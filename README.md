# claude-sdlc

An **agentic SDLC with a human in the loop**, delivered as global Claude Code
skills and commands. This repo is the source of truth; `apply.sh` installs it
into `~/.claude` so the process is available in every project.

---

## Purpose

When you ask Claude to build or fix software, it should behave like a
disciplined engineer: interview you for requirements, propose a design, iterate
through review gates, write code test-first, review it, and help ship it —
pausing for your approval at each gate. This repo packages that process for
**personal and small/medium-business** software: high quality, but simple.

It supports multiple stacks (shell, Python, SQL, front-end) via pluggable
**profiles**, and scales effort to the task via a **tier dial** (Quick /
Standard / Full).

See [`design/overview.md`](design/overview.md) for the architecture,
[`PLAN.md`](PLAN.md) for the build plan, and [`PROGRESS.md`](PROGRESS.md) for
live status.

---

## Quick Start

```bash
git clone https://github.com/Sdaas/claude-sdlc.git
cd claude-sdlc

# Preview what would be installed into ~/.claude (writes nothing):
./apply.sh --dry-run --verbose

# Install / update:
./apply.sh

# Check what's installed, and whether anything has been edited since:
./apply.sh --status

# Remove everything this installed (leaves your other ~/.claude files):
./apply.sh --uninstall
```

Once installed, the SDLC commands (e.g. `/sdlc-newproject`, `/sdlc-feature`)
become available in Claude Code globally. Every SDLC-owned command is prefixed
`sdlc-` so it never collides with Claude Code's built-in or third-party
commands/skills.

### Your local edits are safe

`apply.sh` records a SHA-256 of every file it installs, so it can tell an
untouched file from one you edited in place. If you tweak an installed command
or skill under `~/.claude`, the next `./apply.sh` **stops** rather than
overwriting it:

```
apply.sh: refusing to overwrite locally modified files:
  - skills/sdlc-common/SKILL.md
These differ from what apply.sh installed. Copy your changes into the
source repo first, or re-run with --force to discard them.
```

Copy the change back into `payload/` (where it gets version-controlled), or
re-run with `--force` to discard it. `--status` reports the same information
without changing anything:

```
Integrity: 54 tracked — 52 ok, 1 modified, 1 missing
  modified: skills/sdlc-common/SKILL.md
  missing:  commands/sdlc-help.md
```

`--uninstall` follows the same rule: locally modified files are preserved and
listed, unless you pass `--force`.

---

## User Guide

The SDLC exposes a small set of commands (installed into `~/.claude/commands`):

| Command | Purpose |
|---|---|
| `/sdlc-newproject` | Start a new repo — interview, then scaffold README, `design/`, `test.sh`, `release.sh`, hooks, and CI. |
| `/sdlc-feature` | Add a feature to an existing SDLC repo. |
| `/sdlc-bugfix` | Fix a bug (a failing test reproduces it first). |
| `/sdlc-harden` | Retrofit the SDLC onto an existing repo. |
| `/sdlc-retrospective` | Feature retro, or a session retro to improve the SDLC. |
| `/sdlc-resume` | Continue in-flight work across sessions (reads `SESSION_STATE.md`; reconciles with git/issues). |
| `/sdlc-help` | Explain how the SDLC works, or answer a specific how-to question. |
| `/sdlc-feedback` | Turn a message into a well-formed GitHub issue (prompts for detail if thin). |

Work is tracked as **GitHub Issues** (the backlog). Trivial changes go straight
to `main`; everything else gets its own branch. Every implementation ends with a
**review guide** — the changed files and the order to review them in.

> Status: commands are under construction. See `PROGRESS.md`.

---

## Developer Guide

Layout:

```
apply.sh              Installer (copy payload → ~/.claude, versioned)
VERSION               Current version (semver)
payload/              What gets installed
  commands/           Slash commands
  skills/             Gate skills + stack profiles
tests/                Tests for this repo's own tooling
design/               Curated design of the SDLC itself (dogfoods the root-design/ rule)
PLAN.md, PROGRESS.md  Build plan and cross-session tracker
```

This repo **dogfoods** its own process: changes are made test-first, the design
lives in `design/`, and all testing/release runs through shell scripts.

### Setup

Developer dependencies:

| Tool | Why |
|---|---|
| `git` | version control |
| `gh` (GitHub CLI) | the issue backlog + PRs |
| `shellcheck` | lints every shell script in `./test.sh` |
| `bash`, `zsh` | run/target shells (present on macOS by default) |

`setup.sh` checks these and offers to install the missing ones (macOS/Homebrew):

```bash
./setup.sh          # check deps; prompt before installing anything
./setup.sh --yes    # install missing deps without prompting (CI-friendly)
./setup.sh --verify # also run per-dep readiness checks (auth, versions)
```

The plain run only checks that each tool is **installed**. `--verify` additionally
runs **readiness checks** for the deps that declare one — today `gh` must be
authenticated (`gh auth status`); a failed check prints the fix (`gh auth login`)
and exits non-zero. Checks live in the `CHECKS` table near the top of `setup.sh`:

```bash
# command | auth    | <probe command>            | <fix hint>
# command | version | <min-version> | <version-probe command> [| <fix hint>]
"gh|auth|gh auth status|run: gh auth login"
# add a version floor when a tool needs one, e.g.:
# "git|version|2.30.0|git --version|brew upgrade git"
```

On non-macOS systems it reports what to install by hand. Then install the local
git hooks:

```bash
./install-hooks.sh
```

---

## Automated Testing Guide

All tests run through a single entrypoint:

```bash
./test.sh
```

`test.sh` runs `shellcheck` (if installed) and the behavior tests under
`tests/`. It is what the **pre-push hook** and **GitHub Actions CI** both call —
so if `./test.sh` is green locally, push and CI will be too.

- Tests are plain `bash` (no `bats` dependency) and self-contained.
- Installer tests run against throwaway `--source`/`--target` dirs, so they
  never touch your real `~/.claude`.

---

## Release Process

Releases are automated through `release.sh`:

```bash
./release.sh patch      # bump 0.1.0 -> 0.1.1, tag, push tag
./release.sh minor      # bump 0.1.0 -> 0.2.0
./release.sh major      # bump 0.1.0 -> 1.0.0
./release.sh --version 0.4.2   # set an explicit version
```

The release script refuses to run on a dirty tree or a failing test suite,
bumps `VERSION`, commits it, creates an annotated `v<version>` tag, and pushes.
Consumers pick up the new version by re-running `./apply.sh`, which records the
installed version and git sha in `~/.claude/.sdlc/version`.
