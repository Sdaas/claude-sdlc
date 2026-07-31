#!/usr/bin/env bash
#
# apply.sh — install / update / remove the SDLC payload into a Claude config dir.
#
# Copies payload/{commands,skills} into a target (default: ~/.claude), tracking
# exactly which paths we own in a manifest so updates are clean and nothing of
# yours is ever clobbered. Version-stamped and reversible.
#
# Usage:
#   ./apply.sh                 Install or update to this repo's current version
#   ./apply.sh --status        Show installed version + sha vs. repo version
#   ./apply.sh --dry-run       Print the plan (add/overwrite/remove); change nothing
#   ./apply.sh --uninstall     Remove every path we own; leave everything else
#   ./apply.sh --force         Proceed even if a target collides with a foreign file
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
	# Print the header comment block (lines starting with '#') as help text.
	sed -n '3,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Is $1 present as an exact line in the newline-delimited list $2 ?
in_list() {
	printf '%s\n' "$2" | grep -Fxq -- "$1"
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

# --- STATUS -----------------------------------------------------------------
if [[ "$MODE" == "status" ]]; then
	if [[ -f "$STAMP" ]]; then
		echo "Installed in: $TARGET"
		cat "$STAMP"
	else
		echo "Not installed in: $TARGET"
	fi
	echo "Repo version: $(read_source_version) (sha $(source_git_sha), dirty $(source_git_dirty))"
	exit 0
fi

# --- load previous manifest (may be empty) ----------------------------------
OLD_MANIFEST=""
if [[ -f "$MANIFEST" ]]; then
	OLD_MANIFEST="$(cat "$MANIFEST")"
fi

# --- UNINSTALL --------------------------------------------------------------
if [[ "$MODE" == "uninstall" ]]; then
	if [[ -z "$OLD_MANIFEST" ]]; then
		echo "Nothing to uninstall (no manifest in $TARGET)."
		exit 0
	fi
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		local_path="$TARGET/$rel"
		if [[ -e "$local_path" ]]; then
			rm -f "$local_path"
			log "removed $rel"
			prune_empty "$(dirname "$local_path")"
		fi
	done <<<"$OLD_MANIFEST"
	rm -rf "$SDLC_DIR"
	echo "Uninstalled from $TARGET."
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

# Collision check: a target that already exists, is NOT ours, and is not --force.
COLLISIONS=""
ADD_COUNT=0
OVERWRITE_COUNT=0
while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	dest="$TARGET/$rel"
	if [[ -e "$dest" ]]; then
		if in_list "$rel" "$OLD_MANIFEST"; then
			OVERWRITE_COUNT=$((OVERWRITE_COUNT + 1))
		elif ! $FORCE; then
			COLLISIONS+="$rel"$'\n'
		else
			OVERWRITE_COUNT=$((OVERWRITE_COUNT + 1))
		fi
	else
		ADD_COUNT=$((ADD_COUNT + 1))
	fi
done <<<"$NEW_LIST"

if [[ -n "$COLLISIONS" ]]; then
	{
		echo "apply.sh: refusing to overwrite files we don't own:"
		printf '%s' "$COLLISIONS" | sed 's/^/  - /'
		echo "Re-run with --force to overwrite them."
	} >&2
	exit 1
fi

# Compute stale = in OLD manifest but not in NEW list.
STALE=""
if [[ -n "$OLD_MANIFEST" ]]; then
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		if ! in_list "$rel" "$NEW_LIST"; then
			STALE+="$rel"$'\n'
		fi
	done <<<"$OLD_MANIFEST"
fi
STALE="${STALE%$'\n'}"
REMOVE_COUNT=0
[[ -n "$STALE" ]] && REMOVE_COUNT="$(printf '%s\n' "$STALE" | grep -c .)"

# --- dry run: report and stop ----------------------------------------------
if $DRY_RUN; then
	echo "Plan for $TARGET (version $(read_source_version)):"
	echo "  add:       $ADD_COUNT"
	echo "  overwrite: $OVERWRITE_COUNT"
	echo "  remove:    $REMOVE_COUNT"
	if $VERBOSE; then
		while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  + $rel"; done <<<"$NEW_LIST"
		[[ -n "$STALE" ]] && while IFS= read -r rel; do [[ -n "$rel" ]] && echo "  - $rel"; done <<<"$STALE"
	fi
	echo "(dry run — nothing written)"
	exit 0
fi

# --- apply: copy new/updated files -----------------------------------------
while IFS= read -r rel; do
	[[ -n "$rel" ]] || continue
	src="$PAYLOAD/$rel"
	dest="$TARGET/$rel"
	mkdir -p "$(dirname "$dest")"
	cp "$src" "$dest"
	log "wrote $rel"
done <<<"$NEW_LIST"

# --- remove stale files -----------------------------------------------------
if [[ -n "$STALE" ]]; then
	while IFS= read -r rel; do
		[[ -n "$rel" ]] || continue
		dest="$TARGET/$rel"
		if [[ -e "$dest" ]]; then
			rm -f "$dest"
			log "removed stale $rel"
			prune_empty "$(dirname "$dest")"
		fi
	done <<<"$STALE"
fi

# --- write manifest + version stamp ----------------------------------------
mkdir -p "$SDLC_DIR"
printf '%s\n' "$NEW_LIST" >"$MANIFEST"
{
	echo "version=$(read_source_version)"
	echo "git_sha=$(source_git_sha)"
	echo "dirty=$(source_git_dirty)"
	echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	echo "source=$SOURCE"
} >"$STAMP"

echo "Applied version $(read_source_version) to $TARGET"
echo "  added $ADD_COUNT, overwrote $OVERWRITE_COUNT, removed $REMOVE_COUNT"
