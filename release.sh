#!/usr/bin/env bash
#
# release.sh — bump VERSION, tag, and push.
#
# Usage:
#   ./release.sh patch|minor|major     Bump the corresponding semver component
#   ./release.sh --version X.Y.Z        Set an explicit version
#   ./release.sh --help
#
# Refuses to run on a dirty tree, off main, or with a failing test suite.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT" || exit 1

die() {
	printf 'release.sh: error: %s\n' "$1" >&2
	exit 1
}

# Print the header comment (from line 3 to the first non-comment line) as usage.
# Scanning to the first non-# line — not a fixed range — so the header can grow
# without leaking code into --help (#78).
usage() {
	awk 'NR < 3 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

[[ $# -ge 1 ]] || {
	usage
	exit 1
}

CURRENT="$(head -n1 VERSION)"
IFS='.' read -r MAJOR MINOR PATCH <<<"$CURRENT"

case "$1" in
--help | -h)
	usage
	exit 0
	;;
patch) NEW="$MAJOR.$MINOR.$((PATCH + 1))" ;;
minor) NEW="$MAJOR.$((MINOR + 1)).0" ;;
major) NEW="$((MAJOR + 1)).0.0" ;;
--version)
	NEW="${2:-}"
	[[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version: $NEW"
	;;
*) die "unknown argument: $1 (try --help)" ;;
esac

# Preconditions.
[[ "$(git branch --show-current)" == "main" ]] || die "must be on main to release"
[[ -z "$(git status --porcelain)" ]] || die "working tree is dirty — commit first"
git rev-parse "v$NEW" >/dev/null 2>&1 && die "tag v$NEW already exists"

echo "==> running test suite"
./test.sh || die "tests must pass before release"

echo "==> bumping $CURRENT -> $NEW"
printf '%s\n' "$NEW" >VERSION
git add VERSION
git commit -m "Release v$NEW"
git tag -a "v$NEW" -m "Release v$NEW"

echo "==> pushing"
git push origin main
git push origin "v$NEW"

echo "Released v$NEW"
