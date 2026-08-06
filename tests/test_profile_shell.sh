#!/usr/bin/env bash
#
# test_profile_shell.sh — structural guard for profile-shell (#91, folds #84).
# profile-shell/SKILL.md is F3: the shell profile filled to the full
# profile-common skeleton (ADR-0001), cloning the F2/profile-python pattern. This
# test pins the required shape so a future edit — or drift from the skeleton —
# fails loudly: the six quality dimensions (in order), the scaffolding +
# cross-profile sections, the comprehensive security checklist wired to the real
# scanners (shellcheck + gitleaks, folding in #84), the observability rendering
# (real for shell, not N/A), and the traceability footer. Plain bash, no bats
# (matching test_profile_common.sh / test_profile_python.sh).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SKILL="$REPO_ROOT/payload/skills/profile-shell/SKILL.md"

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

echo "== profile-shell: the shell profile filled to the skeleton (ADR-0001, #91, folds #84) =="

start "profile file exists"
assert_exists "$SKILL" "profile-shell/SKILL.md exists"

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

start "best-practices dimension names the real shell tooling"
has "shellcheck" "linter (shellcheck)"
has "shfmt" "formatter (shfmt)"
has "set -euo pipefail" "strict mode"

start "performance dimension names ADR-0003 signals + tools (process-spawn cost)"
has "spawn" "process-spawn / fork cost signal"
has "hyperfine" "benchmark tool option"

start "testing dimension names bats + the opt-in integration lane + cross-shell"
has "bats" "test framework"
has "integration" "opt-in integration lane"
has "zsh" "cross-shell (bash + zsh) discipline"

start "security dimension is comprehensive and wired to the real scanners (folds #84)"
has "shellcheck" "primary scanner (shellcheck)"
has "gitleaks" "secret-scanner (the gap shellcheck won't cover)"
has "eval" "eval / injection check"
has "IFS" "word-splitting / \$IFS check"
has "mktemp" "temp-file / TOCTOU check"
has "rm -rf" "unsafe rm check"
has "curl" "untrusted fetch-exec check"
# The profile now OWNS the security section — the 'starter, see #84' hedge must be gone.
lacks "starter — non-exhaustive, see #84" "starter hedge removed (#84 subsumed)"

start "reliability dimension names failure-path idioms (deps, null-safety, retry)"
has "command -v" "dependency preflight"
has "timeout" "timeout at boundaries"
has "backoff" "retry/backoff idiom"
has "trap" "trap-based cleanup"

start "observability dimension renders the logging policy (real for shell, not N/A)"
has "design/logging-policy.md" "points at the authoritative policy"
has "stderr" "stderr destination"
has "--verbose" "verbose selects DEBUG"
has "log_error" "shell logging helpers"

start "references the shell-family skills rather than absorbing them (non-goal)"
has "zsh-script" "references zsh-script"
has "harden-shell-repo" "references harden-shell-repo"

start "traceability footer present"
has "Traceability" "traceability footer"
has "#91" "cites the issue"

echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
