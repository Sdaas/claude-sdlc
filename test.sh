#!/usr/bin/env bash
#
# test.sh — single test entrypoint for this repo.
# Runs shellcheck (if available) then all behavior tests. Non-zero on any failure.
# This is what the pre-push hook and CI both call.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=0

SHELL_FILES=(
	apply.sh test.sh release.sh install-hooks.sh hooks/pre-push
	tests/test_apply.sh tests/test_scaffold.sh
	payload/skills/sdlc-common/scaffold.sh
)

echo "==> shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
	existing=()
	for f in "${SHELL_FILES[@]}"; do [[ -f "$f" ]] && existing+=("$f"); done
	if shellcheck "${existing[@]}"; then
		echo "    clean"
	else
		echo "    shellcheck FAILED"
		FAILED=1
	fi
else
	echo "    shellcheck not installed — skipped"
fi

echo "==> tests/test_apply.sh"
if bash tests/test_apply.sh; then
	echo "    apply tests passed"
else
	echo "    apply tests FAILED"
	FAILED=1
fi

echo "==> tests/test_scaffold.sh"
if bash tests/test_scaffold.sh; then
	echo "    scaffold tests passed"
else
	echo "    scaffold tests FAILED"
	FAILED=1
fi

echo
if [[ "$FAILED" -eq 0 ]]; then
	echo "ALL TESTS PASSED"
else
	echo "TESTS FAILED"
fi
exit "$FAILED"
