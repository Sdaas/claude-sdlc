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

scaffold_py() { # target [extra args...]
	"$SCAFFOLD" --target "$1" --name "my-tool" \
		--purpose "Do things with tasks." --profile python \
		--archetype cli --distribution none --license mit \
		--author "Ada Lovelace" "${@:2}"
}

# --- Test 8: python profile files generated ---------------------------------
test_python_profile_files() {
	start "python profile generates pyproject, src/<pkg>, tests, test.sh"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_exists "$tgt/pyproject.toml" "pyproject.toml exists"
	assert_exists "$tgt/src/my_tool/__init__.py" "package dir uses underscores (my_tool)"
	assert_exists "$tgt/src/my_tool/cli.py" "cli.py exists"
	assert_exists "$tgt/tests/test_my_tool.py" "pytest module exists"
	assert_exec "$tgt/test.sh" "test.sh is executable"
	assert_contains "$tgt/pyproject.toml" "my-tool" "pyproject has project name"
	assert_contains "$tgt/pyproject.toml" "requires-python" "pyproject pins python"
	assert_contains "$tgt/pyproject.toml" "3.11" "pyproject targets 3.11"
	assert_contains "$tgt/pyproject.toml" "hatchling" "pyproject uses hatchling"
	assert_contains "$tgt/pyproject.toml" "ruff" "pyproject includes ruff"
	assert_contains "$tgt/src/my_tool/cli.py" "argparse" "cli uses argparse"
	assert_absent_str "$tgt/pyproject.toml" "{{" "no leftover placeholders in pyproject"
	assert_absent_str "$tgt/src/my_tool/cli.py" "{{" "no leftover placeholders in cli.py"
	# python profile should NOT emit shell-only files
	assert_absent_str "$tgt/bin/my-tool" "usage" "no shell bin/ for python profile"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 9: python test.sh guards on uv (dev dependency) --------------------
test_python_uv_guard() {
	start "generated python test.sh checks uv and runs pytest"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/test.sh" "command -v uv" "test.sh checks for uv"
	assert_contains "$tgt/test.sh" "pytest" "test.sh runs pytest"
	assert_contains "$tgt/test.sh" "ruff" "test.sh runs ruff"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 10: generated python shell scripts pass shellcheck ----------------
test_python_generated_shellcheck() {
	start "generated python shell scripts are shellcheck-clean"
	if ! command -v shellcheck >/dev/null 2>&1; then
		pass "shellcheck not installed — skipped"
		return
	fi
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	if shellcheck "$tgt/test.sh" "$tgt/release.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
		pass "generated python scripts pass shellcheck"
	else
		fail "generated python scripts have shellcheck findings"
	fi
	rm -rf "$(dirname "$tgt")"
}

scaffold_fe() { # target [extra args...]
	"$SCAFFOLD" --target "$1" --name "web-widget" \
		--purpose "A tiny web widget." --profile frontend \
		--archetype webapp --distribution none --license mit \
		--author "Ada Lovelace" "${@:2}"
}

# --- Test 11: frontend profile files generated ------------------------------
test_frontend_profile_files() {
	start "frontend profile generates package.json, index.html, src, tests, test.sh"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_fe "$tgt" >/dev/null 2>&1
	assert_exists "$tgt/package.json" "package.json exists"
	assert_exists "$tgt/tsconfig.json" "tsconfig.json exists"
	assert_exists "$tgt/vite.config.ts" "vite.config.ts exists"
	assert_exists "$tgt/index.html" "index.html exists"
	assert_exists "$tgt/src/main.ts" "src/main.ts exists"
	assert_exists "$tgt/src/main.test.ts" "vitest suite exists"
	assert_exec "$tgt/test.sh" "test.sh is executable"
	assert_exec "$tgt/release.sh" "release.sh is executable"
	assert_contains "$tgt/package.json" "web-widget" "package.json has project name"
	assert_contains "$tgt/package.json" "\"vite\"" "package.json depends on vite"
	assert_contains "$tgt/package.json" "vitest" "package.json depends on vitest"
	assert_contains "$tgt/package.json" "typescript" "package.json depends on typescript"
	assert_contains "$tgt/package.json" "prettier" "package.json depends on prettier"
	assert_contains "$tgt/tsconfig.json" "strict" "tsconfig is strict"
	assert_contains "$tgt/src/main.ts" "export" "main.ts exports a testable symbol"
	assert_contains "$tgt/index.html" "src/main.ts" "index.html loads the entry module"
	assert_contains "$tgt/.gitignore" "node_modules" ".gitignore ignores node_modules"
	assert_exists "$tgt/.prettierignore" ".prettierignore exists"
	assert_contains "$tgt/.prettierignore" "README.md" ".prettierignore scopes off core docs"
	assert_absent_str "$tgt/package.json" "{{" "no leftover placeholders in package.json"
	assert_absent_str "$tgt/src/main.ts" "{{" "no leftover placeholders in main.ts"
	# frontend profile should NOT emit shell- or python-only files
	assert_absent_str "$tgt/bin/web-widget" "Usage" "no shell bin/ for frontend profile"
	assert_absent_str "$tgt/pyproject.toml" "hatchling" "no pyproject for frontend profile"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 12: frontend test.sh guards on node/npm ---------------------------
test_frontend_node_guard() {
	start "generated frontend test.sh checks node/npm and runs tsc + prettier + vitest"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_fe "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/test.sh" "command -v npm" "test.sh checks for npm"
	assert_contains "$tgt/test.sh" "vitest" "test.sh runs vitest"
	assert_contains "$tgt/test.sh" "tsc" "test.sh type-checks with tsc"
	assert_contains "$tgt/test.sh" "prettier" "test.sh checks formatting"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 13: generated frontend shell scripts pass shellcheck --------------
test_frontend_generated_shellcheck() {
	start "generated frontend shell scripts are shellcheck-clean"
	if ! command -v shellcheck >/dev/null 2>&1; then
		pass "shellcheck not installed — skipped"
		return
	fi
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_fe "$tgt" >/dev/null 2>&1
	if shellcheck "$tgt/test.sh" "$tgt/release.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
		pass "generated frontend scripts pass shellcheck"
	else
		fail "generated frontend scripts have shellcheck findings"
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
test_python_profile_files
test_python_uv_guard
test_python_generated_shellcheck
test_frontend_profile_files
test_frontend_node_guard
test_frontend_generated_shellcheck
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
