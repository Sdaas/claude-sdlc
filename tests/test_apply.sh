#!/usr/bin/env bash
#
# test_apply.sh — behavior tests for apply.sh (the SDLC installer).
#
# Everything runs against throwaway --source and --target directories under
# a temp root, so neither this repo's real payload/ nor the real ~/.claude
# is ever touched.
#
# Plain bash, no bats dependency. Run: bash tests/test_apply.sh

set -uo pipefail

# --- locate the script under test -------------------------------------------
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
APPLY="$REPO_ROOT/apply.sh"

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

assert_eq() { # expected actual msg
	if [[ "$1" == "$2" ]]; then pass "$3"; else fail "expected [$1] got [$2] — $3"; fi
}

assert_exists() { # path msg
	if [[ -e "$1" ]]; then pass "$2"; else fail "expected to exist: $1 — $2"; fi
}

assert_absent() { # path msg
	if [[ ! -e "$1" ]]; then pass "$2"; else fail "expected absent: $1 — $2"; fi
}

assert_contains() { # haystack needle msg
	if [[ "$1" == *"$2"* ]]; then pass "$3"; else fail "expected to contain [$2] — $3"; fi
}

assert_file_is() { # path expected-content msg
	local got
	got="$(cat "$1" 2>/dev/null || true)"
	if [[ "$got" == "$2" ]]; then pass "$3"; else fail "file $1: expected [$2] got [$got] — $3"; fi
}

# --- fixtures ---------------------------------------------------------------
# Build a fake SOURCE repo (VERSION + payload/) and an empty TARGET.
make_fixture() {
	local root="$1"
	SRC="$root/src"
	TGT="$root/tgt"
	mkdir -p "$SRC/payload/commands" "$SRC/payload/skills/sdlc-common" "$TGT"
	printf '0.1.0\n' >"$SRC/VERSION"
	printf 'feature command v1\n' >"$SRC/payload/commands/feature.md"
	printf 'sdlc-common skill v1\n' >"$SRC/payload/skills/sdlc-common/SKILL.md"
}

run_apply() { # args...  -> sets OUT and RC
	OUT="$("$APPLY" --source "$SRC" --target "$TGT" "$@" 2>&1)"
	RC=$?
}

# ============================================================================
# Test 1 — fresh install
# ============================================================================
test_fresh_install() {
	start "fresh install copies payload + writes manifest/version"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	assert_eq 0 "$RC" "exit 0 on fresh install"
	assert_file_is "$TGT/commands/feature.md" "feature command v1" "command copied"
	assert_file_is "$TGT/skills/sdlc-common/SKILL.md" "sdlc-common skill v1" "nested skill copied"
	assert_exists "$TGT/.sdlc/manifest" "manifest written"
	assert_exists "$TGT/.sdlc/version" "version stamp written"
	assert_contains "$(cat "$TGT/.sdlc/manifest")" "commands/feature.md" "manifest lists command"
	assert_contains "$(cat "$TGT/.sdlc/version")" "0.1.0" "version stamp has version"
	rm -rf "$root"
}

# ============================================================================
# Test 2 — --status reports installed version
# ============================================================================
test_status() {
	start "--status reports installed version"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	run_apply --status
	assert_eq 0 "$RC" "status exits 0"
	assert_contains "$OUT" "0.1.0" "status shows version"
	rm -rf "$root"
}

# ============================================================================
# Test 3 — --dry-run changes nothing
# ============================================================================
test_dry_run() {
	start "--dry-run prints plan but writes nothing"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply --dry-run
	assert_eq 0 "$RC" "dry-run exits 0"
	assert_absent "$TGT/commands/feature.md" "no file copied in dry-run"
	assert_absent "$TGT/.sdlc" "no .sdlc dir in dry-run"
	rm -rf "$root"
}

# ============================================================================
# Test 4 — idempotent re-apply
# ============================================================================
test_idempotent() {
	start "re-apply is idempotent"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	local m1; m1="$(cat "$TGT/.sdlc/manifest")"
	run_apply
	assert_eq 0 "$RC" "second apply exits 0"
	assert_eq "$m1" "$(cat "$TGT/.sdlc/manifest")" "manifest unchanged on re-apply"
	rm -rf "$root"
}

# ============================================================================
# Test 5 — stale removal
# ============================================================================
test_stale_removal() {
	start "removed payload file is deleted on update"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	assert_exists "$TGT/commands/feature.md" "installed before update"
	rm "$SRC/payload/commands/feature.md"
	run_apply
	assert_eq 0 "$RC" "update exits 0"
	assert_absent "$TGT/commands/feature.md" "stale file removed"
	assert_exists "$TGT/skills/sdlc-common/SKILL.md" "other files retained"
	rm -rf "$root"
}

# ============================================================================
# Test 6 — collision guard
# ============================================================================
test_collision() {
	start "foreign file at target path blocks install unless --force"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	mkdir -p "$TGT/commands"
	printf 'USER OWNED\n' >"$TGT/commands/feature.md"
	run_apply
	assert_eq 1 "$RC" "aborts non-zero on collision"
	assert_file_is "$TGT/commands/feature.md" "USER OWNED" "foreign file left untouched"
	run_apply --force
	assert_eq 0 "$RC" "--force succeeds"
	assert_file_is "$TGT/commands/feature.md" "feature command v1" "--force overwrites foreign file"
	rm -rf "$root"
}

# ============================================================================
# Test 7 — uninstall
# ============================================================================
test_uninstall() {
	start "--uninstall removes owned files but not foreign files"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	# a foreign file we must NOT touch
	mkdir -p "$TGT/commands"
	printf 'keep me\n' >"$TGT/commands/other.md"
	run_apply
	run_apply --uninstall
	assert_eq 0 "$RC" "uninstall exits 0"
	assert_absent "$TGT/commands/feature.md" "owned command removed"
	assert_absent "$TGT/skills/sdlc-common" "owned skill removed"
	assert_absent "$TGT/.sdlc" ".sdlc dir removed"
	assert_file_is "$TGT/commands/other.md" "keep me" "foreign file preserved"
	rm -rf "$root"
}

# --- run all ----------------------------------------------------------------
echo "Running apply.sh tests against: $APPLY"
echo
test_fresh_install
test_status
test_dry_run
test_idempotent
test_stale_removal
test_collision
test_uninstall
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
