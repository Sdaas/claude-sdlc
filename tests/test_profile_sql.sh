#!/usr/bin/env bash
#
# test_profile_sql.sh — structural guard for profile-sql (F4/#92, greenfield).
# profile-sql/SKILL.md is the SQL profile filled to the full profile-common
# skeleton (ADR-0001), cloning the F2/profile-python + F3/profile-shell pattern.
# This test pins the required shape so a future edit — or drift from the skeleton
# — fails loudly: the six quality dimensions (in order), the scaffolding (N/A for
# sql) + cross-profile sections, the NEW comprehensive SQL security section
# (sql was absent from #84–86) wired to a real linter (sqlfluff) + secret scan,
# the observability rendering (real for sql — slow-query logging, not N/A), the
# Postgres-reference / portable-first stance, and the traceability footer. Plain
# bash, no bats (matching test_profile_common.sh / _python.sh / _shell.sh).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILL="$REPO_ROOT/payload/skills/profile-sql/SKILL.md"

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
# assert a fixed string is ABSENT
lacks() { if grep -qF -- "$1" "$SKILL" 2>/dev/null; then fail "SKILL.md still contains [$1] — $2"; else pass "$2"; fi; }
# assert two fixed strings appear in order (a before b)
in_order() {
	local la lb
	la="$(grep -nF -- "$1" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	lb="$(grep -nF -- "$2" "$SKILL" 2>/dev/null | head -1 | cut -d: -f1)"
	if [[ -n "$la" && -n "$lb" && "$la" -lt "$lb" ]]; then pass "$3"; else fail "expected [$1] before [$2] — $3"; fi
}

echo "== profile-sql: the SQL profile filled to the skeleton (ADR-0001, F4/#92, greenfield) =="

start "profile file exists"
assert_exists "$SKILL" "profile-sql/SKILL.md exists"

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

start "content-kind sections present (scaffolding is N/A for sql, ADR-0004)"
has "## Scaffolding" "Scaffolding section kept (N/A stated, never dropped)"
has "N/A" "Scaffolding states N/A — why (sql ships no scaffolding in v1)"
has "## Cross-profile testing" "Cross-profile testing section (F6/#94 stub)"

start "dialect stance: Postgres as reference, portable-first"
has "PostgreSQL" "names PostgreSQL as the concrete reference dialect"
has "portab" "portability called out (portable-first)"
has "MySQL" "names a divergent dialect (MySQL)"
has "SQLite" "names a divergent dialect (SQLite)"

start "best-practices dimension names the real sql tooling + conventions"
has "sqlfluff" "linter/formatter (sqlfluff)"
has "snake_case" "naming convention"
has "migration" "schema/migration conventions"
has "Flyway" "names the migration tool field (tool-neutral)"

start "performance dimension names ADR-0003 signals + tools (EXPLAIN, N+1)"
has "EXPLAIN" "query-plan tool (EXPLAIN / ANALYZE)"
has "index" "missing-index / full-scan check"
has "N+1" "N+1 signal"

start "testing dimension: host app test.sh + opt-in DB-integration lane + pgTAP"
has "test.sh" "runs through the host app's test.sh"
has "integration" "opt-in DB-integration lane"
has "self-skip" "lane self-skips when no DB present"
has "pgTAP" "in-DB test option (pgTAP / pg_prove)"
has "seed" "seed-data fixtures"

start "security dimension is NEW + comprehensive (sql absent from #84–86)"
has "sqlfluff" "primary linter/scanner reused for security"
has "gitleaks" "secret-scanner companion"
has "parameter" "parameterization / injection check"
has "injection" "SQL injection named"
has "GRANT" "least-privilege grants check"
has "PII" "PII handling check"
has "search_path" "search_path / definer-safety check"
has "sdlc-security" "delegates review method to the shared skill"

start "reliability dimension names failure-path idioms (timeout, txn, retry)"
has "timeout" "connection/statement timeout"
has "transaction" "transaction / rollback safety"
has "deadlock" "retry on transient (deadlock/serialization)"
has "NULL" "null-handling semantics"

start "observability dimension renders the logging policy (real for sql, not N/A)"
has "design/logging-policy.md" "points at the authoritative policy"
has "log_min_duration_statement" "slow-query logging mechanism"
has "auto_explain" "auto_explain for plan capture"

start "traceability footer present"
has "Traceability" "traceability footer"
has "#92" "cites the issue"
has "UC-001" "cites a served use case"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
