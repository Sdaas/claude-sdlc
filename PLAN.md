# Roadmap

The **backlog lives in GitHub Issues** (per the SDLC's own rule). This file is
the *narrative* — the phase rationale and the dependency-ordered sequence (the
readable DAG). It is **not** a task checklist.

## How work is tracked

| Where | Role |
|---|---|
| **GitHub Issues** | The backlog — every unit of work. Source of truth for what's queued/active/done. Slug = issue number. |
| **Milestones** | Phase grouping + order: **Phase 2 → 3 → 4**. |
| **`Depends on: #N`** (issue body) | Authoritative per-issue gate — an issue is *ready* only when its deps are closed. |
| **PLAN.md** (this file) | The readable DAG + rationale. |
| **PROGRESS.md** | The live cursor — current status, active issue, next action, session log. |

**Selection rule (what's next):** the earliest open milestone's issue whose
`Depends on` are all closed, in the order listed below.

## Phase 0 — Foundation & installer ✅ done

`apply.sh` (versioned installer) + tests, `test.sh`/`release.sh`, pre-push + CI,
README, design docs. Repo pushed; CI green.

## Phase 1 — `/newproject` slice ✅ done

Core scaffolder (`scaffold.sh` + templates) + shell profile (bats, cross-shell,
brew) + `/newproject` command. Proven end-to-end; applied to `~/.claude` (v0.1.0).
Closed #1, #5, #6.

## Phase 2 — `/feature` + first self-hosted feature ([milestone](https://github.com/Sdaas/claude-sdlc/milestones))

Rationale: build the tool that lets the SDLC build itself, then prove it by using
it. Self-hosted on **this repo only** until it graduates (see the self-hosting
strategy in memory / design docs).

Sequence:
```
#2  sdlc-common SKILL.md  (tiers, paths, governance, conventions)
      → #12 /feature command (embedded gates; code + prose paths)
            → #13 python profile   ← FIRST feature built *by* /feature (shakedown)
#8  README Setup + deps script      (parallel — no hard dependency)
```

## Phase 3 — more commands, profiles, deploy

All depend on **#12** (`/feature`). Parallelizable once it exists:
```
#14 /bugfix   #15 deploy(brew)   #16 profile-sql   #17 profile-frontend
#18 /retrospective   #19 /resume
```

## Phase 4 — refactor, adopt, migrate

```
#20 /harden               (depends on #12)
#11 extract orchestrator  (depends on #14, #20 — only once multiple callers exist)
#4  extract gate skills   (tech-debt; after the embedded version proves out)
#21 migrate global shell skills into profile-shell
#22 model/token optimization
```

## Cross-cutting principles

Backlog = Issues · trivial→main / else branch · tests green before push & merge ·
review guide + **review-before-commit (rule #10)** · test-first · HITL at every gate.
