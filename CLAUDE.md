# CLAUDE.md — claude-sdlc

This is the **source repo for the agentic SDLC itself** — the `/sdlc-*` commands,
skills, templates, scaffolder, and installer that `./apply.sh` deploys into
`~/.claude`. It is both the tool and a user of the tool: work here follows the
process it ships, **self-hosted on this repo only** until it graduates.

## Project marker

- **Name:** claude-sdlc
- **Archetype:** cli + payload library (shell tooling wrapping a markdown payload)
- **Profile (stack):** shell
- **Distribution:** none — delivered by `./apply.sh` into `~/.claude`, not packaged

Use this marker to select the right stack profile without re-asking.

## Structure

| Path | Contents |
|---|---|
| `payload/commands/*.md` | The `/sdlc-*` slash commands — thin gate-walkers. |
| `payload/skills/*/SKILL.md` | The skills defining the vocabulary and rules. |
| `payload/skills/*/templates/` | Scaffold + artifact templates, owned by their skill. |
| `payload/skills/sdlc-common/scaffold.sh` | The `/sdlc-newproject` scaffolder. |
| `apply.sh` | Versioned installer into `~/.claude` (manifest, dry-run, uninstall). |
| `setup.sh` | Developer dependency check/install (`--verify` for readiness). |
| `test.sh` / `release.sh` | The only supported test and release entry points. |
| `tests/` + `hooks/` | Test suites; the pre-push hook (moving to `.githooks/` in #63). |
| `docs/design/` | Curated architecture + per-command design docs. |
| `docs/reviews/` | Received review artifacts, kept for issue provenance. |

## Where to look next

- **`docs/design/overview.md`** — the curated end-to-end design and key decisions.
- **`PLAN.md`** — roadmap narrative and dependency order.
- **`PROGRESS.md`** — the live cursor; read it first when resuming.
- Backlog — GitHub Issues; the issue number is the branch slug.

## Process

The rules for working here (tiers, paths, branching, review-before-commit,
Definition of Done) live in the **`sdlc-common` skill** and are deliberately
**not restated in this file** — one source of truth, one edit site.

> **Known drift:** the scaffolder tells scaffolded repos their design lives in
> `design/`, while this repo uses `docs/design/`. Reconciling the two is tracked
> in **#56**; until then `docs/design/` is correct *here*.
