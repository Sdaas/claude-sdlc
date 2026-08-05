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

## Phase 1 — `/sdlc-newproject` slice ✅ done

Core scaffolder (`scaffold.sh` + templates) + shell profile (bats, cross-shell,
brew) + `/sdlc-newproject` command. Proven end-to-end; applied to `~/.claude`
(v0.1.0). Closed #1, #5, #6.

## Phase 2 — `/sdlc-feature` + first self-hosted feature ([milestone](https://github.com/Sdaas/claude-sdlc/milestones))

Rationale: build the tool that lets the SDLC build itself, then prove it by using
it. Self-hosted on **this repo only** until it graduates (see the self-hosting
strategy in memory / design docs).

Sequence:
```
#2  sdlc-common SKILL.md  (tiers, paths, governance, conventions)
      → #12 /sdlc-feature command (embedded gates; code + prose paths)
            → #13 python profile   ← FIRST feature built *by* /sdlc-feature (shakedown)
#8  README Setup + deps script      (parallel — no hard dependency)
```

## Phase 3 — more commands, profiles, deploy

All depend on **#12** (`/sdlc-feature`). Parallelizable once it exists:
```
#14 /sdlc-bugfix   #15 deploy(brew)   #16 profile-sql   #17 profile-frontend
#18 /sdlc-retrospective   #19 /sdlc-resume
```

## Phase 4 — refactor, adopt, migrate

```
#25 /sdlc-harden           (depends on #12) — gap analysis; #20 folded in as dup
#11 extract orchestrator  (depends on #14, #25 — only once multiple callers exist)
#4  extract gate skills   (tech-debt; after the embedded version proves out)
#21 migrate global shell skills into profile-shell
#22 model/token optimization
```

## Phase 5 — review remediation

