#!/usr/bin/env bash
#
# test_dogfood.sh — does THIS repo obey the standard it ships?
# The SDLC prescribes a curated root design/ (payload: 23 refs to design/, 0 to
# docs/design/). This guard fails if the meta-repo drifts from its own rule, or
# if the README's layout block names a path that does not exist. Plain bash, no
# bats dependency (matching test_apply.sh / test_scaffold.sh style).

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
assert_exists() { if [[ -e "$1" ]]; then pass "$2"; else fail "missing: $1 — $2"; fi; }
assert_absent() { if [[ ! -e "$1" ]]; then pass "$2"; else fail "should not exist: $1 — $2"; fi; }
# assert a regex is ABSENT from a file (guards against a wrong doc reference)
assert_no_match() {
	if grep -qE "$2" "$1" 2>/dev/null; then
		fail "file $1 should not match /$2/ — $3"
	else
		pass "$3"
	fi
}

cd "$REPO_ROOT" || exit 1

echo "== dogfooding: repo conforms to the standard it ships =="

# #56 — the curated design lives at root design/, not docs/design/.
start "design at root"
assert_exists "design/overview.md" "design/overview.md exists at repo root"
assert_absent "docs/design" "docs/design/ no longer exists (drift removed)"
assert_no_match "README.md" "docs/design" "README does not reference docs/design/"

# #58 — the README layout block must not name a top-level dir that is absent.
start "README layout is honest"
assert_no_match "README.md" "^templates/" "README layout lists no phantom top-level templates/ dir"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
