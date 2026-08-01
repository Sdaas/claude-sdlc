# Feature Backlog — <product name>

> Produced by `/architecture` — its terminal artifact. Each row is a **feature**
> sized for one `/feature` run, **traced** to the use cases it satisfies and
> **sequenced** by dependency + deferral discipline. This is what becomes GitHub
> Issues (`Depends on: #N`) and what `/feature` builds one at a time.
>
> Gate: every feature traces to use-case IDs (no floating work); the sequence
> respects dependencies and puts core before peripheral.

## Components (from architecture/overview.md)

<Short list of the architectural components these features build out, so the
backlog stays anchored to the structure.>

- **<Component>** — <one line>

## Backlog

Ordered by build sequence. A feature blocked by another lists it under
`Depends on`.

| # | Feature | Serves (UC) | Component | Priority | Depends on |
|---|---|---|---|---|---|
| F1 | <verb-phrase feature> | UC-001 | <component> | P0 | — |
| F2 | <feature> | UC-002, UC-003 | <component> | P0 | F1 |
| F3 | <feature> | UC-005 | <component> | P1 | F2 |
| … | | | | | |

## Sequencing rationale

<Why this order — the dependency logic and the deferral calls. E.g. "F1 before
F2 because F2 needs the storage F1 establishes; claims features (F9–F12)
deferred until the core document pipeline (F1–F6) is stable." This is the part
that used to be vibes ("do 2B before 2C, brother") — make the logic explicit.>

## Handoff

- [ ] Issues created for P0 features with `Depends on` lines
- [ ] `PROGRESS.md` / board updated with the new backlog
- Next: `/feature` picks the earliest unblocked P0.
