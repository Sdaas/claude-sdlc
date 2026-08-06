---
name: profile-common
description: >
  Backbone for every stack profile in the SDLC — the fixed SKILL.md skeleton that
  profile-shell, profile-python, profile-sql, and profile-frontend all follow.
  Defines the six quality dimensions (best practices, performance, testing,
  security, reliability, observability), the scaffolding section (shell/python
  only), and the cross-profile testing home. Load this to author or review a
  profile, or to learn the quality bar once and transfer it across stacks.
---

# Profile — Common (the backbone)

`profile-common` is to the stack profiles what `sdlc-common` is to the workflow
commands: the shared rulebook that keeps them consistent. It does **not** describe
any one stack. It defines the **fixed shape** every `profile-<stack>` renders, so
that:

- an **agent** can rely on "the performance section is always here, called this",
  at IMPLEMENT / VERIFY / review time; and
- a **reader** who learns one profile can transfer that knowledge to another
  (UC-008) — the bar is in the same place everywhere.

## How to use this skeleton

A profile author (building `profile-python`, `profile-shell`, …) **clones the
section shape below** and fills each section with the concrete "how" for that one
stack — the tools, commands, thresholds, and idioms. `profile-common` gives the
headings and states *what each section must answer*; the profile gives the
stack-specific answers.

**Two hard rules (ADR-0001):**

1. **Fixed shape.** Keep the section set and their order. "The same place
   everywhere" is the entire point of a backbone — reordering or renaming defeats
   it.
2. **N/A is stated, never dropped.** If a dimension genuinely does not apply to a
   stack, keep the section and write **`N/A — why`** (e.g. shell scaffolding is
   real, but sql has no scaffolding: "N/A — why"). A missing section is
   indistinguishable from an oversight; an explicit N/A is a decision.

---

# The skeleton — six quality dimensions

Every profile renders these six, in this order. Each carries the stack's standard
plus the tooling that checks it.

## 1. Best practices

*What this section answers:* the stack's **style/idiom standard** and the
**lint/format tooling** that enforces it — what "clean, idiomatic code" means for
this stack and the command that proves it. (CAP-1 · serves UC-001, UC-008.)

A profile's section states: the linter/formatter (and config), the "run it"
command, and the highest-signal idioms a reviewer checks by hand.

## 2. Performance & scale

*What this section answers:* what makes performance **checkable** for this stack —
the concrete signals, thresholds, and tooling (ADR-0003), not vague advice.
(CAP-4 · serves UC-004.)

A profile's section states: the measurable signals that matter for the stack, how
to observe them, and any tool/command. This dimension **may ship thin and deepen
per stack as a fast-follow** — a thin-but-honest section does not block a profile
from being Done. If a stack has no meaningful perf surface, state **`N/A — why`**.

## 3. Testing pyramid

*What this section answers:* the stack's **testing standard across the pyramid**
(unit → integration → e2e) and its **test runner** — where each layer lives and
how `./test.sh` drives it. (CAP-2 · serves UC-002.)

A profile's section states: the framework(s), the layer split (and the fast vs.
opt-in integration lane, per `sdlc-common` §3), and the single command that runs
them. Cross-**profile** (cross-language) testing is not here — see
[Cross-profile testing](#cross-profile-testing) below.

## 4. Security

*What this section answers:* the stack's **security checklist + scanner**. This
dimension **delegates to the shared `sdlc-security` skill** for the review method
and the six-category checklist; the profile carries the **stack-specific** checks
and the scanner command. (CAP-3 · serves UC-003.)

A profile's section states: a starter **floor, not a ceiling** of stack-specific
checks (injection/quoting, secrets, filesystem, deps, …) and the scanner
(`bandit`/`ruff -S`, `shellcheck`, …). It is consumed by the `sdlc-security`
Full-tier gate and by `/sdlc-harden`. See the shared skill: **`sdlc-security`**.

## 5. Reliability & resilience

*What this section answers:* how code in this stack **survives partial failure at
its boundaries** — retry, backoff, timeout, idempotency, graceful degradation.
(CAP-5 · serves UC-010.)

A profile's section states: the stack's idioms for timeouts/retries/backoff at
network/subprocess boundaries, and the **failure-path test** that proves them —
co-located with the boundary's contract test (see
[Cross-profile testing](#cross-profile-testing)).

## 6. Observability & logging

*What this section answers:* how this stack **renders the shared logging policy** —
levels, destination, format, and mechanism. This dimension **renders the shared
`design/logging-policy.md`** for the stack; it does not invent its own policy.
(CAP-6 · serves UC-009.)

A profile's section states: the stack's logging mechanism and how it maps to the
policy's `DEBUG`/`INFO`/`ERROR` levels, `--verbose` selection, and stderr
destination. See the authoritative policy: **`design/logging-policy.md`**.

---

# Content-kind sections

Beyond the six dimensions, a profile carries these where applicable.

## Scaffolding (shell / python only)

*What this section answers:* the stack's **project scaffolding** — the templates a
new repo is generated from, aligned to the standards above. Scaffolding exists for
**shell and python only** (CAP-7); it **references the existing `templates/` dir**
rather than re-inventing it (ADR-0004), and `/sdlc-newproject` generates from it.

- **shell, python:** point at `payload/skills/profile-<stack>/templates/` and note
  what a generated repo inherits (entry point, `test.sh`, hooks, logging).
- **sql, frontend:** **`N/A — why`** — these stacks ship no scaffolding in v1
  (state the reason, keep the section).

## Cross-profile testing

> **Stub — fleshed out in F6 (#94).** This section shell records the shape ADR-0002
> fixed; F6 fills in the concrete lane, contract tests, and resilience failure-path
> tests once ≥2 real profiles exist to exercise a boundary.

*What this section answers:* how a component in one stack is tested against a
component in **another** stack (python↔sql, frontend↔python/shell). This is owned
by `profile-common` because it belongs to no single profile (ADR-0002 · CAP-8 ·
serves UC-007, UC-010).

The shape (ADR-0002):

- **Contract tests at the boundary.** Each side of an X→Y boundary has a contract
  test, per the `sdlc-common` §3 mock-obligation rule.
- **An opt-in integration/e2e lane.** A single `./test.sh` with a lane that is
  **local + nightly, skippable in PR CI** (so PR CI stays green without live
  services/secrets), reusing the split-suite pattern the python/shell profiles use.
- **Resilience is co-located.** The UC-010 failure-path test (timeout/retry/
  backoff) lives next to the boundary's contract test — same boundary, two tests.
- **One un-mocked run at VERIFY** exercises the real cross-stack boundary before
  Done.

---

# Shared standards this backbone points at

| Dimension | Shared standard | Where |
|---|---|---|
| Security (4) | Review method + six-category checklist | **`sdlc-security`** skill |
| Observability (6) | Levels, destination, format, per-stack mapping | **`design/logging-policy.md`** |
| Scaffolding | Existing scaffolding templates (shell/python) | `payload/skills/profile-<stack>/templates/` |

_Traceability: CAP-10 (backbone + consistent structure), CAP-8 (cross-profile
testing). Serves UC-008 (read the bar once, transfer it) and UC-007 (a findable
home for cross-profile testing). Source: `/sdlc-architecture` backlog F1 (#89);
ADR-0001, ADR-0002._
