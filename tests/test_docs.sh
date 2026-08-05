#!/usr/bin/env bash
#
# test_docs.sh — consistency tests for the payload prose (#53).
#
# The SDLC's primary artifact is markdown: 10 commands + 6 skills, cross-
# referencing each other by command name, skill name, template path, and repo
# path. Nothing tested it, and it had already drifted twice (the 5->10 gate
# renumber; the /help and /verify collisions).
#
# Each check is a function taking a ROOT directory, so the self-tests can point
# it at a deliberately-broken fixture and prove the check bites. Plain bash, no
# bats dependency (matching test_apply.sh / test_scaffold.sh style).

# This suite matches LITERAL backticks (markdown code spans) throughout, so
# single-quoted patterns containing ` are intentional, not a missed expansion.
# shellcheck disable=SC2016

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

PASS=0
FAIL=0
CURRENT=""
start() { CURRENT="$1"; }
pass() { PASS=$((PASS + 1)); printf '  ok   — %s\n' "$1"; }
fail() {
	FAIL=$((FAIL + 1))
	printf '  FAIL — %s\n' "$CURRENT"
	printf '         %s\n' "$1"
}
# A check is "clean" when it exits 0 and prints nothing.
assert_clean() { # check-fn root msg
	local out rc
	out="$("$1" "$2" 2>&1)"; rc=$?
	if [[ "$rc" -eq 0 && -z "$out" ]]; then pass "$3"; else fail "expected clean, got rc=$rc: $out — $3"; fi
}
assert_flags() { # check-fn root needle msg
	local out rc
	out="$("$1" "$2" 2>&1)"; rc=$?
	if [[ "$rc" -ne 0 && "$out" == *"$3"* ]]; then
		pass "$4"
	else
		fail "expected a violation mentioning [$3], got rc=$rc: $out — $4"
	fi
}

# --- allowlists -------------------------------------------------------------
# Claude Code built-ins, referenced deliberately in the collision guidance
# (sdlc-common naming convention; sdlc-resume's "not /resume" note). These are
# NOT ours to prefix.
EXTERNAL_COMMANDS=" /help /verify /resume /code-review "
# Skills that ship globally in ~/.claude rather than in this payload.
EXTERNAL_SKILLS=" harden-shell-repo run verify "
# Known README drift, each already filed. Delete the entry when the issue lands.
README_PATH_ALLOW=" design/ templates/ " # design/ -> #56, templates/ -> #58

in_list() { case "$2" in *" $1 "*) return 0 ;; esac; return 1; }

# Files that make up the prose surface. Missing globs expand to nothing.
prose_files() { # root
	local root="$1"
	ls "$root"/payload/commands/*.md 2>/dev/null
	ls "$root"/payload/skills/*/SKILL.md 2>/dev/null
	[[ -f "$root/README.md" ]] && echo "$root/README.md"
	return 0
}

# --- checks -----------------------------------------------------------------
# Each prints one line per violation and returns non-zero if any were found.

