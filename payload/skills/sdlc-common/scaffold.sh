#!/usr/bin/env bash
#
# scaffold.sh — render the SDLC repo skeleton into a target directory.
#
# Called by /newproject with the interview answers. Substitutes {{PLACEHOLDER}}
# tokens in templates/ using bash string replacement (bash 3.2 compatible; no
# sed escaping pitfalls). Refuses a non-empty target unless --force.
#
# Usage:
#   scaffold.sh --target DIR --name NAME [options]
# Options:
#   --purpose "text"        one-line purpose
#   --profile shell|python|sql|frontend   (default: shell)
#   --archetype cli|library|service|webapp|pipeline   (default: cli)
#   --distribution none|brew|pip|npm|container         (default: none)
#   --license mit|apache|none                          (default: mit)
#   --author "Name"         (default: git config user.name, else "Unknown")
#   --force                 write even if target is non-empty
#   --help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/templates"

# --- defaults ---------------------------------------------------------------
TARGET=""
NAME=""
PURPOSE=""
PROFILE="shell"
ARCHETYPE="cli"
DISTRIBUTION="none"
LICENSE="mit"
AUTHOR=""
FORCE=false

die() {
	printf 'scaffold.sh: error: %s\n' "$1" >&2
	exit 1
}
usage() { sed -n '3,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# --- args -------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
	case "$1" in
	--target) TARGET="${2:-}"; shift ;;
	--name) NAME="${2:-}"; shift ;;
	--purpose) PURPOSE="${2:-}"; shift ;;
	--profile) PROFILE="${2:-}"; shift ;;
	--archetype) ARCHETYPE="${2:-}"; shift ;;
	--distribution) DISTRIBUTION="${2:-}"; shift ;;
	--license) LICENSE="${2:-}"; shift ;;
	--author) AUTHOR="${2:-}"; shift ;;
	--force) FORCE=true ;;
	--help | -h) usage; exit 0 ;;
	*) die "unknown argument: $1 (try --help)" ;;
	esac
	shift
done

[[ -n "$TARGET" ]] || die "--target is required"
[[ -n "$NAME" ]] || die "--name is required"
if [[ -z "$AUTHOR" ]]; then
	AUTHOR="$(git config user.name 2>/dev/null || true)"
	[[ -n "$AUTHOR" ]] || AUTHOR="Unknown"
fi
YEAR="$(date +%Y)"

# --- non-empty guard --------------------------------------------------------
if [[ -d "$TARGET" ]] && [[ -n "$(ls -A "$TARGET" 2>/dev/null || true)" ]]; then
	$FORCE || die "target not empty: $TARGET (use --force)"
fi

# --- render helper ----------------------------------------------------------
# render SRC DST — substitute placeholders from SRC template into DST.
render() {
	local src="$1" dst="$2" content
	content="$(cat "$src")"
	content="${content//\{\{NAME\}\}/$NAME}"
	content="${content//\{\{PURPOSE\}\}/$PURPOSE}"
	content="${content//\{\{PROFILE\}\}/$PROFILE}"
	content="${content//\{\{ARCHETYPE\}\}/$ARCHETYPE}"
	content="${content//\{\{DISTRIBUTION\}\}/$DISTRIBUTION}"
	content="${content//\{\{AUTHOR\}\}/$AUTHOR}"
	content="${content//\{\{YEAR\}\}/$YEAR}"
	mkdir -p "$(dirname "$dst")"
	printf '%s\n' "$content" >"$dst"
}

# --- core skeleton ----------------------------------------------------------
mkdir -p "$TARGET"

render "$TEMPLATES/core/README.md.tmpl" "$TARGET/README.md"
render "$TEMPLATES/core/gitignore.tmpl" "$TARGET/.gitignore"
render "$TEMPLATES/core/CLAUDE.md.tmpl" "$TARGET/CLAUDE.md"
render "$TEMPLATES/core/design-overview.md.tmpl" "$TARGET/design/overview.md"
render "$TEMPLATES/core/pre-push.tmpl" "$TARGET/hooks/pre-push"
render "$TEMPLATES/core/install-hooks.sh.tmpl" "$TARGET/install-hooks.sh"
render "$TEMPLATES/core/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"

printf '0.1.0\n' >"$TARGET/VERSION"
mkdir -p "$TARGET/docs/retrospectives"
: >"$TARGET/docs/retrospectives/.gitkeep"

# --- license ----------------------------------------------------------------
case "$LICENSE" in
none) : ;;
mit | apache)
	lic="$TEMPLATES/licenses/$LICENSE.tmpl"
	[[ "$LICENSE" == "apache" ]] && lic="$TEMPLATES/licenses/apache-2.0.tmpl"
	[[ -f "$lic" ]] || die "no license template for: $LICENSE"
	render "$lic" "$TARGET/LICENSE"
	;;
*) die "unknown license: $LICENSE" ;;
esac

# --- executable bits --------------------------------------------------------
chmod +x "$TARGET/hooks/pre-push" "$TARGET/install-hooks.sh"

echo "Scaffolded $NAME ($PROFILE/$ARCHETYPE) into $TARGET"
