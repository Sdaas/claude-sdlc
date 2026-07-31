# Progress Tracker

Live status for building this SDLC, designed to survive across sessions.
**Read this first when resuming.** Pair with `PLAN.md` (the phased plan) and
`docs/design/overview.md` (the architecture).

> Backlog note: once this repo is on GitHub, the backlog moves to **GitHub
> Issues** (per the SDLC's own rule). Until then, this file is the tracker.

---

## ▶ Current status

- **Phase:** 0 (repo foundation & installer) — **complete**
- **Last done:** README (6 sections), `test.sh`, `release.sh`, pre-push hook +
  installer, GitHub Actions CI. Full suite green (27/27, shellcheck clean).
  First commit + push to GitHub, backlog seeded as Issues.
- **NEXT ACTION:** Phase 1 — **design `/newproject`** first (interview questions
  + exact scaffold tree per profile), get human approval, THEN build
  `sdlc-common` + `sdlc-orchestrator` + `profile-shell` + `/newproject`
  test-first.

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

## Conventions for updating this file

- At the **start** of a session: read `## ▶ Current status` and the top session-log entry.
- At the **end** of a session: update `## ▶ Current status`, tick checklist
  boxes, add a session-log entry (date + what changed + next action).
