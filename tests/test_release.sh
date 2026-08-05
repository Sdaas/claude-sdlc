#!/usr/bin/env bash
#
# test_release.sh — behavior tests for release.sh.
# Scoped to the pure, side-effect-free surface (--help). release.sh otherwise
# tags/pushes git, which we do not exercise here. Plain bash, no bats dependency
# (matching test_apply.sh / test_scaffold.sh style).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
RELEASE="$REPO_ROOT/release.sh"

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
assert_contains() { if [[ "$1" == *"$2"* ]]; then pass "$3"; else fail "expected to contain [$2] — $3"; fi; }
assert_not_contains() { if [[ "$1" != *"$2"* ]]; then pass "$3"; else fail "expected NOT to contain [$2] — $3"; fi; }

# --help must render the header comment only, never leak script code (#78).
# release.sh sliced a fixed line range (correct by luck today); this guard fails
# if the header outgrows it, the same rot that bit scaffold.sh.
test_help_no_code_leak() {
	start "release.sh --help prints usage text, not code"
	local out
	out="$("$RELEASE" --help 2>&1)"
	assert_contains "$out" "Usage:" "help shows the usage line"
	assert_not_contains "$out" "set -euo pipefail" "help does not leak the strict-mode line"
	assert_not_contains "$out" "REPO_ROOT=" "help does not leak code below the header"
}

echo "Running release.sh tests against: $RELEASE"
echo
test_help_no_code_leak
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
