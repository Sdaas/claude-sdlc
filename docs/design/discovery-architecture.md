# `/discovery` + `/architecture` — Design

The upstream phase that turns a fuzzy concept into gated, versioned artifacts,
**before** a repo exists. Tracks Issue #32.

```
/discovery → /architecture → /newproject → /feature → /feature → …
  (what)        (how)         (scaffold)   (build one component at a time)
```

Today the SDLC starts at "scaffold a repo" (`/newproject`) or "add to a repo"
(`/feature`) — both assume the big picture already lives in someone's head.
These two commands make that big picture an explicit input.

## Why (the motivating failure)

Derived from a real 256-page ChatGPT "build a medical AI product" thread. Its
failure mode was the thing we design against:

- The big picture lived in **chat scrollback + screenshots** — no durable
  artifact. The user's only capture tool was periodically asking the AI to
  regenerate a flow diagram and a giant paste-prompt. That reconstruction *is*
  the slop generator.
- Architecture was designed **reactively, mid-build** ("add an Extraction Router
  before the classifier") because no use-case-first pass forced it out early.
- Requirements were **never separated from architecture** — straight to
  boxes-and-arrows, no use-case catalog.
- Validation was **vibes** — "concept match 80–85%", "yes brother, right path".
- The **decision doc the user asked for on day one** ("3–4 options + metrics +
  why I chose") was never produced.

## The thesis

**Every arrow emits a durable, versioned artifact and passes a human gate — or
it decays into chat slop.** Four artifacts, four gates:

| Stage | Artifact | Gate passes when |
|---|---|---|
| Concept | `discovery/concept.md` | non-goals written; every actor named |
| Use cases | `discovery/use-cases.md` | each has priority + "done when"; no orphans |
| Architecture | `architecture/overview.md` + `decisions/` | every UC served; each contested choice has an ADR (options + metric + why) |
| Components | `architecture/components.md` | every feature traces to UC IDs; sequenced by dependency + deferral |

## Two design principles that do the real work

1. **Human is the source of truth; AI structures and challenges.** Not "AI
   drafts, human edits." Artifacts keep the human's prose **verbatim**
   (`In your words:`) separate from **AI distillation** (labeled, approved). This
   gives provenance — you can always tell your requirements from inferred ones —
   which kills the "AI invents a requirement that then gets built" failure.
2. **Traceability = anti-slop.** use case → capability → component/feature → back
   to use case. A feature that can't name the use case it serves does not get
   built. A use case no component serves is flagged as an orphan.

## Terminal artifact: the feature backlog

`/architecture`'s last gate produces `components.md` — a list of **features**
(each sized for one `/feature` run), **traced** to use-case IDs and **sequenced**
by dependency + deferral. That flows into your existing machinery: GitHub Issues
with `Depends on: #N` → `/feature` builds the earliest unblocked one. The medical
thread's hand-rolled, drifting "Sprint 2C…2J" list is exactly this artifact done
without gates or traceability; ours makes it first-class.

## What we build for v1 (prose path)

1. **`payload/skills/sdlc-discovery/SKILL.md`** — shared vocabulary, gate
   definitions, the prose-vs-distillation rule, the traceability rule, artifact
   locations, both gate sequences.
2. **`payload/skills/sdlc-discovery/templates/`** — `concept.md`,
   `use-cases.md`, `decision.md`, `components.md`.
3. **`payload/commands/discovery.md`** + **`payload/commands/architecture.md`** —
   thin gate-walkers over the skill.

## Artifact home & handoff (v1 decision)

Artifacts are plain markdown in a **product workspace** (`discovery/`,
`architecture/`), usually not yet a code repo. `/newproject` later seeds a
scaffolded repo's `design/` from them. **v1 does not hard-wire that handoff** —
it only fixes the locations. Deferral discipline: the first real run tells us how
tight the coupling must be.

## How we validate v1 (proof by running)

Ship v1, then do the **first real `/discovery` run** on an actual concept. The
run's primary output is the artifacts; its **secondary output is the retro** —
"the command should've asked me X / shouldn't have done Y" — which cuts v2. Same
self-hosting loop already used for `/feature`.

## Non-goals (v1)

- No hard-wired `/newproject` handoff (locations only).
- No automatic GitHub-issue creation without approval.
- Not a heavyweight framework (arc42/RUP) — curated artifacts, scaled to the idea.
- No model/token optimization.
