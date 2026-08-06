#!/usr/bin/env bash
#
# test_profile_common.sh — structural guard for the profile-common backbone (#89).
# profile-common/SKILL.md is the fixed skeleton every profile-<stack> clones
# (ADR-0001). This test pins the required shape: the six quality-dimension
# sections (in order), the scaffolding + cross-profile testing sections, the
# shared-standard pointers, and the N/A rule. If a future edit drops or renames a
# section the shape breaks and F2-F5 authors lose their reference — this fails
# loudly. Plain bash, no bats dependency (matching test_scaffold.sh style).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILL="$REPO_ROOT/payload/skills/profile-common/SKILL.md"

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
# assert a fixed string is present in the SKILL file
has() { if grep -qF -- "$1" "$SKILL" 2>/dev/null; then pass "$2"; else fail "SKILL.md missing [$1] — $2"; fi; }
# assert two fixed strings appear in order (a before b)
in_order() {
	local la lb
	la="$(grep -nF -- "$1" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	lb="$(grep -nF -- "$2" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	if [[ -n "$la" && -n "$lb" && "$la" -lt "$lb" ]]; then pass "$3"; else fail "expected [$1] before [$2] — $3"; fi
}

echo "== profile-common: the SKILL.md skeleton (ADR-0001, #89) =="

start "skeleton file exists"
assert_exists "$SKILL" "profile-common/SKILL.md exists"

start "six quality dimensions present, in order"
has "## 1. Best practices" "dim 1 — Best practices"
has "## 2. Performance & scale" "dim 2 — Performance & scale"
has "## 3. Testing pyramid" "dim 3 — Testing pyramid"
has "## 4. Security" "dim 4 — Security"
has "## 5. Reliability & resilience" "dim 5 — Reliability & resilience"
has "## 6. Observability & logging" "dim 6 — Observability & logging"
in_order "## 1. Best practices" "## 2. Performance & scale" "dim 1 before dim 2"
in_order "## 5. Reliability & resilience" "## 6. Observability & logging" "dim 5 before dim 6"

start "content-kind sections present"
has "## Scaffolding" "Scaffolding section (shell/python only)"
has "## Cross-profile testing" "Cross-profile testing section shell (ADR-0002)"

start "pointers to shared standards"
has "sdlc-security" "Security dimension points at sdlc-security"
has "design/logging-policy.md" "Observability dimension points at logging-policy.md"

start "the N/A rule is stated"
has "N/A — why" "N/A rule (a dimension states 'N/A — why', never drops the section)"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
