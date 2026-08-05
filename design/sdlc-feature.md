# `/sdlc-feature` — Design

Add a capability to an **existing** SDLC repo through the gated, human-in-the-loop
workflow. Tracks Issues #2 (sdlc-common), #3 (orchestrator), #4 (gates).

This is the component we hand-build, then **self-host**: once applied, we use
`/sdlc-feature` to build the rest of the SDLC (this repo only) until it graduates.

## Two paths (both first-class from day one)

Every feature is classified into a **path** as well as a tier:

- **CODE path** — behavior/logic changes. Test-first (red → green → refactor).
  Optionally the test-writer runs as an **isolated subagent** that sees the
  requirements but NOT the implementation plan, so tests encode intent.
- **PROSE path** — markdown skills, docs, design, templates. No red-green;
  instead draft → self-check against a checklist → human review. Still gated by
  review-guide + review-before-commit. (Most remaining SDLC components use this.)

The path is proposed at CLASSIFY and confirmed by the human.

## Tier dial (effort scales to the task)

| Tier | Branch | Gate path |
|---|---|---|
| **Quick** | `main` | classify → surgical change → **review** → commit |
| **Standard** | `feature/<slug>` | classify → interview → design(brief) → implement → verify → code-review → review-guide → **human review** → commit → pre-push |
| **Full** | `feature/<slug>` | Standard + design-review, security-review, retrospective |

`implement` = the CODE or PROSE path above. Tier is proposed at CLASSIFY; human
confirms or overrides.

## Gate sequence (Standard)

```
CLASSIFY (issue + tier + path + branch)
  → INTERVIEW (requirements, edge cases, constraints)
  → DESIGN (brief; record KEY decisions into design/overview.md)
  → IMPLEMENT
       code path : write failing test → red → implement → green → refactor
       prose path: draft artifact → self-check vs checklist
  → VERIFY (drive the real flow; exercise each boundary un-mocked; Def. of Done)
  → CODE-REVIEW (2-pass; prose: checklist review)
  → REVIEW-GUIDE (changed files + recommended order)
  → HUMAN REVIEW (approval gate — rule #10)
  → COMMIT → PRE-PUSH (test.sh green) → optional PR/merge
```

## Why a VERIFY gate (#42)

Green hermetic tests are necessary but not sufficient: a red written against a
**mock** goes green the moment the mock is satisfied, proving only the mock.
medical-ocr#7 shipped fully green because the external boundary was mocked — a
missing runtime dependency and a truncation default both passed CI. So after
IMPLEMENT, **VERIFY** drives the real user-facing flow and exercises every
external boundary un-mocked at least once, before code review. This is the
concrete enforcement of the **Definition of Done** ("green tests AND observed
behavior", `sdlc-common` §5) and the **mock-obligation rule** (§3: mocking a
boundary owes ≥1 opt-in non-mocked test there). Required when the change crosses
an external boundary or user-facing entry point; skippable — with a stated
reason — only when there is no runtime surface to drive.

## What it reads / writes

- **Stack detection:** reads the repo's `CLAUDE.md` marker (archetype/profile)
  so it knows shell/python/etc. without asking again.
- **Backlog:** links or creates a GitHub Issue at CLASSIFY; slug = issue number.
- **Design:** appends only **key** decisions to `design/overview.md` (curated).
- **Branch:** trivial → `main`; else `feature/<slug>`.
- **Tests/release:** always via the repo's `test.sh` / `release.sh`.

## What we build for v1 (minimal, then grow)

1. **`payload/skills/sdlc-common/SKILL.md`** (prose) — the shared conventions the
   command leans on: tier definitions, the two paths, the governance matrix,
   branching/backlog rules, and rule #10. Kept lean.
2. **`payload/commands/sdlc-feature.md`** (prose) — the command that loads
   `sdlc-common` and walks the gate sequence above.

Deferred: a standalone `sdlc-orchestrator` skill (v1 embeds the sequence in the
command; factor it out once `/sdlc-bugfix`/`/sdlc-harden` share it); Full-tier
design-review/security-review kept light for now.

## How we validate `/sdlc-feature` v1

Because `/sdlc-feature` is mostly prose, we validate it by **using it** to build the
**python profile** (a CODE-path feature that extends the already-tested
`scaffold.sh`). A clean end-to-end run — interview → design → TDD → review →
commit, no manual rescue — is the shakedown (and graduation criterion #4).

## Non-goals (v1)

- Not a replacement for the existing global shell skills yet.
- No automatic merge without human approval.
- No model/token optimization.
