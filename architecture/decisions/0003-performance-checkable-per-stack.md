# ADR-0003 — How "performance & scalability" is made checkable per stack

- **Status:** accepted
- **Date:** 2026-08-06
- **Serves:** UC-004

## Context

"Performant & scalable" is the hardest dimension to keep out of vibes. UC-004's
"done when" demands the agent name a concrete perf/scale risk **or** clear it
against a **named signal** — so the profile must supply falsifiable signals, not
adjectives. But building a bespoke benchmarking/load-test harness per stack is a
declared non-goal (no infra overhaul).

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **A — Qualitative checklist only** (agent reasons, no tool) | Cheap; always available | Not falsifiable; slides back into vibes |
| **B — Named per-stack signals + existing tooling + thresholds** | Falsifiable; uses tools that already exist (profiler, `EXPLAIN`, bundle analyzer); no new infra | Thresholds need judgement; not full load-testing |
| **C — Bespoke benchmark/load-test harness per profile** | Rigorous | Violates the no-infra-overhaul non-goal; heavy to build/maintain |

**Comparison metric:** **falsifiability per unit of build cost** — the most
checkable signal we can get without building new infrastructure.

## Decision

**Chosen: Option B.** Each profile names concrete perf/scale **signals + the
existing tool** that surfaces them, and the agent must flag-or-clear against a
named one:

- **sql** — `EXPLAIN`/query plan, missing-index & full-scan checks, N+1 patterns,
  row-count growth assumptions.
- **python** — hot-path profiling (`cProfile`/`timeit`), algorithmic complexity of
  the changed path, sync-in-async / blocking-IO, unbounded memory/collections.
- **frontend** — bundle-size budget, render/re-render cost, network waterfall,
  main-thread blocking.
- **shell** — process-spawn cost in loops, quadratic loops, streaming vs.
  buffering large data.

**Why (one line):** named signals over existing tools give falsifiability without
the infra a bespoke harness would demand (the non-goal).

## Consequences

- Each profile's Performance section is a short list of named signals + how to
  observe them, plus the flag-or-clear bar.
- Load/stress testing at scale is explicitly out of v1 (revisit per project need).
- This is the dimension most likely to start thin and deepen per stack.
