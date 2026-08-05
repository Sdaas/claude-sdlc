---
name: sdlc-harden
description: >
  Vocabulary and rules for hardening an existing repo up to SDLC standards — the
  gap-analysis workflow. Load this whenever running /sdlc-harden. Defines the
  stack-agnostic standards checklist (the four areas audited), the gap taxonomy
  (area × risk), the two modes (audit default / apply opt-in), the safety-net
  cardinal rule, the hybrid close mechanism (fix infra/doc/test-net in-harden,
  escalate behavior/logic gaps to /sdlc-feature or /sdlc-bugfix), and how the
  stack-specific checklist is delegated to a profile. The command that loaded this
  skill walks the actual gate sequence; this skill defines what each term means.
---

# SDLC — Harden (gap analysis) Conventions

The rulebook for bringing an **existing** repo up to SDLC standard. A repo may
have been built outside this SDLC, or built earlier and left behind as the SDLC
evolved. `/sdlc-harden` audits it against the standards, reports the gaps in a
categorized form, discusses priorities with the human, and closes the agreed
gaps incrementally with approval at each step.

This skill is stack-agnostic: it owns the **workflow and the standards core**;
the concrete, stack-specific checklist is **delegated to the matching profile**
(see §5). It builds on `sdlc-common` (tiers, paths, governance, hard rules) —
load that too.

## The cardinal rule

**Never refactor code that has no tests.** Before *any* fix that could change
behavior, pin the current behavior with **characterization tests** (pass-now, not
fail-first) run through the repo's `./test.sh`, green on the untouched code. That
safety net is the whole point — do not skip it, even in a hurry. A
characterization test that fails on unchanged code is mis-written; fix it before
proceeding. (Adapted from the shell-family `harden-shell-repo` skill.)

## 1. Two modes (what harden does to the code)

- **Audit (default)** — build the safety net and the missing **infrastructure**
  (test runner, hooks, CI, README/`design/` docs, characterization tests) and
  deliver a **categorized gap report**. Does **not** edit the code's own logic.
- **Apply (opt-in)** — everything audit does, **plus** the guided close loop (§5)
  that edits the code for the agreed **behavior-touching** gaps
  (behavior-preserving and, with sign-off, behavior-changing) under the green
  safety net. **Infra-doc gaps are closed in both modes; code-logic edits are
  apply-only.**

Confirm the mode at CLASSIFY. Default to audit unless the human asks to apply.

## 2. Mode vs. tier — two different knobs

Do not conflate them:

- **Mode** = *what harden does to the code* — audit (infra + report only) vs.
  apply (also change logic).
- **Tier** (`sdlc-common` §2) = *how much process wraps the work* — Quick /
  Standard / Full (which review gates run).

An **apply** run can be **Standard** tier; an **audit** of a shipped tool can be
**Full**. Propose both at CLASSIFY; the human confirms.

## 3. The standards checklist (what we audit against)

The **stack-agnostic core** — four areas. Each profile refines these with its own
concrete checks (§7).

1. **Test net + `./test.sh` runner** — tests exist, run through a **single**
   `./test.sh`, and are green. Untested code is pinned with characterization
   tests first (the cardinal rule). Boundaries are exercised un-mocked at least
   once (`sdlc-common` §3).
2. **CI + pre-push hook** — a GitHub Actions workflow that runs `./test.sh`, and
   a **versioned** pre-push hook (`.githooks/` + `core.hooksPath`) that runs it
   and blocks a red push.
3. **Docs — README + `design/`** — README to the standard outline (Purpose ·
   Quick Start · User Guide · Developer Guide · Automated Testing Guide · Release
   Process) and a curated `design/overview.md` capturing the **key** decisions.
4. **Logging + coding standards + backlog** — the leveled **logging policy**
   (INFO default, DEBUG via `--verbose`, ERROR always; logs→stderr, data→stdout;
   ISO-8601 UTC); the profile's **coding conventions** (lint/format, layout,
   strict mode); and **backlog discipline** (GitHub Issues + branching:
   trivial→`main`, else its own branch).

## 4. The gap taxonomy (how the report is categorized)

Every gap is tagged on **two axes** — its **area** (§3: test-net / CI-hooks /
docs / logging-coding-backlog) and its **risk class**:

