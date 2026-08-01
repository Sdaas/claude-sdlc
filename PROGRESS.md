# Progress Tracker

The live **cursor** for building this SDLC across sessions. **Read this first
when resuming.** The backlog itself lives in **GitHub Issues** (see the
[board](https://github.com/Sdaas/claude-sdlc/issues) and milestones); `PLAN.md`
holds the roadmap + dependency order; `docs/design/` holds the architecture.

---

## ▶ Current status

- **Phase:** 2 nearly done; **Phase 3 underway** (#17 frontend profile shipped).
- **Self-hosting is LIVE.** Applied to `~/.claude`; `/feature` + `/newproject` are
  live commands. **#13 python + #17 frontend profiles were built *by* `/feature`**
  end-to-end (graduation criterion #4 met twice). Closed #2, #12, #13, #17.
- **Phase 2 remaining:** #8 (README Setup + deps script — the only Phase-2 item
  with no dependency).
- **NEXT ACTION:** #8, then remaining Phase 3 (all blocked on #12, now closed):
  #14 /bugfix, #15 deploy(brew), #16 profile-sql, #18 /retrospective, #19 /resume.
- **Graduation:** need ~3–4 clean `/feature` runs + no process gaps in retros
  before using the SDLC on OTHER repos (see memory `sdlc-self-hosting`).
- **Process reminder:** never commit/push before human review + approval (rule #10).

## How to pick the next work

Earliest open milestone → issue whose `Depends on` are all closed → in PLAN.md's
listed order. Update this file's NEXT ACTION to the active issue #.

---

## Session log

Newest first. One short entry per working session.

### 2026-08-01 — Session 1 (cont. 5)
- **Used /feature to build #17 frontend profile** end-to-end (Vite + vanilla TS,
  npm, vitest, tsc + prettier; framework-neutral, no React). Live verify caught a
  real bug (prettier sweeping the core docs) → fixed with a `.prettierignore`.
  Merged (PR #28). Suite 83 assertions. Second clean self-hosted `/feature` run.
- Note: `gh pr merge`/PR-create are gated by the harness classifier — human ran
  the merge; the PR body needed `--body-file` to pass.
- Next: #8, then remaining Phase 3.

### 2026-07-31 — Session 1 (cont. 4)
- Built #2 sdlc-common SKILL.md + #12 /feature command (hand-built), merged (PR #23).
- Applied to `~/.claude` → **/feature is live**. Then **used /feature to build
  #13 python profile** end-to-end (interview → design → TDD → verify), merged
  (PR #26). Suite 82 assertions. First self-hosted feature — no manual rescue.
- Retro note: Standard-tier Gate 3 (design) was near-empty when the interview
  fully determined the design — candidate process tweak.
- Next: #8, then Phase 3.

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
