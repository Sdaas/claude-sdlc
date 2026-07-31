# Build Plan — Agentic SDLC

End-to-end plan for building this system. Phased so each phase delivers a
working vertical slice. See `PROGRESS.md` for live status and `docs/design/`
for the architecture. We **dogfood**: this repo is built using the very
process it defines (test-first, curated design, script-driven testing).

---

## Phase 0 — Repo foundation & installer  ✅ (in progress → mostly done)

Goal: a versioned, safely-installable skeleton.

- [x] `git init`, `VERSION`, `.gitignore`
- [x] `apply.sh` — copy payload → `~/.claude`, manifest + version stamp,
      `--status/--dry-run/--uninstall/--force/--source/--target`, collision guard,
      stale removal (bash 3.2 compatible)
- [x] `tests/test_apply.sh` — 7 behaviors, 27 assertions, green
- [x] `docs/design/overview.md`, `PLAN.md`, `PROGRESS.md`
- [ ] `test.sh` — the repo's own single test entrypoint (runs all tests)
- [ ] `release.sh` — bump `VERSION`, tag, (later) publish
- [ ] Pre-push hook + GitHub Actions CI for THIS repo (dogfood addition #3)
- [ ] 6-section `README.md` for this repo
- [ ] First commit / push; migrate backlog to GitHub Issues (dogfood addition #1)

**Verify:** `bash test.sh` green; `apply.sh --dry-run` shows a sane plan.

---

## Phase 1 — Core spine + `/newproject` end-to-end

Goal: prove one command works start-to-finish via the gate engine + shell profile.

- [ ] `sdlc-common` skill — tier definitions, governance matrix, artifact
      conventions, branching policy, backlog/issue conventions
- [ ] `sdlc-orchestrator` skill — classify → tier → walk gates; branch policy
      (trivial→main, else own branch); SESSION_STATE for `/resume`
- [ ] Core gate skills: `interview`, `design`, `plan`, `tdd`, `code-review`,
      `review-guide`, `commit`
- [ ] `profile-shell` — test runner (bats/plain bash), shellcheck/shfmt,
      layout, brew packaging hooks, shell review checklist
- [ ] `/newproject` command — interview → scaffold (README 6 sections, `design/`,
      `test.sh`, `release.sh`, pre-push hook, GitHub Actions CI, git init,
      first issue conventions)
- [ ] **Prove:** run `/newproject` to create a real throwaway shell tool repo,
      end-to-end, and confirm the scaffold + first `/feature` works.

**Design-first sub-step (before coding `/newproject`):** nail the interview
questions and the exact scaffold tree per profile; get human approval.

---

## Phase 2 — Python profile + full gate set

- [ ] `profile-python` — pytest, ruff/black, `src/` layout, packaging
      (reuse the old template scaffold only where it earns its place)
- [ ] Remaining gates: `design-review`, `plan-review`, `security-review`,
      `retrospective` (feature + session modes)
- [ ] `/feature` and `/bugfix` commands (issue-linked, reproduce-first for bugs)
- [ ] Subagent-isolated TDD (test-writer can't see impl plan)

---

## Phase 3 — Deploy + lightweight SQL/frontend profiles

- [ ] `deploy` gate — brew formula packaging (asked in interview), release flow
- [ ] `profile-sql` (migrations/seeds/queries) — lightweight
- [ ] `profile-frontend` — lightweight
- [ ] `release.sh` conventions per profile

---

## Phase 4 — Harden, adopt, migrate

- [ ] `/harden` — retrofit SDLC onto an existing non-SDLC repo
- [ ] CI/hooks installer as a reusable gate action
- [ ] Migrate existing global shell skills (`zsh-script`, `add-shell-feature`,
      `fix-shell-bug`, `harden-shell-repo`) into `profile-shell`; retire duplicates
- [ ] Model/token-usage optimization (previously deferred)

---

## Cross-cutting principles (apply to every phase)

- **Backlog = GitHub Issues.** Work items are issues; slug = issue number.
- **Branching.** Trivial → main; everything else → own branch.
- **CI + pre-push.** Tests must be green before push and before merge.
- **Review guide.** Every implementation ends with a changed-file list +
  recommended review order.
- **Test-first.** Red → green → refactor; all testing via `test.sh`.
- **HITL.** Human approves at each gate; agent proposes, never bulldozes.
