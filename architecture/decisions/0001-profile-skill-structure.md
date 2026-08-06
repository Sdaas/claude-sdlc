# ADR-0001 — Profile SKILL.md structure (the shared skeleton)

- **Status:** accepted
- **Date:** 2026-08-06
- **Serves:** UC-008, and coherence of UC-001–006, 009, 010 across 4 profiles

## Context

Five quality dimensions × four profiles is 20 chunks of guidance. Without a shared
shape they drift: the agent can't rely on "the perf section is always here," and a
reader (UC-008) can't learn one profile and transfer. `profile-common` (CAP-10)
exists to prevent this. The in-flight security work (#84/85/86) already put a
`## Security checklist` section in three profiles — the structure must absorb that
without rework.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **A — Freeform per profile** | Zero convention friction | Guaranteed drift; UC-008 transfer fails; no place is "the same place" |
| **B — Fixed 5-dimension skeleton owned by `profile-common`** | One shape everywhere; readers + agents know where each dimension lives; security section already fits | Some sections thin for some stacks (e.g. shell perf) |
| **C — `profile-common` structure, profiles free to reorder/override** | Flexibility | Reordering defeats the "same place" benefit; half-convention |

**Comparison metric:** **cross-profile consistency** (can an agent/reader rely on
the same section existing in the same place across all four profiles?).

## Decision

**Chosen: Option B** — `profile-common` defines a fixed `SKILL.md` skeleton with a
section per dimension (Best practices · Performance & scale · Testing · Security ·
Reliability & resilience), plus scaffolding for shell/python. The existing
`## Security checklist` section (#84/85/86) **becomes** the Security dimension
section — those issues continue unchanged as the way that section gets filled.

**Why (one line):** a fixed skeleton is the only option that delivers
cross-profile consistency, which is the whole point of a backbone.

## Consequences

- `profile-common` must be built (or at least its skeleton) **first** — it blocks
  the per-profile work (drives sequencing, CAP-11 pilot).
- #84/85/86 are absorbed as the Security-dimension slice of each profile, not
  separate artifacts.
- A dimension that is genuinely N/A for a stack states "N/A — why", it does not
  drop the section (keeps the shape intact).
