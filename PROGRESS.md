# Progress Tracker

The live **cursor** for building this SDLC across sessions. **Read this first
when resuming.** The backlog itself lives in **GitHub Issues** (see the
[board](https://github.com/Sdaas/claude-sdlc/issues) and milestones); `PLAN.md`
holds the roadmap + dependency order; `docs/design/` holds the architecture.

---

## ▶ Current status

- **Phase:** 2 done (#8 setup docs shipped); **Phase 3 underway** (#17 frontend profile shipped).
- **Upstream phase added.** #32 shipped `/sdlc-discovery` + `/sdlc-architecture` (new
  `sdlc-discovery` skill + templates + two command gate-walkers) — the phase that
  turns a fuzzy concept into gated, versioned artifacts (concept → use cases →
  arch + ADRs → traced/sequenced feature backlog) feeding `/sdlc-feature`. Merged
  (PR #33). **v1 to be proven by the first real `/sdlc-discovery` run** (retro → v2).
- **Self-hosting is LIVE.** Applied to `~/.claude`; `/sdlc-feature` + `/sdlc-newproject` are
  live commands. **#13 python + #17 frontend profiles were built *by* `/sdlc-feature`**
  end-to-end (graduation criterion #4 met twice). Closed #2, #12, #13, #17.
- **Meta/help commands added.** #34 `/sdlc-help` (explain the SDLC + answer
  how-to questions; advisory/read-only) and #35 `/sdlc-feedback` (message →
  well-formed GitHub issue; graceful degradation for non-author reporters) both
  built by `/sdlc-feature` and merged (PRs #36, #38). Closed #27 as a dup of #34.
  Filed #37 (add a `gh auth status` check to `setup.sh`), surfaced while building #35.
- **#37, #14, #19 built.** #37 → `setup.sh --verify` readiness checks (opt-in
  `auth` probe + `version` floor, declarative `CHECKS`, mirrored into the
  scaffold) — merged (PR #39). #14 `/sdlc-bugfix` (reproduce-first; `fix/<slug>`;
  Full-tier ladder + design-flaw→`/sdlc-architecture` escalation) — merged (PR #40).
  #19 `/sdlc-resume` built by `/sdlc-feature` (prose): cross-session continuity =
  transient gitignored `SESSION_STATE.md` checkpoint (every gate-walker writes it
  per `sdlc-common` §5, cleared at close-out) + a read-only resume command that
  reconciles it with git/issues/`PROGRESS.md`. Renamed from `/resume` (built-in
  collision). `/sdlc-pause` deferred as a candidate follow-up.
- **Phase 2 remaining:** none.
- **#42 shipped.** VERIFY gate + Definition of Done + mock-obligation rule added
  to `/sdlc-feature`, `/sdlc-bugfix`, and `sdlc-common` (retro-born from medical-ocr#7:
  hermetic green ≠ Done when a boundary is mocked). Full tier, prose. Merged
  (PR #44); applied to `~/.claude` (git_sha 8c0b2d9). Gates renumbered 5→10.
- **#24 shipped (logging policy).** `docs/design/logging-policy.md` +
  leveled logging baked into all 3 entry templates (shell/python/frontend):
  INFO default, DEBUG via `--verbose`, ERROR always; logs→stderr, data→stdout;
  ISO-8601 UTC `<ts> <LEVEL> <name>: <msg>`; full trace on error (shell
  best-effort/cross-shell). Standard tier, mixed path; VERIFY observed on real
  scaffolds. PR TBD.
- **#25 built (`/sdlc-harden`).** Phase 4 gap-analysis command: audit an existing
  repo vs SDLC standards → categorized report (4 areas × 3 risk classes) →
  human prioritizes (close/defer/drop) → hybrid close (infra/doc/behavior-preserving
  in-harden under a green safety net; behavior/logic escalates to `/sdlc-feature` /
  `/sdlc-bugfix`). Audit default / apply opt-in; mode ≠ tier; cardinal rule =
  never refactor untested code; report-first backlog; stack checklist delegated to
  profile (shell → `harden-shell-repo`, migration deferred to #21). New `sdlc-harden`
  skill + thin command + gap-report template; design decision #11. #20 closed as
  dup of #25 (now in Phase 4). Full tier, prose. PR TBD.
- **NEXT ACTION:** proof-run `/sdlc-discovery` on a real concept (retro cuts #32 v2);
  then remaining Phase 3: #15 deploy(brew), #16 profile-sql, #18 /sdlc-retrospective.
- **Graduation:** need ~3–4 clean `/sdlc-feature` runs + no process gaps in retros
  before using the SDLC on OTHER repos (see memory `sdlc-self-hosting`).
- **Process reminder:** never commit/push before human review + approval (rule #10).

## How to pick the next work

Earliest open milestone → issue whose `Depends on` are all closed → in PLAN.md's
listed order. Update this file's NEXT ACTION to the active issue #.

---

## Session log

Newest first. One short entry per working session.

### 2026-08-02 — Session 1 (cont. 10)
- **Shipped #42** via `/sdlc-feature` (prose, **Full tier**): a **VERIFY gate** ("observe
  the real thing") in `/sdlc-feature` + `/sdlc-bugfix` after IMPLEMENT/before CODE REVIEW —
  drive the real flow, exercise every external boundary un-mocked; required at
  external/user-facing boundaries, skippable only with a stated reason. Plus a
  **mock-obligation rule** (§3) and an explicit **Definition of Done** (§5, green
  tests AND observed behavior) in `sdlc-common`, and a boundary inventory in the
  interview/design gates. Retro-born from medical-ocr#7 (mocked boundary hid a
  missing `Pillow` dep + a `num_ctx` truncation, both fully-green). Gates
  renumbered 5→10; review-scan caught + fixed cross-ref drift in `bugfix.md` and
  `sdlc-resume.md`. Merged (PR #44); applied to `~/.claude`.
- **Ops note:** in `auto` mode the permission classifier gates `git push` and
  blocks the agent from self-editing `settings.json` (even with `Bash(*)` allowed);
  resolved by adding an explicit `Bash(git push:*)` allow rule via `/permissions`.
- Next: proof-run `/sdlc-discovery`; remaining Phase 3 (#15, #16, #18).

### 2026-08-02 — Session 1 (cont. 9)
- **Shipped #37** via `/sdlc-feature` (code path): `setup.sh --verify` — opt-in
  per-dependency readiness checks (`auth` probe + `version` floor) via a
  declarative `CHECKS` table (overridable with `_SETUP_CHECKS` for tests),
  mirrored into the scaffold template; 6 new tests; docs in both READMEs +
  overview. Merged (PR #39).
- **Built #14 `/sdlc-bugfix`** via `/sdlc-feature` (prose path): reproduce-first command
  (`fix/<slug>`; failing test reproduces the bug → red → root-cause fix → green →
  regression test stays). Code + prose paths; Full-tier ladder
  (security/design/shipped/high-risk); design-flaw → `/sdlc-architecture` escalation;
  security bug → exploit-first + security-review. Command + `docs/design/sdlc-bugfix.md`.
  Merged (PR #40).
- **Built #19 `/sdlc-resume`** via `/sdlc-feature` (prose path): (A) a read-only
  resume command + (B) a `SESSION_STATE.md` checkpoint contract in `sdlc-common`
  §5 that all 5 gate-walkers write (gitignored; cleared at close-out). Reconciles
  state with git/issues/`PROGRESS.md`; hands off to the owning command. Renamed
  from `/resume` (Claude Code built-in collision); removed the superseded
  untracked `docs/resume-prompt.md`; `.gitignore` + scaffold template updated.
  `/sdlc-pause` (explicit mid-gate flush) deferred.
- Next: proof-run `/sdlc-discovery`; remaining Phase 3 (#15, #16, #18).

### 2026-08-01 — Session 1 (cont. 8)
- **Built #34 `/sdlc-help` and #35 `/sdlc-feedback`** via `/sdlc-feature` (prose path).
  `/sdlc-help`: advisory/read-only guide — no-arg overview + question→command
  mapping; reads installed commands/skills live so help never drifts.
  `/sdlc-feedback`: message → confirmed GitHub issue; prompts when thin; live
  `gh label list`; graceful-degradation ladder for non-author reporters (auth
  preflight + label/create permission fallbacks that never lose feedback).
  Both wired into README + overview tables. Merged (PRs #36, #38). Closed #27
  (dup of #34). Filed #37 (setup.sh should verify `gh auth status`, not just
  that `gh` is installed) — surfaced mid-#35.
- Next: proof-run `/sdlc-discovery`; #37; remaining Phase 3.

### 2026-08-01 — Session 1 (cont. 7)
- **Built #32: `/sdlc-discovery` + `/sdlc-architecture` upstream phase** (hand-built, prose
  path). New `sdlc-discovery` skill (gate defs, human-prose-vs-AI-distillation
  provenance rule, traceability rule, both gate sequences) + 4 templates (concept,
  use-cases, ADR decision, feature backlog) + two thin command gate-walkers +
  `docs/design/sdlc-discovery-architecture.md` + overview updates. Motivated by a real
  256-page ChatGPT product-build thread whose failure mode was big-picture-in-
  scrollback + reactive architecture + vibes validation. Tests green (145);
  apply.sh dry-run registers all 7 files. Merged (PR #33).
- Next: proof-run `/sdlc-discovery` on a real concept, then retro → v2.

### 2026-08-01 — Session 1 (cont. 6)
- **Used /sdlc-feature to build #8** (README Setup docs + `setup.sh` dep checker/installer).
  macOS/Homebrew, check + consent (`--yes` for CI), non-mac/no-brew → manual +
  non-zero. Propagated into the `/sdlc-newproject` scaffold: core base + per-profile
  `setup.sh.tmpl` (shell +shellcheck/bats, python +uv, frontend +node), same
  override pattern as `test.sh`/`ci.yml`. Test-first; suites now 27+100+18 = 145
  assertions. Review caught a false-positive `--help` test (sed-in-error-text) → hardened.
- Phase 2 complete. Third clean self-hosted `/sdlc-feature` run.

### 2026-08-01 — Session 1 (cont. 5)
- **Used /sdlc-feature to build #17 frontend profile** end-to-end (Vite + vanilla TS,
  npm, vitest, tsc + prettier; framework-neutral, no React). Live verify caught a
  real bug (prettier sweeping the core docs) → fixed with a `.prettierignore`.
  Merged (PR #28). Suite 83 assertions. Second clean self-hosted `/sdlc-feature` run.
- Note: `gh pr merge`/PR-create are gated by the harness classifier — human ran
  the merge; the PR body needed `--body-file` to pass.
- Next: #8, then remaining Phase 3.

### 2026-07-31 — Session 1 (cont. 4)
- Built #2 sdlc-common SKILL.md + #12 /sdlc-feature command (hand-built), merged (PR #23).
- Applied to `~/.claude` → **/sdlc-feature is live**. Then **used /sdlc-feature to build
  #13 python profile** end-to-end (interview → design → TDD → verify), merged
  (PR #26). Suite 82 assertions. First self-hosted feature — no manual rescue.
- Retro note: Standard-tier Gate 3 (design) was near-empty when the interview
  fully determined the design — candidate process tweak.
- Next: #8, then Phase 3.

### 2026-07-31 — Session 1 (cont. 3)
- Applied SDLC to real `~/.claude` (v0.1.0); smoke-tested the installed scaffolder.
- Locked **self-hosting strategy** + graduation criteria; designed `/sdlc-feature`
  (two paths: code TDD + prose; embedded gates for v1, extraction tracked in #11).
- **Migrated backlog to GitHub Issues** + milestones (Phase 2/3/4) + labels +
  `Depends on` lines. PLAN → roadmap narrative; PROGRESS → cursor.
- Next: #2 → #12 → #13.

### 2026-07-31 — Session 1 (cont. 2)
- Shell profile (PR #9) + `/sdlc-newproject` command (PR #10) merged. Live dry run
  proved `/sdlc-newproject` end-to-end. Closed #1/#5/#6. 64 assertions green.

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
