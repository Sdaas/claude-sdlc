#!/usr/bin/env bash
#
# apply.sh — install / update / remove the SDLC payload into a Claude config dir.
#
# Copies payload/{commands,skills} into a target (default: ~/.claude), tracking
# exactly which paths we own in a manifest so updates are clean and nothing of
# yours is ever clobbered. Version-stamped and reversible.
#
# The manifest records a SHA-256 per installed file, so a file you edited in
# place is detected and never overwritten silently (#76).
#
# Usage:
#   ./apply.sh                 Install or update to this repo's current version
#   ./apply.sh --status        Show installed version, plus an integrity report
#   ./apply.sh --dry-run       Print the plan (add/update/unchanged/remove); change nothing
#   ./apply.sh --uninstall     Remove every path we own; leave everything else
#   ./apply.sh --force         Overwrite foreign files and discard local edits
#   ./apply.sh --source DIR    Source repo root (default: this script's repo)
#   ./apply.sh --target DIR    Target config dir (default: ~/.claude)
#   ./apply.sh --verbose       List every action
#   ./apply.sh --help
#
# Kept bash 3.2 compatible (macOS default): no associative arrays.

set -euo pipefail

# --- defaults ---------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR"
TARGET="${HOME}/.claude"
MODE="install" # install | status | uninstall
DRY_RUN=false
FORCE=false
VERBOSE=false

SDLC_DIR_NAME=".sdlc" # our bookkeeping dir under the target

# --- helpers ----------------------------------------------------------------
die() {
	printf 'apply.sh: error: %s\n' "$1" >&2
	exit 1
}

log() { # only prints when --verbose
	if $VERBOSE; then printf '  %s\n' "$1"; fi
}

usage() {
	# Print the header comment block as help text: every line from 3 until the
	# first non-comment line. (A fixed end line silently leaks code into --help
	# as soon as the header grows.)
	awk 'NR < 3 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

# Is $1 present as an exact line in the newline-delimited list $2 ?
in_list() {
	printf '%s\n' "$2" | grep -Fxq -- "$1"
}

# Count the lines in newline-delimited list $1.
count_list() {
	if [[ -z "$1" ]]; then echo 0; else printf '%s\n' "$1" | grep -c .; fi
}

# --- content hashing --------------------------------------------------------
# Resolved once, as an array so the command and its flags stay separate words.
# Both tools emit "<64 hex>  <path>".
SHA_CMD=()
if command -v shasum >/dev/null 2>&1; then
	SHA_CMD=(shasum -a 256)
elif command -v sha256sum >/dev/null 2>&1; then
	SHA_CMD=(sha256sum)
fi

require_sha_cmd() {
	[[ "${#SHA_CMD[@]}" -gt 0 ]] || die "no SHA-256 tool found (need 'shasum' or 'sha256sum' on PATH).
apply.sh records content hashes to detect locally modified files; without one
it cannot protect your edits from being overwritten."
}

# SHA-256 of file $1 (empty if not a readable regular file).
sha_of() {
	[[ -f "$1" ]] || return 0
	"${SHA_CMD[@]}" "$1" 2>/dev/null | cut -c1-64
}

# Do the executable bits of $1 (source) and $2 (dest) agree?
same_mode() {
	if [[ -x "$1" ]]; then [[ -x "$2" ]]; else [[ ! -x "$2" ]]; fi
}

# --- manifest lines ---------------------------------------------------------
# A manifest line is either "<sha>  <path>" (current) or a bare "<path>"
# (legacy, written before hashes existed). Parsed positionally so that paths
# containing spaces survive intact.
is_hashed_line() {
	[[ "${#1}" -gt 66 ]] || return 1
	[[ "${1:64:2}" == "  " ]] || return 1
	local h="${1:0:64}"
	[[ "$h" != *[!0-9a-f]* ]]
}

# Every path in manifest content $1, one per line, in either format.
manifest_paths() {
	local line
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		if is_hashed_line "$line"; then printf '%s\n' "${line:66}"; else printf '%s\n' "$line"; fi
	done <<<"$1"
}

# Recorded sha for target-relative path $1; empty when the manifest is legacy
# (i.e. drift is unknowable for that path).
recorded_sha() {
	local line
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		if is_hashed_line "$line" && [[ "${line:66}" == "$1" ]]; then
			printf '%s' "${line:0:64}"
			return 0
		fi
	done <<<"$OLD_MANIFEST"
}

# Copy payload file $1 (target-relative) into place, matching the source mode.
# Remove any existing path first so cp always CREATES a regular file: this both
# lets cp set the mode from the source (#76c) and — critically — stops cp from
# following a symlink at $dest and writing through it to outside --target (#77).
write_file() {
	local src="$PAYLOAD/$1" dest="$TARGET/$1"
	mkdir -p "$(dirname "$dest")"
	rm -f "$dest"
	cp "$src" "$dest"
	if [[ -x "$src" ]]; then chmod +x "$dest"; else chmod -x "$dest"; fi
}

# Remove empty parent dirs upward from $1, stopping at $TARGET.
prune_empty() {
	local dir="$1"
	while [[ "$dir" != "$TARGET" && "$dir" != "/" && "$dir" != "." && -d "$dir" ]]; do
		rmdir "$dir" 2>/dev/null || break
		dir="$(dirname "$dir")"
	done
}

# --- argument parsing -------------------------------------------------------
while [[ $# -gt 0 ]]; do
	case "$1" in
	--status) MODE="status" ;;
	--uninstall) MODE="uninstall" ;;
	--dry-run) DRY_RUN=true ;;
	--force) FORCE=true ;;
	--verbose | -v) VERBOSE=true ;;
	--help | -h)
		usage
		exit 0
		;;
	--source)
		SOURCE="${2:-}"
		[[ -n "$SOURCE" ]] || die "--source requires a directory"
		shift
		;;
	--target)
		TARGET="${2:-}"
		[[ -n "$TARGET" ]] || die "--target requires a directory"
		shift
		;;
	*) die "unknown argument: $1 (try --help)" ;;
	esac
	shift
