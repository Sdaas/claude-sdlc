# `/bugfix` — Design

Fix a bug in an **existing** SDLC repo through the gated, human-in-the-loop
workflow. Tracks Issue #14. Built by `/feature` (prose path), so it is a sibling
of `/feature` and reuses the same 9-gate skeleton and the `sdlc-common` rulebook.

## Why a separate command

A bug fix is not a feature: its discipline is **reproduce-first**, and its risk
profile skews toward security and design flaws. `/bugfix` encodes that discipline
so a fix can't skip the failing-test-first step or quietly patch a symptom.

## Defining rule — reproduce before you fix

A failing test that **reproduces the bug** must exist and go **red** before any
fix is written (code path, whenever a test is feasible). The reproducing test
then **stays** as a permanent regression test. This is the one non-negotiable
that distinguishes `/bugfix` from `/feature`.

## Two paths

- **CODE path** — the usual case. Reproduce with a failing test → red → fix the
  **root cause** → green → the test remains as a regression guard.
- **PROSE path** — a wrong instruction in a doc/command/skill. No red-green;
  correct the root of the confusion → re-verify the corrected instruction.

Path is proposed at CLASSIFY and confirmed by the human.

## Tier ladder (and when Full applies)

| Tier | Branch | Use when |
|---|---|---|
| **Quick** | `main` | genuinely trivial one-liner (still reproduce-first if a test is feasible) |
| **Standard** | `fix/<slug>` | most bugs |
| **Full** | `fix/<slug>` | any Full trigger below — Standard + design-review + security-review + retrospective |

Bug fixes branch **`fix/<slug>`** (not `feature/<slug>`), per `sdlc-common` §2.

**Full triggers** (any one):
1. **Security-sensitive** — the bug is a vulnerability.
2. **Design-rooted** — the honest fix changes a component contract/interface.
3. **Shipped/packaged surface** — touches `release.sh`, delivery/`apply.sh`, or a
   published artifact.
4. **High blast radius** — changes a shared interface, affects many callers, or
   risks data/state migration.

## Two escalations that keep the fix at the right altitude

- **Design flaw → `/architecture`.** If the root cause is architectural, `/bugfix`
  stops and routes back to `/architecture` to revise the decision/ADR first, then
  implements under Full. Patching a design flaw at function scope is a bandaid.
- **Security flaw → exploit-first, root-cause-by-class.** The reproducing test is
  an exploit/regression test; the fix addresses the **input class**, not the one
  payload; Gate 5 adds a security-review pass.

## Gate sequence

Same 9 gates as `/feature`, with three deltas:

```
CLASSIFY   — tier ladder w/ explicit Full triggers; path; branch fix/<slug>
REPRODUCE  — exact repro + root-cause hypothesis; design-flaw & security escalation
& DIAGNOSE
DESIGN     — brief; confirm the fix targets the root cause
IMPLEMENT  — code: failing repro test → red → root-cause fix → green → keep test
             prose: correct the root of the confusion → re-verify
CODE REVIEW— two-pass; confirm root cause closed, no regressions (+security @Full)
REVIEW GUIDE → HUMAN REVIEW → COMMIT & PUSH → CLOSE OUT (retro @Full)
```

## Relationship to the `fix-shell-bug` skill

The installed `fix-shell-bug` skill is the shell-specific, deep-dive version of
this discipline (write-a-failing-test-that-reproduces-the-bug-first). `/bugfix`
is the language-agnostic SDLC command; on a shell repo it and that skill share
the same reproduce-first spine.
