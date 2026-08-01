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

See [`docs/design/overview.md`](docs/design/overview.md) for the architecture,
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

# Check what's installed:
./apply.sh --status

# Remove everything this installed (leaves your other ~/.claude files):
./apply.sh --uninstall
```

Once installed, the SDLC commands (e.g. `/newproject`, `/feature`) become
available in Claude Code globally.

---

## User Guide

The SDLC exposes a small set of commands (installed into `~/.claude/commands`):

| Command | Purpose |
|---|---|
| `/newproject` | Start a new repo — interview, then scaffold README, `design/`, `test.sh`, `release.sh`, hooks, and CI. |
| `/feature` | Add a feature to an existing SDLC repo. |
| `/bugfix` | Fix a bug (a failing test reproduces it first). |
| `/harden` | Retrofit the SDLC onto an existing repo. |
| `/retrospective` | Feature retro, or a session retro to improve the SDLC. |
| `/resume` | Continue in-flight work. |
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
docs/design/          Curated design of the SDLC itself
templates/            Per-repo artifact templates (scaffolded by /newproject)
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
