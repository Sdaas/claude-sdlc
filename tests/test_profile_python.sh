#!/usr/bin/env bash
#
# test_profile_python.sh — structural guard for the profile-python pilot (#90).
# profile-python/SKILL.md is F2: the first profile filled to the full
# profile-common skeleton (ADR-0001), the reference pattern F3-F5 clone. This
# test pins the required shape so a future edit — or a clone that drifts — fails
# loudly: the six quality dimensions (in order), the scaffolding + cross-profile
# sections, the security checklist wired to the real scanners (ruff -S /
# pip-audit, folding in #85), the observability rendering (not N/A for python),
# and the traceability footer. Plain bash, no bats (matching test_profile_common.sh).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILL="$REPO_ROOT/payload/skills/profile-python/SKILL.md"

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
# assert a fixed string is ABSENT (used to prove the 'starter' hedges are gone)
lacks() { if grep -qF -- "$1" "$SKILL" 2>/dev/null; then fail "SKILL.md still contains [$1] — $2"; else pass "$2"; fi; }
# assert two fixed strings appear in order (a before b)
in_order() {
	local la lb
	la="$(grep -nF -- "$1" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	lb="$(grep -nF -- "$2" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	if [[ -n "$la" && -n "$lb" && "$la" -lt "$lb" ]]; then pass "$3"; else fail "expected [$1] before [$2] — $3"; fi
}

echo "== profile-python: the pilot profile filled to the skeleton (ADR-0001, #90) =="

start "profile file exists"
assert_exists "$SKILL" "profile-python/SKILL.md exists"

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

start "content-kind sections present"
has "## Scaffolding" "Scaffolding section (references templates/, ADR-0004)"
has "templates/" "Scaffolding points at the existing templates dir (no copy)"
has "## Cross-profile testing" "Cross-profile testing section (F6/#94 stub)"

start "best-practices dimension names the real python tooling"
has "ruff check" "lint command"
has "ruff format" "format command"
has "src/" "src layout"

start "performance dimension names ADR-0003 signals + tools"
has "cProfile" "hot-path profiler"
has "timeit" "micro-benchmark tool"

start "testing dimension names pytest + the opt-in integration lane"
has "pytest" "test framework"
has "integration" "opt-in integration lane"

start "security dimension is comprehensive and wired to the real scanners (folds #85)"
has "ruff check --select S" "primary scanner command (ruff S-rules)"
has "pip-audit" "dependency-CVE scanner"
has "shell=True" "command-injection check"
has "yaml.safe_load" "unsafe-deserialization check"
has "verify=False" "TLS check"
# The pilot OWNS the security section — the 'starter, see #85' hedge must be gone.
lacks "starter — non-exhaustive, see #85" "starter hedge removed (#85 subsumed)"

start "reliability dimension names failure-path idioms"
has "timeout" "timeout idiom at boundaries"
has "backoff" "retry/backoff idiom"

start "observability dimension renders the logging policy (real for python, not N/A)"
has "design/logging-policy.md" "points at the authoritative policy"
has "stderr" "stderr destination"
has "--verbose" "verbose selects DEBUG"

start "web/API service section present (FastAPI standard + auth + the four concerns)"
has "## Web / API service" "Web/API content-kind section"
has "FastAPI" "names FastAPI as the standard framework"
has "uvicorn" "names the ASGI server"
has "gunicorn" "names the prod process manager"
has "Depends(" "auth enforced via a Depends() dependency"
has "JWT" "documents JWT bearer auth"
has "API key" "documents API-key auth"
has "Session cookie" "documents session-cookie auth"
has "/healthz" "health/readiness endpoints"
has "pydantic-settings" "12-factor config from env"
has "SQLAlchemy" "DB/ORM standard"
has "DRF" "documents the Django REST alternative"
in_order "## Scaffolding" "## Web / API service" "Scaffolding before Web/API (content-kind order)"
in_order "## Web / API service" "## Cross-profile testing" "Web/API before Cross-profile testing"

start "traceability footer present"
has "Traceability" "traceability footer"
has "#90" "cites the issue"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