Rationale: two independent reviews landed on 2026-08-05 — an external
professional review (`docs/reviews/2026-08-05-external-review.md`, Opus 4.8) and
this repo's own `/sdlc-harden` self-audit, the first real proof-run of #25
(a working document; its findings are decomposed into #63–#65 and the widened
#53, and it was discarded per #68). Their findings overlap heavily and share one root
cause: **single-source-of-truth discipline**. Rules are copy-pasted across
commands and cited by fragile numbers; paths are asserted in prose and never
checked. The drift this produces has already bitten twice (the `5→10` gate
renumber, the `/help` + `/verify` collisions).

The sequencing principle below is deliberate: **build the check before fixing
what it checks.** A TDD-first project should not repair a defect class by hand
when it can go red first. That is why the linter leads, not trails.

### How Phase 5 is executed

Per `sdlc-common` §5, **the batching unit is the issue** — the issue number is
the branch slug, so there is no such thing as a "5b branch." The command is
chosen by issue *type*, and the tier decides whether a gate-walking run is
needed at all:

| Tier | Issues | Execution |
|---|---|---|
| **Quick** (§2 — no command run) | #57, #59 | Surgical change on `main` → human review → commit. Batch them into one review. |
| **Standard — `/sdlc-bugfix`** | #52 | Reproduce-first. The only issue in the backlog with a real repro. |
| **Standard — `/sdlc-feature`** | #53, #58, #56, #55, #54, #11, #63, #64, #60, #65, #66, #62, #67 | One branch per issue. |
| **Full — `/sdlc-feature`** | #61 | Release: adds design-review + security-review + retrospective. |

`#66` carries the `type:bug` label but is an interview-text edit with nothing to
reproduce — it runs down `/sdlc-feature`'s **prose path**, not `/sdlc-bugfix`.

That is ~14 runs plus one Quick batch. Resist collapsing them: a branch that
maps to no issue breaks the slug convention and the `Depends on:` gating.

### 5a — Marker & hygiene (Quick tier, no deps, do first)
```
#57 root CLAUDE.md stack marker   ← unblocks profile detection for #65
#59 refresh PROGRESS.md; harvest the retro + audit docs, then discard them
```
`#57` is a prerequisite hiding in plain sight: `sdlc-common` §7 stack detection
reads this marker, and the harden audit had to *infer* the stack without it.

Both are Quick (§2): no logic change, no new tests. Straight to `main` under
review-before-commit — no `/sdlc-feature` run.

### 5b — The dangling-path class
```
#52 --license apache has no template     → /sdlc-bugfix   (reproduce-first)
      → #53 (part) path + template integrity checks   → /sdlc-feature
            → #58 README advertises a root templates/ that does not exist
            → #56 design/ vs docs/design/ — repo, scaffolder, README disagree
```
`#52`, `#58` and `#56` are **the same defect**: a path named in prose that is
absent on disk. Fixing them by hand fixes three instances; the check in `#53`
fixes the class.

**Sequencing constraint — red never reaches `main`.** "Tests green before push
and merge" (§5) is non-negotiable and the pre-push hook enforces it, so the
linter cannot be landed red and repaired later. Red is a state that lives
*inside* a branch and is green before the push.

`#52` therefore runs **first and alone**, as a genuine reproduce-first
`/sdlc-bugfix` (repro: `scaffold.sh --license apache` → `no license template
for: apache`). The SDLC is still self-hosting and `/sdlc-bugfix` needs the
mileage more than `#53` needs to demonstrate a red. `#53` then lands its checks
green, and `#58` / `#56` follow as ordinary `/sdlc-feature` runs — each one
extending the check's reach as it removes the last dangling path it knows about.

### 5c — Kill the numeric cross-refs (Standard, prose path)
```
#55 fix duplicate numbering in docs/design/overview.md
      → #54 replace §N / rule #N with stable named anchors
            → #53 (rest) assert every anchor resolves
```
Order matters: renumbering while references are still numeric multiplies the
edit surface. Fix the numbering, convert to anchors, *then* pin it with the
test. Note this retires the phrase "rule #10" — including its use in the
Cross-cutting principles below, which must be updated in `#54`.

**`#11` (extract the orchestrator / de-dup the command preamble) becomes ready
here.** The external review names it as the structural other half of `#54`: one
edit site per rule instead of N. It was blocked on "multiple callers exist" —
that condition is now met.

### 5d — Infra dogfooding (Standard, code path)
```
#63 hooks/ + symlink → .githooks/ + core.hooksPath
#64 --integration lane + clean-install CI  (dogfoods what #43 ships)
```
Independent of each other; both should precede `#61`, so a release is cut on CI
that actually exercises a clean install.

### 5e — Fill the empty gates (Standard, prose path)
```
#60 security-review gate gets real content   (a Full-tier gate with no checklist)
#65 hardening checklists for profile-python / profile-frontend   (depends on #57)
#66 signpost unwired distribution options at the point of choice
      → #53 (stretch) assert no interview option lacks an impl or a caveat
```
`#66` is `#52`'s twin — an option offered that the system cannot deliver — and
belongs to the same check.

### 5f — Framing, then release (Standard → **Full** for #61)
```
#62 human glossary + quickstart one-pager
      → #67 reconcile "deliberately simple" with actual Standard-tier ceremony
            → #61 cut a real release off 0.1.0; add a CHANGELOG
```
`#61` runs last on purpose: `VERSION` has sat at `0.1.0` through ~11 shipped
features, so the first honest release should carry all of Phase 5. `#67` reads
better once `#62` gives it a one-pager to point at.

### Harvested mid-phase (from the #59 close-out)
```
#68 /sdlc-retrospective → ephemeral doc + HARVEST gate   (the design change)
#69 sdlc-common: surface the trade-off when an instruction conflicts
      with a convention                                  (the #24 lesson)
```
Both came out of discarding the #24 retro rather than committing it. `#69` is a
single rule added to `sdlc-common` INTERVIEW guidance and can ride along with
`#54`'s edits to that file rather than taking its own run. `#68` is standalone
and should land before the next Full-tier close-out, which is `#61`.

### Not in this phase
`#15` (brew), `#16` (profile-sql), `#21` (migrate shell skills), `#22` (token
optimization), `#48` (frontend integration lane) predate these reviews and are
unaffected by them. `#4` (extract gate skills) still trails `#11`.

## Cross-cutting principles

Backlog = Issues · trivial→main / else branch · tests green before push & merge ·
review guide + **review-before-commit (rule #10)** · test-first · HITL at every gate.