done

# Resolve to absolute paths (target may not exist yet).
SOURCE="$(cd "$SOURCE" 2>/dev/null && pwd)" || die "source not found: $SOURCE"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

PAYLOAD="$SOURCE/payload"
VERSION_FILE="$SOURCE/VERSION"
SDLC_DIR="$TARGET/$SDLC_DIR_NAME"
MANIFEST="$SDLC_DIR/manifest"
STAMP="$SDLC_DIR/version"

# --- version / provenance of the SOURCE -------------------------------------
read_source_version() {
	if [[ -f "$VERSION_FILE" ]]; then
		head -n1 "$VERSION_FILE"
	else
		echo "unknown"
	fi
}

source_git_sha() {
	if git -C "$SOURCE" rev-parse --git-dir >/dev/null 2>&1; then
		git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null || echo "unknown"
	else
		echo "unknown"
	fi
}

source_git_dirty() {
	if git -C "$SOURCE" rev-parse --git-dir >/dev/null 2>&1; then
		if [[ -n "$(git -C "$SOURCE" status --porcelain 2>/dev/null)" ]]; then
			echo "true"
		else
			echo "false"
		fi
	else
		echo "unknown"
	fi
}

require_sha_cmd

# --- load previous manifest (may be empty) ----------------------------------
OLD_MANIFEST=""
if [[ -f "$MANIFEST" ]]; then
	OLD_MANIFEST="$(cat "$MANIFEST")"
fi

# --- STATUS -----------------------------------------------------------------
# Reports what is actually on disk, not merely what was recorded at install
# time: a deleted or edited file used to be invisible here (#76b).
if [[ "$MODE" == "status" ]]; then
	if [[ -f "$STAMP" ]]; then
		echo "Installed in: $TARGET"
		cat "$STAMP"
	else
		echo "Not installed in: $TARGET"
	fi

	if [[ -n "$OLD_MANIFEST" ]]; then
		TRACKED=0
		OK=0
		MODIFIED=""
		MISSING=""
		LEGACY=false
		while IFS= read -r line; do
			[[ -n "$line" ]] || continue
			TRACKED=$((TRACKED + 1))
			if is_hashed_line "$line"; then
				rel="${line:66}"
				rec="${line:0:64}"
			else
				rel="$line"
				rec=""
				LEGACY=true
			fi
			if [[ ! -e "$TARGET/$rel" ]]; then
				MISSING+="$rel"$'\n'
			elif [[ -n "$rec" && "$(sha_of "$TARGET/$rel")" != "$rec" ]]; then
				MODIFIED+="$rel"$'\n'
			else
				OK=$((OK + 1))
			fi
		done <<<"$OLD_MANIFEST"

		printf 'Integrity: %d tracked — %d ok, %d modified, %d missing\n' \
			"$TRACKED" "$OK" "$(count_list "$MODIFIED")" "$(count_list "$MISSING")"
		[[ -n "$MODIFIED" ]] && printf '%s' "$MODIFIED" | sed 's/^/  modified: /'
		[[ -n "$MISSING" ]] && printf '%s' "$MISSING" | sed 's/^/  missing:  /'
		if $LEGACY; then
			echo "  (legacy manifest — no hashes recorded; re-run ./apply.sh to enable drift detection)"
		fi
	fi

	echo "Repo version: $(read_source_version) (sha $(source_git_sha), dirty $(source_git_dirty))"
	exit 0
