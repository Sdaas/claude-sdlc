# Progress Tracker

The live **cursor** for building this SDLC across sessions. **Read this first
when resuming.** The backlog itself lives in **GitHub Issues** (see the
[board](https://github.com/Sdaas/claude-sdlc/issues) and milestones); `PLAN.md`
holds the roadmap + dependency order; `docs/design/` holds the architecture.

---

## ▶ Current status

- **Phase:** 2 (`/feature` + first self-hosted feature) — starting
- **Applied:** SDLC v0.1.0 is installed in `~/.claude` (`/newproject` live).
- **Self-hosting:** build the SDLC *with itself*, **this repo only**, until it
  graduates (criteria in memory `sdlc-self-hosting`). `/feature` stays hand-built.
- **NEXT ACTION:** build **#2 `sdlc-common/SKILL.md`** (tiers, paths, governance,
  conventions) → then **#12 `/feature` command** → then **#13 python profile**
  (the first feature built *by* `/feature`).
- **Process reminder:** never commit/push before human review + approval (rule #10).

## How to pick the next work

Earliest open milestone → issue whose `Depends on` are all closed → in PLAN.md's
listed order. Update this file's NEXT ACTION to the active issue #.

---

## Session log

Newest first. One short entry per working session.

### 2026-07-31 — Session 1 (cont. 3)
- Applied SDLC to real `~/.claude` (v0.1.0); smoke-tested the installed scaffolder.
- Locked **self-hosting strategy** + graduation criteria; designed `/feature`
  (two paths: code TDD + prose; embedded gates for v1, extraction tracked in #11).
- **Migrated backlog to GitHub Issues** + milestones (Phase 2/3/4) + labels +
  `Depends on` lines. PLAN → roadmap narrative; PROGRESS → cursor.
- Next: #2 → #12 → #13.

### 2026-07-31 — Session 1 (cont. 2)
- Shell profile (PR #9) + `/newproject` command (PR #10) merged. Live dry run
  proved `/newproject` end-to-end. Closed #1/#5/#6. 64 assertions green.

### 2026-07-31 — Session 1 (cont.)
- Designed + built the core scaffolder test-first. Committed PR #7 before review
  by mistake → codified **rule #10 "review before commit"**. PR #7 merged.

### 2026-07-31 — Session 1
- Aligned on architecture (unified/global/tiered/multi-stack, 3 layers). Built
  `apply.sh` test-first (27/27). Locked the 4 principles. Decided to dogfood.

---

## Conventions for updating this file

- **Start** of a session: read `▶ Current status` + the top session-log entry.
- **End** of a session: update status + NEXT ACTION, add a session-log entry.
- Do **not** duplicate the issue list here — the board is the backlog.
