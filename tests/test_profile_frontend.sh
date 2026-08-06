#!/usr/bin/env bash
#
# test_profile_frontend.sh — structural guard for profile-frontend (F5/#93, folds #86).
# profile-frontend/SKILL.md grows from its starter to the full profile-common
# skeleton (ADR-0001), cloning the F2/python + F3/shell + F4/sql pattern. This
# test pins the required shape so a future edit — or drift from the skeleton —
# fails loudly: the six quality dimensions (in order), the scaffolding (REAL for
# frontend — points at templates/, since scaffold.sh renders it) + cross-profile
# sections, the comprehensive security checklist wired to real scanners (npm
# audit + gitleaks, folding in #86), the observability rendering (real for
# frontend — console/browser, not N/A), and the traceability footer. Plain bash,
# no bats (matching test_profile_common.sh / _python.sh / _shell.sh / _sql.sh).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILL="$REPO_ROOT/payload/skills/profile-frontend/SKILL.md"

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
# assert a fixed string is ABSENT (used to prove the 'starter' hedge is gone)
lacks() { if grep -qF -- "$1" "$SKILL" 2>/dev/null; then fail "SKILL.md still contains [$1] — $2"; else pass "$2"; fi; }
# assert two fixed strings appear in order (a before b)
in_order() {
	local la lb
	la="$(grep -nF -- "$1" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	lb="$(grep -nF -- "$2" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	if [[ -n "$la" && -n "$lb" && "$la" -lt "$lb" ]]; then pass "$3"; else fail "expected [$1] before [$2] — $3"; fi
}

echo "== profile-frontend: the frontend profile filled to the skeleton (ADR-0001, F5/#93, folds #86) =="

start "profile file exists"
assert_exists "$SKILL" "profile-frontend/SKILL.md exists"

start "six quality dimensions present, in skeleton order"
has "## 1. Best practices" "dim 1 — Best practices"
has "## 2. Performance & scale" "dim 2 — Performance & scale"
has "## 3. Testing pyramid" "dim 3 — Testing pyramid"
has "## 4. Security" "dim 4 — Security"
has "## 5. Reliability & resilience" "dim 5 — Reliability & resilience"
has "## 6. Observability & logging" "dim 6 — Observability & logging"
in_order "## 1. Best practices" "## 2. Performance & scale" "dim 1 before dim 2"
in_order "## 2. Performance & scale" "## 3. Testing pyramid" "dim 2 before dim 3"
in_order "## 3. Testing pyramid" "## 4. Security" "dim 3 before dim 4"
in_order "## 4. Security" "## 5. Reliability & resilience" "dim 4 before dim 5"
in_order "## 5. Reliability & resilience" "## 6. Observability & logging" "dim 5 before dim 6"

start "content-kind sections present (scaffolding is REAL for frontend — templates/ ships)"
has "## Scaffolding" "Scaffolding section present"
has "templates/" "Scaffolding points at the existing templates dir (real, not N/A)"
has "## Cross-profile testing" "Cross-profile testing section (F6/#94 stub)"

start "best-practices dimension names the real frontend tooling"
has "Vite" "bundler/build (Vite)"
has "TypeScript" "language (TypeScript)"
has "tsc" "type-check (tsc --noEmit)"
has "prettier" "formatter (prettier)"

start "performance dimension names ADR-0003 signals (bundle, waterfall, main-thread)"
has "bundle" "bundle-size budget signal"
has "waterfall" "network waterfall signal"
has "main-thread" "main-thread blocking signal"

start "testing dimension names Vitest + the opt-in integration lane + e2e option"
has "Vitest" "test framework (Vitest)"
has "integration" "opt-in integration lane"
has "self-skip" "lane self-skips when its boundary is absent"
has "Playwright" "e2e option named"

start "security dimension is comprehensive and wired to real scanners (folds #86)"
has "npm audit" "dependency scanner (npm audit)"
has "gitleaks" "secret-scanner companion"
has "innerHTML" "XSS: innerHTML"
has "dangerouslySetInnerHTML" "XSS: dangerouslySetInnerHTML"
has "document.write" "XSS: document.write"
has "postMessage" "cross-origin postMessage origin check"
has "CSP" "Content-Security-Policy"
has "noopener" "reverse-tabnabbing (rel=noopener)"
has "CSRF" "token storage / CSRF"
has "localStorage" "auth token storage (localStorage vs httpOnly)"
has "SRI" "subresource integrity / unvetted CDN"
has "sdlc-security" "delegates review method to the shared skill"
# The profile now OWNS the security section — the 'starter, see #86' hedge must be gone.
lacks "starter — non-exhaustive, see #86" "starter hedge removed (#86 subsumed)"

start "reliability dimension names failure-path idioms (null-safety, timeout, retry, boundaries)"
has "AbortController" "fetch timeout via AbortController"
has "timeout" "timeout at network boundary"
has "backoff" "retry/backoff idiom"
has "boundar" "error boundaries / offline handling"

start "observability dimension renders the logging policy (real for frontend, not N/A)"
has "design/logging-policy.md" "points at the authoritative policy"
has "console" "console.* logging mechanism"
has "source map" "source maps for error diagnosis"
has "PII" "no secrets/PII in client logs"

start "traceability footer present"
has "Traceability" "traceability footer"
has "#93" "cites the issue"
has "#86" "cites the subsumed security issue"
has "UC-001" "cites a served use case"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
