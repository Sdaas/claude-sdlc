# ADR-0004 — Scaffolding (CAP-7) vs. the existing `templates/` and `/sdlc-newproject`

- **Status:** accepted
- **Date:** 2026-08-06
- **Serves:** UC-005

## Context

`profile-shell` and `profile-python` are to own scaffolding (content-kind (c)).
But scaffolding **already exists**: `payload/skills/profile-*/templates/` drives
`/sdlc-newproject`. A declared non-goal is "do not replace `templates/`." So the
question is how the profile skill's scaffolding relates to what's already there —
without creating a second, drifting source of truth.

## Options considered

| Option | Pros | Cons |
|---|---|---|
| **A — Profile references the existing `templates/`; adds the standards they must satisfy** | Single source of truth; respects the non-goal; no duplication | Profile and templates must be kept aligned (but one owns files, other owns standards) |
| **B — Profile embeds its own scaffolding, separate from `templates/`** | Self-contained profile | Two sources → drift; violates the non-goal |
| **C — Migrate `templates/` into the profile skill and rewire `/sdlc-newproject`** | One home | Touches shipped scaffolding + a command = infra churn; against non-goal |

**Comparison metric:** **single-source-of-truth** (fewest places the same
scaffolding decision is expressed).

## Decision

**Chosen: Option A.** The existing `templates/` remain the scaffolding files and
`/sdlc-newproject` keeps consuming them. The profile skill **references** them and
adds the *standards* the templates are expected to satisfy (so a scaffolded repo
is born compliant, UC-005) — the profile owns the "what good looks like," the
templates own the files.

**Why (one line):** referencing the existing templates is the only option that
keeps one source of truth and honors the "don't replace templates/" non-goal.

## Consequences

- No template files move in this initiative; `/sdlc-newproject` is untouched by CAP-7.
- The profile's scaffolding section is a pointer + a conformance note, not a copy.
- If a template is found non-conformant with the new standard, that is a normal
  `/sdlc-feature` or `/sdlc-harden` item against the templates, filed separately.
