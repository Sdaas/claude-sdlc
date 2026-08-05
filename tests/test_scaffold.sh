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
assert_absent() { if [[ ! -e "$1" ]]; then pass "$2"; else fail "should not exist: $1 — $2"; fi; }
assert_nonzero() { if [[ "$1" -ne 0 ]]; then pass "$2"; else fail "expected non-zero exit — $2"; fi; }

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
	assert_exec "$tgt/setup.sh" "setup.sh is executable"
	rm -rf "$(dirname "$tgt")"
}

# --- Test: README documents Setup + ./setup.sh ------------------------------
test_readme_setup_section() {
	start "generated README has a Setup section pointing at ./setup.sh"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/README.md" "## Setup" "README has a Setup heading"
	assert_contains "$tgt/README.md" "./setup.sh" "README tells devs to run ./setup.sh"
	rm -rf "$(dirname "$tgt")"
}

# --- Test: setup.sh carries profile-appropriate deps ------------------------
# shell profile -> shellcheck + bats-core; every profile -> git + gh.
test_setup_deps_shell() {
	start "shell profile setup.sh lists shellcheck + bats-core"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/setup.sh" "shellcheck" "setup.sh checks shellcheck"
	assert_contains "$tgt/setup.sh" "bats" "setup.sh checks bats"
	assert_contains "$tgt/setup.sh" "gh" "setup.sh checks gh"
	assert_absent_str "$tgt/setup.sh" "{{" "no leftover placeholders in setup.sh"
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
	if shellcheck "$tgt/bin/widgetron" "$tgt/test.sh" "$tgt/release.sh" "$tgt/setup.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
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

# --- Test: python profile setup.sh lists uv ---------------------------------
test_setup_deps_python() {
	start "python profile setup.sh checks uv (and git/gh), not bats"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_exec "$tgt/setup.sh" "setup.sh is executable"
	assert_contains "$tgt/setup.sh" "uv" "setup.sh checks uv"
	assert_contains "$tgt/setup.sh" "gh" "setup.sh checks gh"
	assert_absent_str "$tgt/setup.sh" "bats" "python setup.sh does not check bats"
	assert_absent_str "$tgt/setup.sh" "{{" "no leftover placeholders in setup.sh"
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
	if shellcheck "$tgt/test.sh" "$tgt/release.sh" "$tgt/setup.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
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

# --- Test: frontend profile setup.sh lists node -----------------------------
test_setup_deps_frontend() {
	start "frontend profile setup.sh checks node (and git/gh), not bats/uv"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_fe "$tgt" >/dev/null 2>&1
	assert_exec "$tgt/setup.sh" "setup.sh is executable"
	assert_contains "$tgt/setup.sh" "node" "setup.sh checks node"
	assert_contains "$tgt/setup.sh" "gh" "setup.sh checks gh"
	assert_absent_str "$tgt/setup.sh" "bats" "frontend setup.sh does not check bats"
	assert_absent_str "$tgt/setup.sh" "{{" "no leftover placeholders in setup.sh"
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
	if shellcheck "$tgt/test.sh" "$tgt/release.sh" "$tgt/setup.sh" "$tgt/hooks/pre-push" "$tgt/install-hooks.sh" >/dev/null 2>&1; then
		pass "generated frontend scripts pass shellcheck"
	else
		fail "generated frontend scripts have shellcheck findings"
	fi
	rm -rf "$(dirname "$tgt")"
}

# --- Test 14: python profile has an opt-in integration lane (#43) -----------
# Default run is fast/hermetic (pytest -m "not integration"); --integration runs
# the full suite. The `integration` marker is registered so pytest doesn't warn.
test_python_integration_lane() {
	start "python profile: opt-in integration lane in test.sh + registered marker"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/pyproject.toml" "markers" "pyproject registers pytest markers"
	assert_contains "$tgt/pyproject.toml" "integration:" "pyproject documents the integration marker"
	assert_contains "$tgt/test.sh" "not integration" "default run excludes integration tests"
	assert_contains "$tgt/test.sh" "--integration" "test.sh accepts an --integration flag"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 15: python CI has a clean runtime-only install job (#43) -----------
# Installs runtime deps only (no dev extras) and runs the tool, so an undeclared
# transitive runtime dependency fails loudly instead of passing green.
test_python_clean_install_ci() {
	start "python CI has a clean-install job that runs the tool on runtime deps only"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/.github/workflows/ci.yml" "clean-install" "CI defines a clean-install job"
	assert_contains "$tgt/.github/workflows/ci.yml" "uv sync --no-dev" "clean-install installs runtime deps only"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 16: shell profile has an opt-in integration lane (#43) -------------
# Integration bats live in tests/integration/ (seeded, .gitkeep). Default
# `bats tests/` is non-recursive and skips them; --integration runs them too.
test_shell_integration_lane() {
	start "shell profile: tests/integration/ lane + --integration flag"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_exists "$tgt/tests/integration/.gitkeep" "tests/integration/ is seeded"
	assert_contains "$tgt/test.sh" "--integration" "test.sh accepts an --integration flag"
	assert_contains "$tgt/test.sh" "tests/integration" "test.sh knows the integration dir"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 17: pre-push runs the integration lane locally (#43) ---------------
# The lane's home is local: the pre-push hook runs the full lane before a push.
test_prepush_runs_integration() {
	start "pre-push hook runs ./test.sh --integration"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/hooks/pre-push" "test.sh --integration" "pre-push runs the integration lane"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 18: README documents run-once onboarding + integration lane (#43) --
test_readme_run_once() {
	start "README documents 'run it once' and the integration lane"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/README.md" "run it once" "README has a fresh-clone run-once step"
	assert_contains "$tgt/README.md" "./test.sh --integration" "README documents the integration lane"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 19: shell entry point follows the logging policy (#24) -------------
# Leveled logging: log_debug/log_info/log_error helpers, timestamp+LEVEL prefix,
# all to stderr; DEBUG gated behind --verbose (default INFO).
test_shell_logging_policy() {
	start "shell profile bin/<tool> has leveled logging (info/debug/error, stderr, --verbose=debug)"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/bin/widgetron" "log_info" "defines log_info"
	assert_contains "$tgt/bin/widgetron" "log_debug" "defines log_debug"
	assert_contains "$tgt/bin/widgetron" "log_error" "defines log_error"
	assert_contains "$tgt/bin/widgetron" "date -u" "timestamps with UTC date"
	assert_contains "$tgt/bin/widgetron" "LOG_LEVEL" "tracks a log level"
	assert_absent_str "$tgt/bin/widgetron" "{{" "no leftover placeholders in tool"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 20: python entry point follows the logging policy (#24) ------------
# Uses stdlib logging to stderr with timestamp+level; --verbose => DEBUG; any
# exception is logged at ERROR with the FULL traceback.
test_python_logging_policy() {
	start "python profile cli.py has leveled logging (stderr, --verbose=debug, full traceback)"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_py "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/src/my_tool/cli.py" "import logging" "imports logging"
	assert_contains "$tgt/src/my_tool/cli.py" "logging.DEBUG" "maps --verbose to DEBUG"
	assert_contains "$tgt/src/my_tool/cli.py" "stderr" "logs to stderr"
	assert_contains "$tgt/src/my_tool/cli.py" "exc_info" "logs full traceback on error"
	assert_absent_str "$tgt/src/my_tool/cli.py" "{{" "no leftover placeholders in cli.py"
	rm -rf "$(dirname "$tgt")"
}

# --- Test 21: frontend entry point follows the logging policy (#24) ----------
# A tiny log helper maps debug/info/error onto console.debug/info/error with a
# timestamp+level prefix (the browser-console analogue of stderr).
test_frontend_logging_policy() {
	start "frontend profile main.ts has leveled logging (console debug/info/error)"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_fe "$tgt" >/dev/null 2>&1
	assert_contains "$tgt/src/main.ts" "console.debug" "uses console.debug for DEBUG"
	assert_contains "$tgt/src/main.ts" "console.info" "uses console.info for INFO"
	assert_contains "$tgt/src/main.ts" "console.error" "uses console.error for ERROR"
	assert_absent_str "$tgt/src/main.ts" "{{" "no leftover placeholders in main.ts"
	rm -rf "$(dirname "$tgt")"
}

# --- License matrix (#52) ---------------------------------------------------
# Every license value the interview advertises must actually scaffold. `apache`
# shipped broken because no test ever passed it.

test_license_apache() {
	start "--license apache scaffolds an Apache-2.0 LICENSE"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" --license apache >/dev/null 2>&1
	assert_eq 0 "$?" "scaffold exits 0 with --license apache"
	assert_exists "$tgt/LICENSE" "LICENSE exists"
	assert_contains "$tgt/LICENSE" "Apache License" "LICENSE is the Apache License"
	assert_contains "$tgt/LICENSE" "Version 2.0" "LICENSE is version 2.0"
	assert_contains "$tgt/LICENSE" "Ada Lovelace" "author rendered into LICENSE"
	assert_absent_str "$tgt/LICENSE" "{{" "no leftover placeholders in LICENSE"
	rm -rf "$(dirname "$tgt")"
}

test_license_mit() {
	start "--license mit scaffolds an MIT LICENSE"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" --license mit >/dev/null 2>&1
	assert_eq 0 "$?" "scaffold exits 0 with --license mit"
	assert_contains "$tgt/LICENSE" "MIT License" "LICENSE is the MIT License"
	assert_contains "$tgt/LICENSE" "Ada Lovelace" "author rendered into LICENSE"
	assert_absent_str "$tgt/LICENSE" "{{" "no leftover placeholders in LICENSE"
	rm -rf "$(dirname "$tgt")"
}

test_license_none() {
	start "--license none scaffolds no LICENSE file"
	local tgt; tgt="$(mktemp -d)/proj"
	scaffold_sample "$tgt" --license none >/dev/null 2>&1
	assert_eq 0 "$?" "scaffold exits 0 with --license none"
	assert_exists "$tgt/README.md" "the rest of the scaffold is still written"
	assert_absent "$tgt/LICENSE" "no LICENSE file is created"
	rm -rf "$(dirname "$tgt")"
}

# A rejected option must fail BEFORE any filesystem writes — otherwise the user
# is left with a half-built repo to clean up by hand.
test_license_rejected_before_writing() {
	start "an unknown --license fails before writing anything"
	local root tgt out rc
	root="$(mktemp -d)"; tgt="$root/proj"
	out="$(scaffold_sample "$tgt" --license bogus 2>&1)"; rc=$?
	assert_nonzero "$rc" "scaffold exits non-zero for an unknown license"
	if [[ "$out" == *"unknown license"* ]]; then
		pass "error names the bad license"
	else
		fail "expected 'unknown license' in: $out"
	fi
	assert_absent "$tgt" "no partial scaffold is left behind"
	rm -rf "$root"
}

test_profile_rejected_before_writing() {
	start "an unknown --profile fails before writing anything"
	local root tgt out rc
	root="$(mktemp -d)"; tgt="$root/proj"
	out="$(scaffold_sample "$tgt" --profile bogus 2>&1)"; rc=$?
	assert_nonzero "$rc" "scaffold exits non-zero for an unknown profile"
	if [[ "$out" == *"unknown profile"* ]]; then
		pass "error names the bad profile"
	else
		fail "expected 'unknown profile' in: $out"
	fi
	assert_absent "$tgt" "no partial scaffold is left behind"
	rm -rf "$root"
}

echo "Running scaffold tests against: $SCAFFOLD"
echo
test_core_files
test_readme_setup_section
test_setup_deps_shell
test_substitutions
test_nonempty_guard
test_shell_profile_files
test_bats_dependency_guard
test_formula_conditional
test_generated_shellcheck
test_python_profile_files
test_python_uv_guard
test_setup_deps_python
test_python_generated_shellcheck
test_frontend_profile_files
test_frontend_node_guard
test_setup_deps_frontend
test_frontend_generated_shellcheck
test_python_integration_lane
test_python_clean_install_ci
test_shell_integration_lane
test_prepush_runs_integration
test_readme_run_once
test_shell_logging_policy
test_python_logging_policy
test_frontend_logging_policy
test_license_apache
test_license_mit
test_license_none
test_license_rejected_before_writing
test_profile_rejected_before_writing
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
