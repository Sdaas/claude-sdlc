# Progress Tracker

The live **cursor** for building this SDLC across sessions. **Read this first
when resuming.** The backlog itself lives in **GitHub Issues** (see the
[board](https://github.com/Sdaas/claude-sdlc/issues) and milestones); `PLAN.md`
holds the roadmap + dependency order; `docs/design/` holds the architecture.

---

## ▶ Current status

- **Phase:** 2 done (#8 setup docs shipped); **Phase 3 underway** (#17 frontend profile shipped).
- **Upstream phase added.** #32 shipped `/discovery` + `/architecture` (new
  `sdlc-discovery` skill + templates + two command gate-walkers) — the phase that
  turns a fuzzy concept into gated, versioned artifacts (concept → use cases →
  arch + ADRs → traced/sequenced feature backlog) feeding `/feature`. Merged
  (PR #33). **v1 to be proven by the first real `/discovery` run** (retro → v2).
- **Self-hosting is LIVE.** Applied to `~/.claude`; `/feature` + `/newproject` are
  live commands. **#13 python + #17 frontend profiles were built *by* `/feature`**
  end-to-end (graduation criterion #4 met twice). Closed #2, #12, #13, #17.
- **Meta/help commands added.** #34 `/sdlc-help` (explain the SDLC + answer
  how-to questions; advisory/read-only) and #35 `/sdlc-feedback` (message →
  well-formed GitHub issue; graceful degradation for non-author reporters) both
  built by `/feature` and merged (PRs #36, #38). Closed #27 as a dup of #34.
  Filed #37 (add a `gh auth status` check to `setup.sh`), surfaced while building #35.
- **Phase 2 remaining:** none.
- **NEXT ACTION:** proof-run `/discovery` on a real concept (retro cuts #32 v2);
  then remaining Phase 3: #14 /bugfix, #15 deploy(brew), #16 profile-sql,
  #18 /retrospective, #19 /resume. Also open: #37 (setup.sh gh-auth check).
- **Graduation:** need ~3–4 clean `/feature` runs + no process gaps in retros
  before using the SDLC on OTHER repos (see memory `sdlc-self-hosting`).
- **Process reminder:** never commit/push before human review + approval (rule #10).

## How to pick the next work

Earliest open milestone → issue whose `Depends on` are all closed → in PLAN.md's
listed order. Update this file's NEXT ACTION to the active issue #.

---

## Session log

Newest first. One short entry per working session.

### 2026-08-01 — Session 1 (cont. 8)
- **Built #34 `/sdlc-help` and #35 `/sdlc-feedback`** via `/feature` (prose path).
  `/sdlc-help`: advisory/read-only guide — no-arg overview + question→command
  mapping; reads installed commands/skills live so help never drifts.
  `/sdlc-feedback`: message → confirmed GitHub issue; prompts when thin; live
  `gh label list`; graceful-degradation ladder for non-author reporters (auth
  preflight + label/create permission fallbacks that never lose feedback).
  Both wired into README + overview tables. Merged (PRs #36, #38). Closed #27
  (dup of #34). Filed #37 (setup.sh should verify `gh auth status`, not just
  that `gh` is installed) — surfaced mid-#35.
- Next: proof-run `/discovery`; #37; remaining Phase 3.

### 2026-08-01 — Session 1 (cont. 7)
- **Built #32: `/discovery` + `/architecture` upstream phase** (hand-built, prose
  path). New `sdlc-discovery` skill (gate defs, human-prose-vs-AI-distillation
  provenance rule, traceability rule, both gate sequences) + 4 templates (concept,
  use-cases, ADR decision, feature backlog) + two thin command gate-walkers +
  `docs/design/discovery-architecture.md` + overview updates. Motivated by a real
  256-page ChatGPT product-build thread whose failure mode was big-picture-in-
  scrollback + reactive architecture + vibes validation. Tests green (145);
  apply.sh dry-run registers all 7 files. Merged (PR #33).
- Next: proof-run `/discovery` on a real concept, then retro → v2.

### 2026-08-01 — Session 1 (cont. 6)
- **Used /feature to build #8** (README Setup docs + `setup.sh` dep checker/installer).
  macOS/Homebrew, check + consent (`--yes` for CI), non-mac/no-brew → manual +
  non-zero. Propagated into the `/newproject` scaffold: core base + per-profile
  `setup.sh.tmpl` (shell +shellcheck/bats, python +uv, frontend +node), same
  override pattern as `test.sh`/`ci.yml`. Test-first; suites now 27+100+18 = 145
  assertions. Review caught a false-positive `--help` test (sed-in-error-text) → hardened.
- Phase 2 complete. Third clean self-hosted `/feature` run.

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