check_prefix() { # root
	local root="$1" bad=0 f base ref
	for f in "$root"/payload/commands/*.md; do
		[[ -e "$f" ]] || continue
		base="$(basename "$f" .md)"
		case "$base" in
		sdlc-*) ;;
		*)
			echo "command file is not sdlc-prefixed: $base.md"
			bad=1
			;;
		esac
	done
	# Only BACKTICKED /command tokens: bare-word matching hits path fragments
	# ("./test.sh" -> /test) and prose ("and/or" -> /or).
	while IFS= read -r ref; do
		[[ -n "$ref" ]] || continue
		case "$ref" in
		/sdlc-*) ;;
		*)
			in_list "$ref" "$EXTERNAL_COMMANDS" && continue
			echo "unprefixed command reference: $ref"
			bad=1
			;;
		esac
	done < <(prose_files "$root" | xargs grep -hoE '`/[a-z][a-z-]+`' 2>/dev/null | tr -d '`' | sort -u)
	return "$bad"
}

check_skills() { # root
	local root="$1" bad=0 s
	while IFS= read -r s; do
		[[ -n "$s" ]] || continue
		in_list "$s" "$EXTERNAL_SKILLS" && continue
		if [[ ! -f "$root/payload/skills/$s/SKILL.md" ]]; then
			echo "referenced skill does not exist: $s"
			bad=1
		fi
	done < <(prose_files "$root" | xargs grep -hoE '`[a-z][a-z0-9-]+` skill' 2>/dev/null |
		sed 's/` skill//; s/`//' | sort -u)
	return "$bad"
}

check_command_index() { # root
	local root="$1" bad=0 f cmd
	[[ -f "$root/README.md" ]] || return 0
	for f in "$root"/payload/commands/*.md; do
		[[ -e "$f" ]] || continue
		cmd="/$(basename "$f" .md)"
		if ! grep -qF -- "\`$cmd\`" "$root/README.md"; then
			echo "command missing from the README table: $cmd"
			bad=1
		fi
	done
	return "$bad"
}

check_templates() { # root
	local root="$1" bad=0 f ref resolved
	while IFS= read -r f; do
		[[ -n "$f" ]] || continue
		while IFS= read -r ref; do
			[[ -n "$ref" ]] || continue
			case "$ref" in
			payload/*) resolved="$root/$ref" ;;                     # repo-root relative
			*/templates/*) resolved="$root/payload/skills/$ref" ;;  # <skill>/templates/...
			templates/*) resolved="$(dirname "$f")/$ref" ;;         # relative to the owning skill
			*) continue ;;
			esac
			if [[ ! -e "$resolved" ]]; then
				echo "referenced template does not exist: $ref (from $(basename "$f"))"
				bad=1
			fi
		done < <(grep -hoE '`[a-zA-Z0-9_./-]*templates/[a-zA-Z0-9_.-]+`' "$f" 2>/dev/null | tr -d '`' | sort -u)
	done < <(prose_files "$root")
	return "$bad"
}

check_readme_paths() { # root
	local root="$1" bad=0 line indent token parent="" full
	[[ -f "$root/README.md" ]] || return 0
	# Only the fenced layout block(s): prose elsewhere legitimately names paths
	# in a SCAFFOLDED repo (design/, docs/retrospectives/) which must not be
	# resolved against this one. Indented entries nest under the last top-level
	# entry, so "  commands/" means "payload/commands/".
	while IFS= read -r line; do
		[[ "$line" =~ ^([[:space:]]*)([a-zA-Z0-9_.-]+/)([a-zA-Z0-9_/.-]*) ]] || continue
		indent="${BASH_REMATCH[1]}"
		token="${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
		if [[ -z "$indent" ]]; then
			parent="$token"
			full="$token"
		else
			full="$parent$token"
		fi
		in_list "$token" "$README_PATH_ALLOW" && continue
		if [[ ! -e "$root/$full" ]]; then
			echo "README names a path that does not exist: $full"
			bad=1
		fi
	done < <(awk '/^```/{f=!f; next} f' "$root/README.md" 2>/dev/null)
	return "$bad"
}

# --- fixture ----------------------------------------------------------------
# A minimal but VALID payload tree. Each negative test breaks exactly one thing,
# so a failure names the check that broke rather than the fixture.
make_fixture() {
	local fx; fx="$(mktemp -d)"
	mkdir -p "$fx/payload/commands" "$fx/payload/skills/sdlc-common/templates" "$fx/docs"
	cat >"$fx/payload/commands/sdlc-thing.md" <<'EOF'
# /sdlc-thing — do a thing
Load the `sdlc-common` skill. Uses `templates/thing.md`.
EOF
	cat >"$fx/payload/skills/sdlc-common/SKILL.md" <<'EOF'
# sdlc-common
The rulebook.
EOF
	: >"$fx/payload/skills/sdlc-common/templates/thing.md"
	cat >"$fx/README.md" <<'EOF'
| Command | Purpose |
|---|---|
| `/sdlc-thing` | Do a thing. |

```
payload/              What gets installed
docs/                 Design
```
EOF
	printf '%s' "$fx"
}

# --- Check 1: sdlc- prefix rule ---------------------------------------------
test_prefix_clean_on_real_tree() {
	start "prefix check is clean on the real payload"
	assert_clean check_prefix "$REPO_ROOT" "every command file and command reference is sdlc-prefixed"
}

test_prefix_catches_unprefixed_file() {
	start "prefix check catches an unprefixed command FILE"
	local fx; fx="$(make_fixture)"
	mv "$fx/payload/commands/sdlc-thing.md" "$fx/payload/commands/thing.md"
	assert_flags check_prefix "$fx" "thing" "an unprefixed command file is flagged"
	rm -rf "$fx"
}

test_prefix_catches_unprefixed_reference() {
	start "prefix check catches an unprefixed command REFERENCE"
	local fx; fx="$(make_fixture)"
	printf 'See `/thing` for details.\n' >>"$fx/payload/commands/sdlc-thing.md"
	assert_flags check_prefix "$fx" "/thing" "an unprefixed command reference is flagged"
	rm -rf "$fx"
}

test_prefix_allows_known_builtins() {
	start "prefix check allows deliberate references to Claude Code built-ins"
	local fx; fx="$(make_fixture)"
	printf 'Named `/sdlc-resume`, not `/resume`, to avoid a collision with `/help`.\n' \
		>>"$fx/payload/commands/sdlc-thing.md"
	assert_clean check_prefix "$fx" "built-in command names are not false positives"
	rm -rf "$fx"
}

# --- Check 2: referenced skills exist ---------------------------------------
test_skills_clean_on_real_tree() {
	start "skill check is clean on the real payload"
	assert_clean check_skills "$REPO_ROOT" "every referenced payload skill exists"
}

test_skills_catches_missing_skill() {
	start "skill check catches a reference to a non-existent skill"
	local fx; fx="$(make_fixture)"
	printf 'Load the `sdlc-orchestrator` skill.\n' >>"$fx/payload/commands/sdlc-thing.md"
	assert_flags check_skills "$fx" "sdlc-orchestrator" "a missing skill is flagged"
	rm -rf "$fx"
}

test_skills_allows_known_global_skills() {
	start "skill check allows skills that ship globally, not in the payload"
	local fx; fx="$(make_fixture)"
	printf 'Delegates to the `harden-shell-repo` skill and the `run` skill.\n' \
		>>"$fx/payload/commands/sdlc-thing.md"
	assert_clean check_skills "$fx" "global skills are not false positives"
	rm -rf "$fx"
}

# --- Check 4: README lists every command ------------------------------------
test_command_index_clean_on_real_tree() {
	start "command-index check is clean on the real payload"
	assert_clean check_command_index "$REPO_ROOT" "README lists every installed command"
}

test_command_index_catches_missing_entry() {
	start "command-index check catches a command missing from the README"
	local fx; fx="$(make_fixture)"
	cat >"$fx/payload/commands/sdlc-newthing.md" <<'EOF'
# /sdlc-newthing — shipped but undocumented
EOF
	assert_flags check_command_index "$fx" "sdlc-newthing" "an undocumented command is flagged"
	rm -rf "$fx"
}

# --- Check 5: template references resolve -----------------------------------
test_templates_clean_on_real_tree() {
	start "template check is clean on the real payload"
	assert_clean check_templates "$REPO_ROOT" "every referenced template exists"
}

test_templates_catches_missing_template() {
	start "template check catches a reference to a non-existent template"
	local fx; fx="$(make_fixture)"
	printf 'Render `templates/nope.md` into place.\n' >>"$fx/payload/skills/sdlc-common/SKILL.md"
	assert_flags check_templates "$fx" "nope.md" "a missing template is flagged"
	rm -rf "$fx"
}

# --- Check 6: README paths resolve ------------------------------------------
test_readme_paths_clean_on_real_tree() {
	start "README path check is clean on the real repo (known drift allowlisted)"
	assert_clean check_readme_paths "$REPO_ROOT" "every README layout path resolves"
}

test_readme_paths_catches_dangling_dir() {
	start "README path check catches a directory the repo does not have"
	local fx; fx="$(make_fixture)"
	# Inside the fenced layout block — that is the only region the check reads.
	cat >"$fx/README.md" <<'EOF'
```
payload/              What gets installed
nosuchdir/            Not a real directory
```
EOF
	assert_flags check_readme_paths "$fx" "nosuchdir" "a dangling README path is flagged"
	rm -rf "$fx"
}

test_readme_paths_resolves_nesting() {
	start "README path check resolves indented entries under their parent"
	local fx; fx="$(make_fixture)"
	cat >"$fx/README.md" <<'EOF'
```
payload/              What gets installed
  commands/           Slash commands
```
EOF
	assert_clean check_readme_paths "$fx" "'  commands/' resolves as payload/commands/"
	rm -rf "$fx"
}

echo "Running docs-consistency tests against: $REPO_ROOT"
echo
test_prefix_clean_on_real_tree
test_prefix_catches_unprefixed_file
test_prefix_catches_unprefixed_reference
test_prefix_allows_known_builtins
test_skills_clean_on_real_tree
test_skills_catches_missing_skill
test_skills_allows_known_global_skills
test_command_index_clean_on_real_tree
test_command_index_catches_missing_entry
test_templates_clean_on_real_tree
test_templates_catches_missing_template
test_readme_paths_clean_on_real_tree
test_readme_paths_catches_dangling_dir
test_readme_paths_resolves_nesting
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