- **Infra-doc** — no runner, no CI, no pre-push, missing/again-standard README or
  `design/`, missing tests. **Safe** to add; changes no existing behavior.
- **Behavior-preserving** — cleanups that keep observed behavior: quoting,
  scoping, `--help`/`--verbose`, meaningful exit codes, adding the logging
  policy, tmp-file cleanup. Low-risk under a green safety net.
- **Behavior-changing** — enabling strict mode, changing exit codes, altering
  error handling or output. **Requires explicit per-category sign-off** and the
  safety net to make the delta visible.

The report is **grouped by area, each finding tagged with its risk class**, so
the human can prioritize by both. Use the `templates/gap-report.md` skeleton.

## 5. The close mechanism (hybrid)

After the human prioritizes (each gap → **close / defer / drop**), close the
agreed gaps by **risk class**:

- **Infra-doc → fixed in-harden in both modes.** Adding the runner, hooks, CI,
  docs, and characterization tests changes no existing behavior.
- **Behavior-preserving + behavior-changing → fixed in-harden, apply mode only.**
  One **category at a time** under the green `./test.sh`: apply the category →
  re-run → green keeps it, red means behavior changed (decide with the human:
  intended → update the pinned test; regression → revert). **Behavior-changing**
  categories additionally need **per-category sign-off** before applying.
- **Behavior / logic gaps (a real feature or bug) → escalate.** File the issue
  and hand it to **`/sdlc-feature`** (new capability) or **`/sdlc-bugfix`**
  (defect) — harden does not reproduce/patch product logic itself. This keeps
  each real change on its proper gated path.

**In audit mode, stop after the safety net + infra are in place and the report is
delivered.** In apply mode, run the close loop above.

## 6. Backlog policy — report first, then file

**Do not** file an issue per raw gap (board spam). The **report is the first
artifact**; after the human prioritizes, file GitHub issues only for the
**close + defer** set (the **drop** set is recorded in the report, not filed).
Each in-harden fix and each escalation references its issue (`sdlc-common` §5,
backlog = Issues). Degrade gracefully: if the repo is not a git repo or `gh` is
unavailable/unauthenticated, **write the report to a file** (e.g.
`docs/harden-report.md`), skip issue-filing, and **state why** (mirrors
`/sdlc-feedback`).

## 7. Profile delegation (the stack-specific checklist)

The core (§3) is stack-agnostic; the **concrete** checks come from the matching
profile (`sdlc-common` §7 — read the repo's `CLAUDE.md` marker; if absent, infer
the stack and **propose** a profile):

- **shell** — delegate to the existing **`harden-shell-repo`** skill and its
  `shell-common` references (best-practices, characterization-tests,
  test-runner-and-CI, project-structure, doc-updates). `/sdlc-harden` owns the
  workflow; `harden-shell-repo` supplies the deep shell checklist. *(Folding this
  content into `profile-shell` is tracked as #21 — not done here.)*
- **python** — audit against the profile's conventions: `uv` + hatchling,
  `src/<pkg>` layout, `ruff` (lint+format), pytest (with the `integration`
  marker / opt-in lane), `requires-python`, the clean-install CI job.
- **frontend** — Vite + TS, Vitest, `tsc --noEmit` + `prettier --check`.
- **No deep checklist yet** (e.g. python/frontend/sql have no dedicated hardening
  skill): audit against the known profile conventions above and **flag "no deep
  hardening checklist for <profile> yet" as a known gap** in the report rather
  than inventing one.

## 8. What "done" means here

A harden run is Done when: the **safety net is green** on the (possibly changed)
code; the **agreed infra gaps are closed**; the **report** reflects final status
(closed / deferred-with-issue / dropped); every closed/deferred gap has an
**issue** (or the stated degradation reason); and the real flow was **VERIFY**-ed
(`sdlc-common` §5) — the runner runs, CI is present, hooks fire. Escalated
behavior/logic gaps are Done when their `/sdlc-feature` / `/sdlc-bugfix` run is.

## References

- `sdlc-common` — tiers, code/prose paths, governance, hard rules (load first).
- `harden-shell-repo` (global skill) — the deep **shell** hardening checklist and
  the characterization-test method this skill's cardinal rule is adapted from.
- `templates/gap-report.md` — the categorized gap-report skeleton.
