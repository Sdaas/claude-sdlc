# Progress Tracker

Live status for building this SDLC, designed to survive across sessions.
**Read this first when resuming.** Pair with `PLAN.md` (the phased plan) and
`docs/design/overview.md` (the architecture).

> Backlog note: once this repo is on GitHub, the backlog moves to **GitHub
> Issues** (per the SDLC's own rule). Until then, this file is the tracker.

---

## ▶ Current status

- **Phase:** 1 (core spine + `/newproject`) — **`/newproject` slice complete**
- **Last done:** shell profile (PR #9) + `/newproject` command (PR #10) merged.
  **Live dry run proved Issue #6** end-to-end (15-file repo, git init + hooks +
  first commit, new repo's `test.sh` green, bats 5/5 cross-shell). Closed
  Issues #1, #5, #6. This repo's suite green (64 assertions), CI green.
- **NOT YET APPLIED:** `apply.sh` has not been run against the real `~/.claude`
  — the SDLC works from the repo but is not globally installed yet.
- **NEXT ACTION (pick one):**
  (a) run `apply.sh` to install globally and use `/newproject` for real; or
  (b) Phase 2 — the `/feature` workflow for existing repos: `sdlc-common`
  (tiers/governance, #2), `sdlc-orchestrator` (#3), core gate skills (#4),
  subagent-isolated TDD.
- **PROCESS REMINDER:** never commit/push before human review + approval (rule #10).

---

## Checklist (mirrors PLAN.md)

### Phase 0 — Foundation & installer
- [x] git init, VERSION, .gitignore
- [x] apply.sh (install/update/status/dry-run/uninstall/force, collision guard, stale removal)
- [x] tests/test_apply.sh (27 assertions green)
- [x] docs/design/overview.md, PLAN.md, PROGRESS.md
- [x] test.sh (repo test entrypoint)
- [x] release.sh (bump VERSION, tag)
- [x] pre-push hook + GitHub Actions CI (dogfood)
- [x] README.md (6 sections)
- [x] first commit + push + backlog → GitHub Issues

### Phase 1 — Core spine + /newproject
- [ ] sdlc-common
- [ ] sdlc-orchestrator
- [ ] gates: interview, design, plan, tdd, code-review, review-guide, commit
- [ ] profile-shell
- [ ] /newproject command
- [ ] proven end-to-end on a throwaway shell repo

### Phase 2 — Python + full gates
- [ ] profile-python
- [ ] gates: design-review, plan-review, security-review, retrospective
- [ ] /feature, /bugfix
- [ ] subagent-isolated TDD

### Phase 3 — Deploy + sql/frontend
- [ ] deploy gate (brew)
- [ ] profile-sql (light), profile-frontend (light)

### Phase 4 — Harden + migrate
- [ ] /harden
- [ ] CI/hooks installer gate
- [ ] migrate global shell skills into profile-shell
- [ ] model/token optimization

---

## Session log

Newest first. One short entry per working session.

### 2026-07-31 — Session 1
- Aligned on architecture: unified, global, tiered, multi-stack (3 layers).
- Locked delivery model: copy + version stamp via `apply.sh` (flat command
  names, no backups).
- Built `apply.sh` test-first → 27/27 green, shellcheck clean.
- Added 4 principles: GitHub Issues backlog; trivial→main / else branch;
  CI + pre-push; post-implementation review guide (change map).
- Wrote design overview, PLAN, PROGRESS. Decided to dogfood this repo.
- **Open:** finish Phase 0 tail; then design `/newproject` before coding it.

---

### 2026-07-31 — Session 1 (cont.)
- Designed `/newproject`; decisions: bats + cross-shell tests, CLAUDE.md stack
  marker, ask/default-private repo, interview = core 6 + constraints + design/UX.
- Built the core scaffolder test-first (`scaffold.sh` + core templates); 25
  assertions green.
- **Correction:** committed PR #7 before human review — inverted the gate order.
  Codified **rule #10 "review before commit"** into overview.md + saved as
  feedback memory. Human approved design edits + PR #7; PR #7 merged.
- **Next:** shell profile templates, then `/newproject` command wiring.

### 2026-07-31 — Session 1 (cont. 2)
- Built shell profile (PR #9) + `/newproject` command (PR #10), both test-first
  / reviewed before commit (rule #10 honored).
- Live `/newproject` dry run proved end-to-end (Issue #6). Closed #1, #5, #6.
- Suite now 64 assertions (27 apply + 37 scaffold). CI green on main.
- `/newproject` slice done but SDLC not yet applied to real `~/.claude`.
- **Next:** either apply globally, or start Phase 2 (`/feature` workflow:
  sdlc-common #2, orchestrator #3, gates #4).

## Conventions for updating this file

- At the **start** of a session: read `## ▶ Current status` and the top session-log entry.
- At the **end** of a session: update `## ▶ Current status`, tick checklist
  boxes, add a session-log entry (date + what changed + next action).
