#!/usr/bin/env bash
#
# test_setup.sh — behavior tests for setup.sh (the dev-dependency checker/installer).
#
# setup.sh must run with NO external commands other than `uname` (overridable via
# _SETUP_UNAME) and `brew`. So every test runs it against an isolated PATH holding
# only fake tools we place there — a fake `brew` logs its args to $BREW_LOG so we
# can assert whether an install was attempted. Nothing touches the real system.
#
# Plain bash, no bats dependency (matches test_apply.sh / test_scaffold.sh style).
# Run: bash tests/test_setup.sh

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SETUP="$REPO_ROOT/setup.sh"

# Absolute bash path so we can hand setup.sh a locked-down PATH (only our fake
# tools) without also hiding the interpreter itself.
BASH_BIN="$(command -v bash)"

# --- tiny test harness ------------------------------------------------------
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
assert_ne() { if [[ "$1" != "$2" ]]; then pass "$3"; else fail "expected != [$1] — $3"; fi; }
assert_contains() { if [[ "$1" == *"$2"* ]]; then pass "$3"; else fail "expected to contain [$2] in: $1 — $3"; fi; }

# --- fixtures ---------------------------------------------------------------
# make_bin DIR TOOL...  — create an isolated bin dir with fake (no-op) tools.
make_bin() {
	local dir="$1"; shift
	mkdir -p "$dir"
	local t
	for t in "$@"; do
		printf '#!/bin/sh\nexit 0\n' >"$dir/$t"
		chmod +x "$dir/$t"
	done
}

# make_gh DIR AUTH_RC VERSION  — install a fake `gh` whose `auth status` exits
# AUTH_RC and whose `--version` prints VERSION, so both readiness check types are
# testable without a real login. Any other subcommand is a no-op success.
make_gh() {
	local dir="$1" auth_rc="$2" version="$3"
	mkdir -p "$dir"
	# The "$1"/$* below are literals written into the generated fake, not this
	# script's params — they must NOT expand here.
	# shellcheck disable=SC2016
	{
		printf '#!/bin/sh\n'
		printf 'case "$1" in\n'
		printf '  auth) exit %s ;;\n' "$auth_rc"
		printf '  --version) echo "gh version %s (2026-01-01)"; exit 0 ;;\n' "$version"
		printf '  *) exit 0 ;;\n'
		printf 'esac\n'
	} >"$dir/gh"
	chmod +x "$dir/gh"
}

# make_brew DIR LOG  — install a fake `brew` in DIR that logs its args to LOG.
make_brew() {
	local dir="$1" log="$2"
	mkdir -p "$dir"
	{
		printf '#!/bin/sh\n'
		printf 'printf "%%s\\n" "$*" >> "%s"\n' "$log"
		printf 'exit 0\n'
	} >"$dir/brew"
	chmod +x "$dir/brew"
}

# run_setup BIN UNAME STDIN_FILE : args...  -> sets OUT, RC (isolated PATH=BIN)
# If the test sets SETUP_CHECKS (even to empty), it is forwarded as _SETUP_CHECKS
# so the readiness-check table can be overridden without a real dep. Unset =
# use setup.sh's built-in CHECKS.
run_setup() {
	local bin="$1" uname="$2" stdin="$3"; shift 3
	if [[ -n "${SETUP_CHECKS+x}" ]]; then
		OUT="$(PATH="$bin" _SETUP_UNAME="$uname" BREW_LOG="$BREW_LOG" _SETUP_CHECKS="$SETUP_CHECKS" \
			"$BASH_BIN" "$SETUP" "$@" <"$stdin" 2>&1)"
	else
		OUT="$(PATH="$bin" _SETUP_UNAME="$uname" BREW_LOG="$BREW_LOG" \
			"$BASH_BIN" "$SETUP" "$@" <"$stdin" 2>&1)"
	fi
	RC=$?
}

# --- Test 1: --help prints usage and exits 0 --------------------------------
# usage() shells out to `sed`, so this test keeps the real PATH (no dep is probed
# before --help returns) and asserts on a help-specific token, not just the
# script name — otherwise a missing `sed` would false-positive via the error text.
test_help() {
	start "--help prints usage and exits 0"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	OUT="$("$BASH_BIN" "$SETUP" --help 2>&1)"
	RC=$?
	assert_eq 0 "$RC" "--help exits 0"
	assert_contains "$OUT" "setup.sh" "help mentions setup.sh"
	assert_contains "$OUT" "--yes" "help documents --yes (real usage text rendered)"
	rm -rf "$root"
}

# --- Test 2: all deps present -> exit 0, installs nothing --------------------
test_all_present() {
	start "all deps present: exit 0, no install attempted"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh shellcheck
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null
	assert_eq 0 "$RC" "exits 0 when all present"
	assert_eq "" "$(cat "$BREW_LOG")" "brew never invoked"
	rm -rf "$root"
}

# --- Test 3: missing dep, non-interactive (no --yes) -> report, no install ---
test_missing_noninteractive() {
	start "missing dep + no input: reports missing, non-zero, does NOT install"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh          # (shellcheck deliberately absent)
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null
	assert_ne 0 "$RC" "exits non-zero when a dep is missing and not installed"
	assert_contains "$OUT" "shellcheck" "reports the missing tool"
	assert_eq "" "$(cat "$BREW_LOG")" "brew NOT invoked without consent"
	rm -rf "$root"
}

