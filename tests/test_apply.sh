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

assert_executable() { # path msg
	if [[ -x "$1" ]]; then pass "$2"; else fail "expected executable: $1 — $2"; fi
}

assert_not_contains() { # haystack needle msg
	if [[ "$1" != *"$2"* ]]; then pass "$3"; else fail "expected NOT to contain [$2] — $3"; fi
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
	# an executable payload file, so mode handling is covered (cf. scaffold.sh)
	printf '#!/usr/bin/env bash\necho v1\n' >"$SRC/payload/skills/sdlc-common/scaffold.sh"
	chmod +x "$SRC/payload/skills/sdlc-common/scaffold.sh"
}

# Rewrite the target manifest in the legacy (bare-path, no hash) format, as
# written by apply.sh before content hashes existed.
downgrade_manifest_to_legacy() {
	local m="$TGT/.sdlc/manifest" tmp
	tmp="$(mktemp)"
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		if [[ "$line" == *"  "* ]]; then printf '%s\n' "${line#*  }"; else printf '%s\n' "$line"; fi
	done <"$m" >"$tmp"
	mv "$tmp" "$m"
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

# ============================================================================
# Test 8 — drift guard: a locally edited owned file blocks install (#76a)
# ============================================================================
test_drift_blocks_install() {
	start "locally modified owned file blocks install"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'MY LOCAL EDIT\n' >>"$TGT/skills/sdlc-common/SKILL.md"
	printf 'feature command v2\n' >"$SRC/payload/commands/feature.md" # a real update is pending
	run_apply
	assert_eq 1 "$RC" "aborts non-zero on drift"
	assert_contains "$OUT" "locally modified" "explains the reason"
	assert_contains "$OUT" "skills/sdlc-common/SKILL.md" "names the drifted file"
	assert_file_is "$TGT/skills/sdlc-common/SKILL.md" \
		"sdlc-common skill v1
MY LOCAL EDIT" "local edit preserved"
	assert_file_is "$TGT/commands/feature.md" "feature command v1" "no partial write of other files"
	rm -rf "$root"
}

# ============================================================================
# Test 9 — --force discards local edits deliberately
# ============================================================================
test_drift_force_overwrites() {
	start "--force overwrites a locally modified file"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'MY LOCAL EDIT\n' >>"$TGT/skills/sdlc-common/SKILL.md"
	run_apply --force
	assert_eq 0 "$RC" "--force exits 0"
	assert_file_is "$TGT/skills/sdlc-common/SKILL.md" "sdlc-common skill v1" "edit discarded on --force"
	rm -rf "$root"
}

# ============================================================================
# Test 10 — drift and foreign collisions are reported as distinct causes
# ============================================================================
test_drift_vs_foreign_reported_separately() {
	start "drift and foreign collision reported separately"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'MY LOCAL EDIT\n' >>"$TGT/skills/sdlc-common/SKILL.md"   # ours, modified
	printf 'USER OWNED\n' >"$TGT/commands/other.md"                  # not ours
	printf 'other command\n' >"$SRC/payload/commands/other.md"       # now claimed by payload
	run_apply
	assert_eq 1 "$RC" "aborts non-zero"
	assert_contains "$OUT" "locally modified" "drift block present"
	assert_contains "$OUT" "don't own" "foreign-collision block present"
	rm -rf "$root"
}

# ============================================================================
# Test 11 — --status detects modified and missing files (#76b)
# ============================================================================
test_status_reports_drift() {
	start "--status reports modified and missing files"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'TRUNCATED\n' >"$TGT/commands/feature.md"
	rm -f "$TGT/skills/sdlc-common/SKILL.md"
	run_apply --status
	assert_eq 0 "$RC" "status still exits 0"
	assert_contains "$OUT" "modified" "reports the modified file class"
	assert_contains "$OUT" "commands/feature.md" "names the modified file"
	assert_contains "$OUT" "missing" "reports the missing file class"
	assert_contains "$OUT" "skills/sdlc-common/SKILL.md" "names the missing file"
	rm -rf "$root"
}

# ============================================================================
# Test 12 — --status is quiet about drift on a healthy install
# ============================================================================
test_status_clean_install() {
	start "--status reports a clean install as ok"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	run_apply --status
	assert_eq 0 "$RC" "status exits 0"
	assert_not_contains "$OUT" "modified:" "no modified files listed"
	assert_not_contains "$OUT" "missing:" "no missing files listed"
	rm -rf "$root"
}

# ============================================================================
# Test 13 — a legacy (bare-path) manifest upgrades without false drift
# ============================================================================
test_legacy_manifest_upgrade() {
	start "legacy manifest upgrades to hashes without false drift"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	downgrade_manifest_to_legacy
	printf 'EDITED BEFORE UPGRADE\n' >>"$TGT/skills/sdlc-common/SKILL.md"
	run_apply
	assert_eq 0 "$RC" "no false drift on first run after upgrade"
	assert_not_contains "$OUT" "locally modified" "does not claim drift it cannot know about"
	assert_contains "$(cat "$TGT/.sdlc/manifest")" "  commands/feature.md" "manifest rewritten with hashes"
	# protection is live from the next run on
	printf 'EDIT AFTER UPGRADE\n' >>"$TGT/skills/sdlc-common/SKILL.md"
	run_apply
	assert_eq 1 "$RC" "drift detected on the following run"
	rm -rf "$root"
}

# ============================================================================
# Test 14 — the executable bit is restored on update (#76c)
# ============================================================================
test_exec_bit_restored_on_update() {
	start "executable bit restored when a file is updated"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	assert_executable "$TGT/skills/sdlc-common/scaffold.sh" "executable on fresh install"
	chmod -x "$TGT/skills/sdlc-common/scaffold.sh"
	printf '#!/usr/bin/env bash\necho v2\n' >"$SRC/payload/skills/sdlc-common/scaffold.sh"
	chmod +x "$SRC/payload/skills/sdlc-common/scaffold.sh"
	run_apply --force # content drifted (we chmod'd, not edited) — force past the guard
	assert_executable "$TGT/skills/sdlc-common/scaffold.sh" "executable restored after update"
	rm -rf "$root"
}

# ============================================================================
# Test 15 — mode is repaired even when content is unchanged
#   (the "unchanged => skip" optimization must not skip a mode repair)
# ============================================================================
test_exec_bit_repaired_when_content_unchanged() {
	start "executable bit repaired when content is unchanged"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	chmod -x "$TGT/skills/sdlc-common/scaffold.sh"
	run_apply
	assert_eq 0 "$RC" "re-apply exits 0"
	assert_executable "$TGT/skills/sdlc-common/scaffold.sh" "mode repaired without a content change"
	rm -rf "$root"
}

# ============================================================================
# Test 16 — unchanged files are skipped and reported
# ============================================================================
test_unchanged_files_skipped() {
	start "unchanged files are skipped and reported"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	assert_contains "$OUT" "added 3" "fresh install reports 3 added"
	run_apply
	assert_eq 0 "$RC" "re-apply exits 0"
	assert_contains "$OUT" "unchanged 3" "re-apply reports all 3 unchanged"
	rm -rf "$root"
}

# ============================================================================
# Test 17 — uninstall preserves locally modified files unless --force
# ============================================================================
test_uninstall_preserves_drift() {
	start "--uninstall preserves locally modified files unless --force"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'MY LOCAL EDIT\n' >>"$TGT/skills/sdlc-common/SKILL.md"
	run_apply --uninstall
	assert_eq 0 "$RC" "uninstall exits 0"
	assert_exists "$TGT/skills/sdlc-common/SKILL.md" "modified file preserved"
	assert_absent "$TGT/commands/feature.md" "unmodified file removed"
	assert_exists "$TGT/.sdlc/manifest" "manifest retained to track what is left"
	assert_contains "$(cat "$TGT/.sdlc/manifest")" "skills/sdlc-common/SKILL.md" "manifest lists the preserved file"
	assert_not_contains "$(cat "$TGT/.sdlc/manifest")" "commands/feature.md" "manifest drops the removed file"
	run_apply --uninstall --force
	assert_eq 0 "$RC" "forced uninstall exits 0"
	assert_absent "$TGT/skills/sdlc-common/SKILL.md" "--force removes the modified file"
	assert_absent "$TGT/.sdlc" ".sdlc dir removed once nothing is left"
	rm -rf "$root"
}

# ============================================================================
# Test 18 — stale removal respects local edits too
#   A file dropped from the payload (e.g. a rename) must not be deleted out
#   from under the user if they had edited the installed copy.
# ============================================================================
test_stale_removal_preserves_drift() {
	start "stale removal preserves a locally modified file"
	local root; root="$(mktemp -d)"; make_fixture "$root"
	run_apply
	printf 'MY LOCAL EDIT\n' >>"$TGT/commands/feature.md"
	rm "$SRC/payload/commands/feature.md" # payload drops it (renamed, say)
	run_apply
	assert_eq 0 "$RC" "update still exits 0"
	assert_exists "$TGT/commands/feature.md" "locally modified stale file preserved"
	assert_contains "$OUT" "feature.md" "reports what it kept"
	# an untouched stale file is still removed
	printf 'other\n' >"$SRC/payload/commands/other.md"
	run_apply
	rm "$SRC/payload/commands/other.md"
	run_apply
	assert_absent "$TGT/commands/other.md" "untouched stale file still removed"
	rm -rf "$root"
}

# ============================================================================
# Test — a symlink at an owned path must not let apply.sh write outside --target
# (#77). A DANGLING symlink is invisible to [[ -e ]], so a plain cp would follow
# it and create the pointed-at file anywhere on disk. The installer must treat a
# symlink as present (a collision needing consent), never a silent add-through.
# ============================================================================
test_symlink_write_escape_refused() {
	local root
	root="$(mktemp -d)"
	make_fixture "$root"
	local outside="$root/outside"
	mkdir -p "$outside" "$TGT/commands"
	# attacker plants a dangling symlink at a to-be-installed owned path
	ln -s "$outside/escaped.md" "$TGT/commands/feature.md"

	start "a dangling symlink at an owned path does not let apply.sh write outside --target"
	run_apply
	assert_absent "$outside/escaped.md" "nothing written outside --target through the symlink"
	assert_eq 1 "$RC" "apply refuses (non-zero) rather than writing through the link"
	assert_contains "$OUT" "don't own" "the symlinked path is reported as a collision"
	rm -rf "$root"
}

# ============================================================================
# Test — uninstall removes a symlink at an owned path but never its target (#77).
# Characterization guard: the removal path is already safe (rm deletes the link,
# not what it points at); this pins that so a future change can't regress it.
# ============================================================================
test_uninstall_symlink_leaves_external_target() {
	local root
	root="$(mktemp -d)"
	make_fixture "$root"
	run_apply # normal install; commands/feature.md is now owned
	local outside="$root/outside"
	mkdir -p "$outside"
	printf 'EXTERNAL\n' >"$outside/secret.md"
	rm "$TGT/commands/feature.md"
	ln -s "$outside/secret.md" "$TGT/commands/feature.md"

	start "uninstall removes the symlink at an owned path but leaves its external target intact"
	run_apply --uninstall --force
	assert_exists "$outside/secret.md" "external target survives uninstall"
	assert_file_is "$outside/secret.md" "EXTERNAL" "external target content untouched"
	assert_absent "$TGT/commands/feature.md" "the symlink at the owned path is removed"
	rm -rf "$root"
}

# ============================================================================
# Test — a symlinked PARENT directory must not let apply.sh write outside
# --target (#83). #77 guards a symlink AT the final path component; a symlinked
# parent dir (e.g. $TGT/commands -> /outside) is the sibling hole: [[ -e/-L
# "$dest" ]] resolves THROUGH the parent, so the path classifies as a fresh ADD
# and cp writes into the external dir. The installer must refuse a path whose
# resolved parent escapes --target and write nothing outside.
# ============================================================================
test_symlink_parent_write_escape_refused() {
	local root
	root="$(mktemp -d)"
	make_fixture "$root"
	local outside="$root/outside"
	mkdir -p "$outside"
	# attacker plants a symlinked PARENT directory where an owned dir would be
	ln -s "$outside" "$TGT/commands"

	start "a symlinked parent dir does not let apply.sh write outside --target"
	run_apply
	assert_absent "$outside/feature.md" "nothing written outside --target through the symlinked parent"
	assert_eq 1 "$RC" "apply refuses (non-zero) rather than writing through the parent symlink"
	assert_contains "$OUT" "escapes --target" "the escaping parent is reported"
	rm -rf "$root"
}

# ============================================================================
# Test — uninstall/removal must not delete an external file THROUGH a symlinked
# parent dir (#83, removal mirror). rm -f "$dest" resolves through a symlinked
# parent and would delete the pointed-at file outside --target.
# ============================================================================
test_uninstall_symlink_parent_leaves_external_target() {
	local root
	root="$(mktemp -d)"
	make_fixture "$root"
	run_apply # normal install; commands/feature.md is now owned
	local outside="$root/outside"
	mkdir -p "$outside"
	printf 'EXTERNAL\n' >"$outside/feature.md"
	# attacker swaps the owned parent dir for a symlink to an external dir
	rm -rf "$TGT/commands"
	ln -s "$outside" "$TGT/commands"

	start "uninstall does not delete an external file through a symlinked parent dir"
	run_apply --uninstall --force
	assert_exists "$outside/feature.md" "external file survives uninstall (not removed through symlinked parent)"
	assert_file_is "$outside/feature.md" "EXTERNAL" "external file content untouched"
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
test_drift_blocks_install
test_drift_force_overwrites
test_drift_vs_foreign_reported_separately
test_status_reports_drift
test_status_clean_install
test_legacy_manifest_upgrade
test_exec_bit_restored_on_update
test_exec_bit_repaired_when_content_unchanged
test_unchanged_files_skipped
test_uninstall_preserves_drift
test_stale_removal_preserves_drift
test_symlink_write_escape_refused
test_uninstall_symlink_leaves_external_target
test_symlink_parent_write_escape_refused
test_uninstall_symlink_parent_leaves_external_target
echo
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
