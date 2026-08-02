---
name: sdlc-discovery
description: >
  Shared vocabulary, gate definitions, and artifact templates for the upstream
  discovery and architecture phase of the SDLC. Load this whenever running
  /sdlc-discovery or /sdlc-architecture. Defines the four artifacts (concept
  brief, use-case catalog, architecture overview + decision records, feature
  backlog), the human-prose-vs-AI-distillation rule, the traceability rule, and
  the handoff into GitHub Issues + /sdlc-feature. The command that loaded this
  skill walks the actual gate sequence; this skill defines what each term means.
---

# SDLC — Discovery & Architecture Conventions

The rulebook for the phase that runs **before** a repo exists:

```
/sdlc-discovery → /sdlc-architecture → /sdlc-newproject → /sdlc-feature → /sdlc-feature → …
  (what)              (how)               (scaffold)      (build one component at a time)
```

Its whole purpose is to make the "big picture" a set of **durable, versioned
artifacts behind human gates**, so `/sdlc-feature` builds against a known
architecture instead of chat scrollback. Every arrow below emits an artifact and
passes a gate — or it decays into slop.

## 0. Where the artifacts live

`/sdlc-discovery` and `/sdlc-architecture` run in a **product workspace** — a
directory for the idea, which is usually not yet a code repo. They write plain
markdown:

```
discovery/
  concept.md          # problem, actors, non-goals, scope
  use-cases.md        # actor · trigger · flow · pre/post · priority
architecture/
  overview.md         # capability map + C4-ish container diagram
  decisions/NNNN-*.md # one ADR per contested decision
  components.md       # the feature backlog: traced + sequenced
```

`/sdlc-newproject` later seeds a scaffolded repo's `design/` from these. **v1 does not
hard-wire that handoff** — it only fixes the locations. (Deferral discipline: let
the first real run tell us how tight the coupling must be.)

## 1. The prime rule — human is the source of truth, AI structures

These commands are **not** "AI drafts, human edits." The human holds the domain
truth; the AI **interviews, structures, and challenges**. Every artifact keeps
two visibly separate kinds of content:

- **`In your words:`** — the human's own prose, stored **verbatim**. Ground
  truth. The AI never overwrites or paraphrases it in place.
- **AI distillation** — the structured rendering beside it (the actor/trigger
  table, the capability list, the ADR options), **labeled as AI-derived** and
  requiring explicit approval.

Why: **provenance.** You can always tell which requirements are *yours* from
which the AI inferred. This kills the worst slop failure — the AI quietly
inventing a requirement ("add an Extraction Router") that nobody asked for and
that then gets built. Every such item must land in one of the two buckets:
"user said this" or "AI proposes this — approve?".

The AI's job at each interview step is to **ask and challenge, not to author**.
Prefer surfacing gaps, contradictions, and missing non-goals over filling them.

## 2. The traceability rule (the anti-slop mechanism)

The chain is **use case → capability → component/feature → back to use case.**

- Every **capability** names the use-case ID(s) it serves.
- Every **component / backlog feature** names the use-case ID(s) it satisfies.
- A feature that cannot name the use case it serves **does not get built** — it
  is either dropped or sent back to `/sdlc-discovery` to justify a new use case.
- Every **use case** should be reachable by at least one component, or it is an
  orphan requirement (flag it).

## 3. Artifacts and their gates

Each gate is an explicit checklist the human approves. This is what replaces
"yes brother, 80% match" with a pass/fail you can actually apply.

| Artifact | Produced by | Gate passes when |
|---|---|---|
| **concept.md** | /sdlc-discovery | Non-goals are written down; every actor is named; the one-sentence "what we're building" is agreed. If you can't say what you're *not* building, you're not ready. |
| **use-cases.md** | /sdlc-discovery | Every use case has a **priority** and a testable **"done when…"**; each traces to at least one actor; no orphan flows. |
| **architecture/overview.md** | /sdlc-architecture | Every use case is served by ≥1 capability; the container diagram shows how pieces connect; nothing floats. |
| **decisions/** (ADRs) | /sdlc-architecture | Every **contested** choice has an ADR: 3–4 options, a comparison metric, the pick, and the one-line why. |
| **components.md** (feature backlog) | /sdlc-architecture | Every feature traces back to use-case IDs; the sequence respects dependencies + deferral (core before peripheral). |

## 4. Gate sequence — /sdlc-discovery

1. **FRAME** — state the concept in one sentence; confirm we are in discovery
   (idea stage, not yet a repo); agree the workspace directory.
2. **INTERVIEW · concept** — problem, actors, value proposition, scope boundary,
   and **non-goals**. Capture prose verbatim; challenge for missing non-goals.
3. **CONCEPT BRIEF** — write `discovery/concept.md` from the template. Present;
   pass the concept gate (§3).
4. **INTERVIEW · use cases** — per actor, elicit what they must be able to *do*.
   For each: trigger, main flow, pre/post-conditions, priority, "done when".
   Accept free-form prose where the human gives it; distill beside it.
5. **USE-CASE CATALOG** — write `discovery/use-cases.md`. Present; pass the
   use-case gate (§3).
6. **HUMAN REVIEW** — approve both artifacts before handing off to
   `/sdlc-architecture`. Never proceed on an unreviewed artifact.

## 5. Gate sequence — /sdlc-architecture

**Precondition:** `discovery/concept.md` and `discovery/use-cases.md` exist and
are gate-approved. If not, stop and point the human at `/sdlc-discovery`.

1. **CAPABILITY MAP** — derive the capabilities the system needs; each names the
   use-case ID(s) it serves (§2). Surface capabilities no use case demands as
   "AI proposes — approve?".
2. **STRUCTURE** — group capabilities into components; draw a C4-ish container
   diagram (mermaid or text). Show connections and boundaries.
3. **DECISIONS** — for each contested choice (stack, storage, sync/async,
   build-vs-buy, engine), write an ADR: 3–4 options, a comparison metric, the
   pick, the one-line why. This is the "why I chose what" document, made real.
4. **FEATURE BACKLOG** — decompose into features sized for one `/sdlc-feature`
   run. Trace each to use-case IDs; sequence by dependency + deferral discipline.
   Write `architecture/components.md`.
5. **HANDOFF** — optionally create GitHub Issues from the backlog with
   `Depends on: #N` lines (backlog = GitHub Issues, per `sdlc-common` §5). This
   is what `/sdlc-feature` consumes.
6. **HUMAN REVIEW** — approve the architecture + backlog before any handoff.

## 6. Altitude & scale

Keep every artifact **curated, not exhaustive** — key points only, same rule as
`design/overview.md`. Discovery is exploratory: expect messy back-and-forth in
the interview, but converge each artifact to something stable before its gate.
Scale effort to the idea — a small tool needs one page of concept and a handful
of use cases, not a treatise. Do not let ceremony outweigh the idea.