# --- Test 4: missing dep + --yes -> installs via brew ------------------------
test_missing_yes_installs() {
	start "missing dep + --yes: brew installs the missing formula"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh          # (shellcheck absent)
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null --yes
	assert_eq 0 "$RC" "exits 0 after install"
	assert_contains "$(cat "$BREW_LOG")" "install" "brew install was called"
	assert_contains "$(cat "$BREW_LOG")" "shellcheck" "brew installed shellcheck"
	rm -rf "$root"
}

# --- Test 5: missing dep + 'y' on stdin -> installs -------------------------
test_missing_yes_prompt() {
	start "missing dep + 'y' answered at prompt: installs"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh
	make_brew "$root/bin" "$BREW_LOG"
	printf 'y\n' >"$root/yes.in"
	run_setup "$root/bin" Darwin "$root/yes.in"
	assert_eq 0 "$RC" "exits 0 after consenting"
	assert_contains "$(cat "$BREW_LOG")" "shellcheck" "brew installed shellcheck after 'y'"
	rm -rf "$root"
}

# --- Test 6: non-macOS -> manual instructions, no install -------------------
test_non_macos() {
	start "non-macOS: prints manual instructions, non-zero, no brew"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Linux /dev/null --yes
	assert_ne 0 "$RC" "exits non-zero on unsupported OS with missing deps"
	assert_contains "$OUT" "shellcheck" "still names the missing tool"
	assert_eq "" "$(cat "$BREW_LOG")" "brew not invoked off macOS"
	rm -rf "$root"
}

# --- Test 7: macOS but no brew -> points at brew.sh, no install -------------
test_no_brew() {
	start "macOS without Homebrew: points at brew.sh, non-zero"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git gh          # (no brew, no shellcheck)
	run_setup "$root/bin" Darwin /dev/null --yes
	assert_ne 0 "$RC" "exits non-zero when brew is absent"
	assert_contains "$OUT" "brew.sh" "points at Homebrew install page"
	rm -rf "$root"
}

# --- Test 8: --verify OFF -> readiness checks are skipped (gating) -----------
# gh is installed but NOT authenticated; without --verify that must NOT fail.
test_verify_gating() {
	start "no --verify: unauthenticated gh does not fail the run"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git shellcheck
	make_gh "$root/bin" 1 2.40.0            # auth status FAILS, but we don't verify
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null
	assert_eq 0 "$RC" "install-only run exits 0 even when gh is unauthenticated"
	rm -rf "$root"
}

# --- Test 9: --verify + gh authenticated -> exit 0 --------------------------
test_verify_auth_ok() {
	start "--verify: authenticated gh passes"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git shellcheck
	make_gh "$root/bin" 0 2.40.0            # auth status SUCCEEDS
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null --verify
	assert_eq 0 "$RC" "--verify exits 0 when the auth probe passes"
	rm -rf "$root"
}

# --- Test 10: --verify + gh NOT authenticated -> non-zero + remediation ------
test_verify_auth_fail() {
	start "--verify: unauthenticated gh fails with remediation"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git shellcheck
	make_gh "$root/bin" 1 2.40.0            # auth status FAILS
	make_brew "$root/bin" "$BREW_LOG"
	run_setup "$root/bin" Darwin /dev/null --verify
	assert_ne 0 "$RC" "--verify exits non-zero when the auth probe fails"
	assert_contains "$OUT" "gh auth login" "prints how to fix the unauthenticated gh"
	rm -rf "$root"
}

# --- Test 11: --verify + version meets minimum -> exit 0 --------------------
# Override CHECKS to a version check on gh; fake gh reports 2.40.0 >= 2.0.0.
test_verify_version_ok() {
	start "--verify: installed version >= minimum passes"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git shellcheck
	make_gh "$root/bin" 0 2.40.0
	make_brew "$root/bin" "$BREW_LOG"
	SETUP_CHECKS="gh|version|2.0.0|gh --version"
	run_setup "$root/bin" Darwin /dev/null --verify
	unset SETUP_CHECKS
	assert_eq 0 "$RC" "--verify exits 0 when version floor is met"
	rm -rf "$root"
}

# --- Test 12: --verify + version below minimum -> non-zero + names floor ------
test_verify_version_fail() {
	start "--verify: installed version < minimum fails, names the floor"
	local root; root="$(mktemp -d)"
	BREW_LOG="$root/brew.log"; : >"$BREW_LOG"
	make_bin "$root/bin" git shellcheck
	make_gh "$root/bin" 0 1.5.0             # too old
	make_brew "$root/bin" "$BREW_LOG"
	SETUP_CHECKS="gh|version|2.0.0|gh --version"
	run_setup "$root/bin" Darwin /dev/null --verify
	unset SETUP_CHECKS
	assert_ne 0 "$RC" "--verify exits non-zero when version is too old"
	assert_contains "$OUT" "2.0.0" "names the required minimum version"
	rm -rf "$root"
}

# --- Test 13: --help documents --verify -------------------------------------
test_help_documents_verify() {
	start "--help documents --verify"
	OUT="$("$BASH_BIN" "$SETUP" --help 2>&1)"
	RC=$?
	assert_eq 0 "$RC" "--help exits 0"
	assert_contains "$OUT" "--verify" "help documents the --verify flag"
}

echo "Running setup tests against: $SETUP"
echo
test_help
test_all_present
test_missing_noninteractive
test_missing_yes_installs
test_missing_yes_prompt
test_non_macos
test_no_brew
test_verify_gating
test_verify_auth_ok
test_verify_auth_fail
test_verify_version_ok
test_verify_version_fail
test_help_documents_verify
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
