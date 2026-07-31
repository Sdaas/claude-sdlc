#!/usr/bin/env bash
#
# test_scaffold.sh — behavior tests for the core scaffolder.
# Runs scaffold.sh into throwaway --target dirs. Plain bash, no bats dependency
# (this tests our own tooling, matching test_apply.sh style).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SCAFFOLD="$REPO_ROOT/payload/skills/sdlc-common/scaffold.sh"

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
assert_eq() { if [[ "$1" == "$2" ]]; then pass "$3"; else fail "expected [$1] got [$2] — $3"; fi; }
assert_exists() { if [[ -e "$1" ]]; then pass "$2"; else fail "missing: $1 — $2"; fi; }
assert_exec() { if [[ -x "$1" ]]; then pass "$2"; else fail "not executable: $1 — $2"; fi; }
assert_contains() {
	local got
	got="$(cat "$1" 2>/dev/null || true)"
	if [[ "$got" == *"$2"* ]]; then pass "$3"; else fail "file $1 missing [$2] — $3"; fi
}
assert_absent_str() {
	local got
	got="$(cat "$1" 2>/dev/null || true)"
	if [[ "$got" != *"$2"* ]]; then pass "$3"; else fail "file $1 still contains [$2] — $3"; fi
}

scaffold_sample() { # target
	"$SCAFFOLD" \
		--target "$1" \
		--name "widgetron" \
		--purpose "Manage widgets from the command line." \
		--profile shell \
		--archetype cli \
		--distribution brew \
		--license mit \
		--author "Ada Lovelace" "${@:2}"
}

# --- Test 1: core files generated with substitutions ------------------------
test_core_files() {
	start "core scaffold generates expected files with substitutions"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_eq 0 "$?" "scaffold exits 0"
	assert_exists "$tgt/README.md" "README exists"
	assert_exists "$tgt/LICENSE" "LICENSE exists"
	assert_exists "$tgt/.gitignore" ".gitignore exists"
	assert_exists "$tgt/VERSION" "VERSION exists"
	assert_exists "$tgt/CLAUDE.md" "CLAUDE.md exists"
	assert_exists "$tgt/design/overview.md" "design/overview.md exists"
	assert_exists "$tgt/docs/retrospectives" "docs/retrospectives exists"
	assert_exists "$tgt/.github/workflows/ci.yml" "CI workflow exists"
	assert_exec "$tgt/hooks/pre-push" "pre-push hook is executable"
	assert_exec "$tgt/install-hooks.sh" "install-hooks.sh is executable"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 2: substitutions correct, no leftover placeholders ----------------
test_substitutions() {
	start "placeholders substituted, none left over"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/README.md" "widgetron" "README has name"
	assert_contains "$tgt/README.md" "Manage widgets from the command line." "README has purpose"
	assert_eq "0.1.0" "$(cat "$tgt/VERSION")" "VERSION is 0.1.0"
	assert_contains "$tgt/LICENSE" "Ada Lovelace" "LICENSE has author"
	assert_contains "$tgt/CLAUDE.md" "shell" "CLAUDE.md records profile"
	assert_contains "$tgt/CLAUDE.md" "cli" "CLAUDE.md records archetype"
	assert_contains "$tgt/CLAUDE.md" "brew" "CLAUDE.md records distribution"
	assert_absent_str "$tgt/README.md" "{{" "no leftover placeholders in README"
	assert_absent_str "$tgt/CLAUDE.md" "{{" "no leftover placeholders in CLAUDE.md"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 3: refuses non-empty target unless --force ------------------------
test_nonempty_guard() {
	start "refuses non-empty target unless --force"
	local tgt; tgt="$(mktemp -d)/proj"
	mkdir -p "$tgt"
	printf 'mine\n' >"$tgt/existing.txt"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_eq 1 "$?" "aborts non-zero on non-empty target"
	assert_absent_str "$tgt/README.md" "widgetron" "nothing written (no README)"
	scaffold_sample "$tgt" --force >/dev/null 2>&1
	assert_eq 0 "$?" "--force proceeds"
	assert_exists "$tgt/README.md" "README written with --force"
	assert_exists "$tgt/existing.txt" "pre-existing file preserved"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 4: shell profile files generated -----------------------------------
test_shell_profile_files() {
	start "shell profile generates bin/<tool>, bats suite, test.sh, release.sh"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_exec "$tgt/bin/widgetron" "bin/widgetron is executable"
	assert_exists "$tgt/tests/widgetron.bats" "bats suite exists (named after tool)"
	assert_exec "$tgt/test.sh" "test.sh is executable"
	assert_exec "$tgt/release.sh" "release.sh is executable"
	assert_contains "$tgt/bin/widgetron" "Usage" "tool prints usage"
	assert_absent_str "$tgt/bin/widgetron" "{{" "no leftover placeholders in tool"
	assert_absent_str "$tgt/test.sh" "{{" "no leftover placeholders in test.sh"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 5: test.sh guards on missing bats (dev dependency) ------------------
test_bats_dependency_guard() {
	start "generated test.sh checks bats is installed"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/test.sh" "command -v bats" "test.sh checks for bats"
	assert_contains "$tgt/test.sh" "bats-core" "test.sh points at install instructions"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 6: brew formula only when distribution=brew ------------------------
test_formula_conditional() {
	start "Formula generated only when distribution=brew"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_exists "$tgt/Formula/widgetron.rb" "brew: Formula present"
	local tgt2; tgt2="$(mktemp -d)/proj"
	scaffold_sample "$tgt2" --distribution none >/dev/null 2>&1
	assert_absent_str "$tgt2/Formula/widgetron.rb" "class" "none: Formula absent"
	rm -rf "$(dirname "$tgt")" "$(dirname "$tgt2")"
}

# --- Test 7: generated shell scripts pass shellcheck ------------------------
test_generated_shellcheck() {
	start "generated shell scripts are shellcheck-clean"
	if ! command -v shellcheck >/dev/null 2>&1; then
		pass "shellcheck not installed — skipped"
		return
	fi
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	if shellcheck "$tgt/bin/widgetron" "$tgt/test.sh" "$tgt/release.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
		pass "generated scripts pass shellcheck"
	else
		fail "generated scripts have shellcheck findings"
	fi
	rm -rf "$(dirname "$tgt")"
}

echo "Running scaffold tests against: $SCAFFOLD"
echo
test_core_files
test_substitutions
test_nonempty_guard
test_shell_profile_files
test_bats_dependency_guard
test_formula_conditional
test_generated_shellcheck
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
