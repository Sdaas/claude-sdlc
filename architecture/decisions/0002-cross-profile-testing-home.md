# ADR-0002 — Where cross-profile (cross-language) testing lives and how it runs

- **Status:** accepted
- **Date:** 2026-08-06
- **Serves:** UC-007 (and UC-010 resilience at call boundaries)

## Context

The apps this SDLC builds mix stacks (python↔sql, frontend↔python/shell) and the
components **interact** — the core motivation. Testing that a stack-X component
correctly talks to a stack-Y component is not owned by either profile. Two
questions: **where does this guidance live**, and **how is a cross-language e2e
actually driven** without breaking PR CI (which must stay green without
secrets/live services, per `sdlc-common` §3)?

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **A — `profile-common` owns cross-profile testing guidance** | No new skill; sits with the backbone; discoverable next to the shared shape | `profile-common` carries a second concern |
| **B — Dedicated `profile-integration` skill** | Clean separation | Skill sprawl for v1; another thing to load/maintain before it's proven |
| **C — Fold into `sdlc-common` boundary inventory** | Reuses the existing boundary concept | Overloads the workflow rulebook with stack-testing mechanics |

**Comparison metric:** **cohesion vs. sprawl** — fewest moving parts that still
keeps cross-profile testing findable and not buried.

## Decision

**Chosen: Option A** — `profile-common` owns the cross-profile
contract/integration/e2e testing guidance (CAP-8). **How it runs:** a single
`./test.sh` with an **opt-in integration/e2e lane** (local + nightly, skippable in
PR CI) — reusing the split-suite pattern the python/shell profiles already use and
the `sdlc-common` §3 mock-obligation rule (contract test at the boundary + one
un-mocked run at VERIFY). Revisit extracting a `profile-integration` skill (Option
B) **if** the guidance outgrows one section.

**Why (one line):** keeping it in the backbone is the least-sprawl option that
still makes cross-profile testing a first-class, findable concern.

## Consequences

- `profile-common` gains a "Cross-profile testing" section; contract tests live at
  the boundary, e2e in an opt-in lane so PR CI stays green.
- If/when it grows, extract to `profile-integration` (this ADR would be superseded).
- Ties resilience (UC-010: retry/backoff/timeout) to the same boundaries — the
  failure-path test and the contract test are co-located.