fi

# --- UNINSTALL --------------------------------------------------------------
if [[ "$MODE" == "uninstall" ]]; then
	if [[ -z "$OLD_MANIFEST" ]]; then
		echo "Nothing to uninstall (no manifest in $TARGET)."
		exit 0
	fi
	# A file you edited in place is yours as much as ours — keep it unless
	# --force, and keep tracking it so it never looks "foreign" later.
	PRESERVED=""
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		if is_hashed_line "$line"; then
			rel="${line:66}"
			rec="${line:0:64}"
		else
			rel="$line"
			rec=""
		fi
		local_path="$TARGET/$rel"
		if [[ -e "$local_path" ]]; then
			if [[ -n "$rec" ]] && ! $FORCE && [[ "$(sha_of "$local_path")" != "$rec" ]]; then
				PRESERVED+="$line"$'\n'
				log "preserved (locally modified) $rel"
				continue
			fi
			rm -f "$local_path"
			log "removed $rel"
			prune_empty "$(dirname "$local_path")"
		fi
	done <<<"$OLD_MANIFEST"

	if [[ -n "$PRESERVED" ]]; then
		mkdir -p "$SDLC_DIR"
		printf '%s' "$PRESERVED" >"$MANIFEST"
		echo "Uninstalled from $TARGET, preserving locally modified files:"
		manifest_paths "$PRESERVED" | sed 's/^/  - /'
		echo "Re-run with --force to remove them too."
	else
		rm -rf "$SDLC_DIR"
		echo "Uninstalled from $TARGET."
	fi
	exit 0
fi

# --- INSTALL / UPDATE -------------------------------------------------------
[[ -d "$PAYLOAD" ]] || die "no payload/ dir in source: $PAYLOAD"

# Build the NEW set of target-relative paths from payload/.
NEW_LIST=""
while IFS= read -r f; do
	rel="${f#"$PAYLOAD"/}"
	NEW_LIST+="$rel"$'\n'
done < <(find "$PAYLOAD" -type f ! -name '.gitkeep' | sort)
NEW_LIST="${NEW_LIST%$'\n'}"

# Classify every payload file. Two distinct refusals are possible: a FOREIGN
# file (we never installed it) and a DRIFTED file (we installed it, you edited
# it since). Both need consent; they need different explanations.
OLD_PATHS="$(manifest_paths "$OLD_MANIFEST")"
COLLISIONS=""
DRIFTED=""
ADD_LIST=""
UPDATE_LIST=""
UNCHANGED_LIST=""
while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	src="$PAYLOAD/$rel"
	dest="$TARGET/$rel"

	# -L as well as -e: a dangling symlink is invisible to -e, and treating it as
	# a fresh add would let write_file's cp follow it outside --target (#77). A
	# symlink (live or dangling) is "present" here, so it routes to the collision
	# or drift path below — overwritten only with consent (--force).
	if [[ ! -e "$dest" && ! -L "$dest" ]]; then
		ADD_LIST+="$rel"$'\n'
		continue
	fi

	if ! in_list "$rel" "$OLD_PATHS"; then
		if $FORCE; then UPDATE_LIST+="$rel"$'\n'; else COLLISIONS+="$rel"$'\n'; fi
		continue
	fi

	rec="$(recorded_sha "$rel")"
	if [[ -z "$rec" ]]; then
		# Legacy manifest: nothing was recorded, so drift cannot be judged.
		# Treat as a plain update rather than inventing a false accusation.
		UPDATE_LIST+="$rel"$'\n'
		continue
	fi

	cur="$(sha_of "$dest")"
	if [[ "$cur" != "$rec" ]] && ! $FORCE; then
		DRIFTED+="$rel"$'\n'
		continue
	fi

	# Unchanged means content AND mode already match the source — a cleared
	# executable bit still needs repairing even when the bytes are identical.
	if [[ "$cur" == "$rec" && "$(sha_of "$src")" == "$rec" ]] && same_mode "$src" "$dest"; then
		UNCHANGED_LIST+="$rel"$'\n'
	else
		UPDATE_LIST+="$rel"$'\n'
	fi
done <<<"$NEW_LIST"

