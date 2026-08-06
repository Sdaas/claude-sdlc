# Feature Backlog — Profile Skills

> Produced by `/sdlc-architecture` — its terminal artifact. Each row is a
> **feature** sized for one (possibly Full-tier) `/sdlc-feature` run, **traced**
> to the use cases it satisfies and **sequenced** by dependency + deferral. This
> is what becomes GitHub Issues (`Depends on: #N`) and what `/sdlc-feature` builds
> one at a time.

## Components (from architecture/overview.md)

- **`profile-common`** — backbone: the `SKILL.md` skeleton + cross-profile testing (CAP-10, CAP-8).
- **`profile-{shell,python,sql,frontend}`** — per-stack renderings of the 6 dimensions.
- **Command integration** — profiles applied at gates by the SDLC commands (CAP-9).
- **`templates/`** — existing scaffolding, referenced (ADR-0004).

## Backlog

Ordered by build sequence. Priority = intrinsic importance to the initiative;
build order is encoded by `Depends on` (see rationale — priority ≠ order).

| # | Feature | Serves (UC) | Component | Priority | Depends on |
|---|---|---|---|---|---|
| **F1** | Build **`profile-common`**: the fixed 6-dimension `SKILL.md` skeleton (ADR-0001, amended #89) + the cross-profile testing section shell (ADR-0002) + pointers to `sdlc-security` & `logging-policy.md` | UC-008, UC-007 | profile-common | **P0** | — |
| **F2** | Build **`profile-python`** as the **pilot** (CAP-11) — all 6 dimensions to the skeleton; perf per ADR-0003; scaffolding references `templates/` per ADR-0004; Security dimension = **#85** | UC-001,002,004,005,009,010 | profile-python | **P0** | F1 |
| **F3** | Build **`profile-shell`** to the proven pattern; scaffolding (ADR-0004); Security = **#84** | UC-001,002,004,005,009,010 | profile-shell | **P0** | F2 |
| **F4** | Build **`profile-sql`** (greenfield — new dir; flips its "out of scope" status); all 6 dimensions; perf per ADR-0003; **new Security section** (no existing issue — sql wasn't in #84–86) | UC-001,002,004,009,010 | profile-sql | **P0** | F2 |
| **F5** | Build **`profile-frontend`** to the pattern; Security = **#86** | UC-001,002,004,009,010 | profile-frontend | **P0** | F2 |
| **F6** | Flesh out **cross-profile contract/integration/e2e testing** in `profile-common` (ADR-0002 full: opt-in lane, boundary contract tests, resilience failure-path tests) | UC-007, UC-010 | profile-common | **P0** | F2 + any 2nd profile |
| **F7** | **Command integration** — wire `/sdlc-feature`, `/sdlc-newproject`, `/sdlc-harden`, `sdlc-common` to load & apply the matching profile at gates (CAP-9) | UC-001–006, 009, 010 | Command integration | **P1** | F1, F2 |

**Security dimension note:** F2/F3/F5 absorb the in-flight per-profile security
issues **#85 / #84 / #86** as their Security-dimension slice (ADR-0001) — those
issues are not re-filed. **F4 (sql) needs a new security section** since sql was
never in that set. `/sdlc-harden` consuming these is the already-filed **#87**.

## Sequencing rationale

- **F1 first — it blocks everything.** The skeleton (ADR-0001) is the shape every
  other feature fills; nothing coherent can be built before it exists.
- **F2 is the pilot, and it's python on purpose.** Python is the most
  tooling-complete stack here — `ruff`, `bandit`/`ruff -S`, `pytest`, `pip-audit`
  are **already installed** — so it's the cheapest place to prove the
  6-dimension pattern (CAP-11) before cloning it four ways. Prove once, then
  replicate.
- **F3–F5 clone the proven pattern** and can run in parallel once F2 sets it.
  **SQL (F4) is a full v1 peer** but sequenced after the pilot (it's greenfield —
  same shape, more new-dir work, and its own new security section).
- **F6 waits for ≥2 profiles.** Cross-profile testing needs at least two real
  stacks to exercise an actual X→Y boundary — it's meaningless against one. High
  intrinsic priority (UC-007 is P0), but a genuine dependency pushes its build
  later. This is the priority-≠-order case, stated explicitly.
- **F7 is last and P1.** Command wiring only matters once the backbone + a real
  profile exist, some wiring already exists (harden §7, newproject scaffold), and
  profiles carry value when loaded manually even before full auto-wiring.
- **Deferral within features:** the perf dimension (ADR-0003) may ship thin and
  deepen per stack as a fast-follow; that does not block a profile from being Done.

## Filed issues (Gate 6 handoff)

| Feature | Issue | Depends on |
|---|---|---|
| F1 profile-common skeleton | **#89** | — |
| F2 profile-python (pilot) | **#90** | #89 |
| F3 profile-shell | **#91** | #90 |
| F4 profile-sql (greenfield) | **#92** | #90 |
| F5 profile-frontend | **#93** | #90 |
| F6 cross-profile testing | **#94** | #90 + a 2nd profile |
| F7 command integration | **#95** | #89, #90 |

Related (not re-filed): security dims **#84** (shell) / **#85** (python) /
**#86** (frontend) fold into F3/F2/F5; **#87** = harden consumes profile security.

## Handoff

- [x] Issues created for F1–F7 with `Depends on` lines
- [x] Linked #84/#85/#86 (security dims) and #87 (harden); sql-security filed under F4 (#92)
- [x] `PROGRESS.md` updated with the new backlog
- Next: `/sdlc-newproject` is N/A (repo exists); `/sdlc-feature` picks **F1 (#89)**,
  the earliest unblocked P0 — the `profile-common` skeleton.
