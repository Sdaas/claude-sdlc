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
# Print the header comment (from line 3 to the first non-comment line) as usage.
# Scanning to the first non-# line — not a fixed range — so the header can grow
# without leaking code into --help (#78).
usage() {
	awk 'NR < 3 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

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

# CamelCase class name for the brew formula (e.g. my-tool -> MyTool).
CLASS=""
_saved_ifs="$IFS"
IFS='-_ '
for _part in $NAME; do
	_first="$(printf '%s' "${_part:0:1}" | tr '[:lower:]' '[:upper:]')"
	CLASS="$CLASS$_first${_part:1}"
done
IFS="$_saved_ifs"

# Python package name: lowercase, hyphens/spaces -> underscores (my-tool -> my_tool).
PKG="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' -' '__')"

# npm-safe package name: lowercase, spaces/underscores -> hyphens (My Tool -> my-tool).
SLUG="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '--')"

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
	content="${content//\{\{CLASS\}\}/$CLASS}"
	content="${content//\{\{PKG\}\}/$PKG}"
	content="${content//\{\{SLUG\}\}/$SLUG}"
	mkdir -p "$(dirname "$dst")"
	printf '%s\n' "$content" >"$dst"
}

# Render the python-profile files (pyproject, src/<pkg>, tests, test.sh via uv).
render_python_profile() {
	local pt
	pt="$(dirname "$SCRIPT_DIR")/profile-python/templates"
	[[ -d "$pt" ]] || die "no profile-python templates at: $pt"
	render "$pt/pyproject.toml.tmpl" "$TARGET/pyproject.toml"
	render "$pt/init.py.tmpl" "$TARGET/src/$PKG/__init__.py"
	render "$pt/cli.py.tmpl" "$TARGET/src/$PKG/cli.py"
	render "$pt/test-pkg.py.tmpl" "$TARGET/tests/test_$PKG.py"
	render "$pt/test.sh.tmpl" "$TARGET/test.sh"
	render "$pt/release.sh.tmpl" "$TARGET/release.sh"
	# Python CI installs uv — overrides the generic core CI.
	render "$pt/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"
	# setup.sh lists uv on top of git/gh — overrides the generic core setup.sh.
	render "$pt/setup.sh.tmpl" "$TARGET/setup.sh"
	chmod +x "$TARGET/test.sh" "$TARGET/release.sh" "$TARGET/setup.sh"
}

# Render the shell-profile files (test.sh via bats, tool, release, CI, formula).
render_shell_profile() {
	local st
	st="$(dirname "$SCRIPT_DIR")/profile-shell/templates"
	[[ -d "$st" ]] || die "no profile-shell templates at: $st"
	render "$st/bin-tool.tmpl" "$TARGET/bin/$NAME"
	render "$st/tool.bats.tmpl" "$TARGET/tests/$NAME.bats"
	# Seed the opt-in integration lane (real-boundary bats; run via ./test.sh --integration).
	mkdir -p "$TARGET/tests/integration"
	: >"$TARGET/tests/integration/.gitkeep"
	render "$st/test.sh.tmpl" "$TARGET/test.sh"
	render "$st/release.sh.tmpl" "$TARGET/release.sh"
	# Shell CI installs bats/zsh — overrides the generic core CI.
	render "$st/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"
	# setup.sh lists shellcheck/bats on top of git/gh — overrides core setup.sh.
	render "$st/setup.sh.tmpl" "$TARGET/setup.sh"
	chmod +x "$TARGET/bin/$NAME" "$TARGET/test.sh" "$TARGET/release.sh" "$TARGET/setup.sh"
	if [[ "$DISTRIBUTION" == "brew" ]]; then
		render "$st/formula.rb.tmpl" "$TARGET/Formula/$NAME.rb"
	fi
}

# Render the frontend-profile files (Vite + vanilla TS, npm, vitest, prettier).
render_frontend_profile() {
	local ft
	ft="$(dirname "$SCRIPT_DIR")/profile-frontend/templates"
	[[ -d "$ft" ]] || die "no profile-frontend templates at: $ft"
	render "$ft/package.json.tmpl" "$TARGET/package.json"
	render "$ft/tsconfig.json.tmpl" "$TARGET/tsconfig.json"
	render "$ft/vite.config.ts.tmpl" "$TARGET/vite.config.ts"
	render "$ft/index.html.tmpl" "$TARGET/index.html"
	render "$ft/prettierignore.tmpl" "$TARGET/.prettierignore"
	render "$ft/main.ts.tmpl" "$TARGET/src/main.ts"
	render "$ft/main.test.ts.tmpl" "$TARGET/src/main.test.ts"
	render "$ft/test.sh.tmpl" "$TARGET/test.sh"
	render "$ft/release.sh.tmpl" "$TARGET/release.sh"
	# Frontend CI installs Node — overrides the generic core CI.
	render "$ft/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"
	# setup.sh lists node on top of git/gh — overrides the generic core setup.sh.
	render "$ft/setup.sh.tmpl" "$TARGET/setup.sh"
	chmod +x "$TARGET/test.sh" "$TARGET/release.sh" "$TARGET/setup.sh"
	# Ignore node artifacts (appended to the core-rendered .gitignore).
	{
		echo ""
		echo "# node / build"
		echo "node_modules/"
		echo "dist/"
	} >>"$TARGET/.gitignore"
}

# --- core skeleton ----------------------------------------------------------
mkdir -p "$TARGET"

render "$TEMPLATES/core/README.md.tmpl" "$TARGET/README.md"
render "$TEMPLATES/core/gitignore.tmpl" "$TARGET/.gitignore"
render "$TEMPLATES/core/CLAUDE.md.tmpl" "$TARGET/CLAUDE.md"
render "$TEMPLATES/core/design-overview.md.tmpl" "$TARGET/design/overview.md"
render "$TEMPLATES/core/pre-push.tmpl" "$TARGET/hooks/pre-push"
render "$TEMPLATES/core/install-hooks.sh.tmpl" "$TARGET/install-hooks.sh"
render "$TEMPLATES/core/setup.sh.tmpl" "$TARGET/setup.sh"
render "$TEMPLATES/core/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"

printf '0.1.0\n' >"$TARGET/VERSION"

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
chmod +x "$TARGET/hooks/pre-push" "$TARGET/install-hooks.sh" "$TARGET/setup.sh"

# --- stack profile ----------------------------------------------------------
case "$PROFILE" in
shell) render_shell_profile ;;
python) render_python_profile ;;
frontend) render_frontend_profile ;;
sql)
	echo "note: profile '$PROFILE' not yet implemented — core skeleton only"
	;;
*) die "unknown profile: $PROFILE" ;;
esac

echo "Scaffolded $NAME ($PROFILE/$ARCHETYPE) into $TARGET"