if [[ -n "$DRIFTED" || -n "$COLLISIONS" ]]; then
	{
		if [[ -n "$DRIFTED" ]]; then
			echo "apply.sh: refusing to overwrite locally modified files:"
			printf '%s' "$DRIFTED" | sed 's/^/  - /'
			echo "These differ from what apply.sh installed. Copy your changes into the"
			echo "source repo first, or re-run with --force to discard them."
		fi
		if [[ -n "$COLLISIONS" ]]; then
			echo "apply.sh: refusing to overwrite files we don't own:"
			printf '%s' "$COLLISIONS" | sed 's/^/  - /'
			echo "Re-run with --force to overwrite them."
		fi
	} >&2
	exit 1
fi

ADD_COUNT="$(count_list "$ADD_LIST")"
UPDATE_COUNT="$(count_list "$UPDATE_LIST")"
UNCHANGED_COUNT="$(count_list "$UNCHANGED_LIST")"

# Compute stale = in OLD manifest but not in NEW list.
STALE=""
if [[ -n "$OLD_PATHS" ]]; then
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		if ! in_list "$rel" "$NEW_LIST"; then
			STALE+="$rel"$'\n'
		fi
	done <<<"$OLD_PATHS"
fi
STALE="${STALE%$'\n'}"
REMOVE_COUNT=0
[[ -n "$STALE" ]] && REMOVE_COUNT="$(printf '%s\n' "$STALE" | grep -c .)"

# --- dry run: report and stop ----------------------------------------------
if $DRY_RUN; then
	echo "Plan for $TARGET (version $(read_source_version)):"
	echo "  add:       $ADD_COUNT"
	echo "  update:    $UPDATE_COUNT"
	echo "  unchanged: $UNCHANGED_COUNT"
	echo "  remove:    $REMOVE_COUNT"
	if $VERBOSE; then
		[[ -n "$ADD_LIST" ]] && while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  + $rel"; done <<<"$ADD_LIST"
		[[ -n "$UPDATE_LIST" ]] && while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  ~ $rel"; done <<<"$UPDATE_LIST"
		[[ -n "$UNCHANGED_LIST" ]] && while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  = $rel"; done <<<"$UNCHANGED_LIST"
		[[ -n "$STALE" ]] && while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  - $rel"; done <<<"$STALE"
	fi
	echo "(dry run — nothing written)"
	exit 0
fi

# --- apply: copy added + updated files (unchanged ones are skipped) ---------
while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	write_file "$rel"
	log "added $rel"
done <<<"$ADD_LIST"

while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	write_file "$rel"
	log "updated $rel"
done <<<"$UPDATE_LIST"

while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	log "unchanged $rel"
done <<<"$UNCHANGED_LIST"

# --- remove stale files -----------------------------------------------------
# Dropping a file from the payload (a rename, say) must not delete your edits
# either — the same consent rule as overwriting, on the removal path. A
# preserved file stops being ours: the payload no longer claims that path, so
# it is left behind untracked, as an ordinary file of yours.
KEPT_STALE=""
if [[ -n "$STALE" ]]; then
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		dest="$TARGET/$rel"
		if [[ -e "$dest" ]]; then
			rec="$(recorded_sha "$rel")"
			if [[ -n "$rec" ]] && ! $FORCE && [[ "$(sha_of "$dest")" != "$rec" ]]; then
				KEPT_STALE+="$rel"$'\n'
				REMOVE_COUNT=$((REMOVE_COUNT - 1))
				log "kept locally modified $rel (no longer in payload)"
				continue
			fi
			rm -f "$dest"
			log "removed stale $rel"
			prune_empty "$(dirname "$dest")"
		fi
	done <<<"$STALE"
fi

# --- write manifest + version stamp ----------------------------------------
# Record the sha of what we just wrote, so the next run can tell an untouched
# file from one you edited in place.
mkdir -p "$SDLC_DIR"
NEW_MANIFEST=""
while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	NEW_MANIFEST+="$(sha_of "$PAYLOAD/$rel")  $rel"$'\n'
done <<<"$NEW_LIST"
printf '%s' "$NEW_MANIFEST" >"$MANIFEST"
{
	echo "version=$(read_source_version)"
	echo "git_sha=$(source_git_sha)"
	echo "dirty=$(source_git_dirty)"
	echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	echo "source=$SOURCE"
} >"$STAMP"

echo "Applied version $(read_source_version) to $TARGET"
echo "  added $ADD_COUNT, updated $UPDATE_COUNT, unchanged $UNCHANGED_COUNT, removed $REMOVE_COUNT"
if [[ -n "$KEPT_STALE" ]]; then
	echo "  kept (locally modified, no longer in the payload — now untracked):"
	printf '%s' "$KEPT_STALE" | sed 's/^/    - /'
fi
