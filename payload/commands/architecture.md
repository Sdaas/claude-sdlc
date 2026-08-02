# /architecture — turn requirements into a structured, sequenced plan

Triggered by `/architecture` in a product workspace where `/discovery` has
already produced an approved concept brief and use-case catalog. Produces the
capability map, the C4-ish container diagram, the decision records, and the
**feature backlog** that `/feature` builds one item at a time.

**First, load the `sdlc-discovery` skill** — it defines the artifacts, the gates,
the traceability rule (§2), and the handoff to GitHub Issues (§5). This command
walks the gate sequence; the skill defines what each term means.

**Precondition:** `discovery/concept.md` and `discovery/use-cases.md` exist and
are gate-approved. If not, stop and point the human at `/discovery`.

**Prime rule (§1):** the human still owns the domain truth. Any capability or
component you propose that no use case demands must be surfaced as "AI proposes —
approve?", not silently added.

**Hard rule (#10):** never finalize an artifact past its gate without approval.

Follow the gates in order. Announce each gate. Do not skip or reorder.

**Checkpoint as you go.** On entering each gate, update a `SESSION_STATE.md`
(gitignored) in the workspace directory per the `sdlc-common` §5 convention, and
delete it at close-out — so `/sdlc-resume` can continue if the session ends
mid-flight.

---

## Gate 1 — CAPABILITY MAP

Read the use-case catalog. Derive the capabilities the system needs; each names
the **use-case ID(s)** it serves (skill §2). Any capability not demanded by a use
case is flagged "AI proposes — approve?". Present the map; confirm.

## Gate 2 — STRUCTURE

Group capabilities into components. Draw a C4-ish container diagram (mermaid or
text) showing components, connections, and boundaries. Begin
`architecture/overview.md`. Pass the **architecture gate** (skill §3): every use
case served by ≥1 capability; nothing floats.

## Gate 3 — DECISIONS (ADRs)

For each **contested** choice (stack, storage, sync vs async, build vs buy, which
engine), write `architecture/decisions/NNNN-*.md` from the `decision.md`
template: 3–4 options, a named **comparison metric**, the pick, the one-line why.
Skip choices with an obvious answer. This is the "why I chose what" record.

## Gate 4 — FEATURE BACKLOG

Decompose into features sized for one `/feature` run. Write
`architecture/components.md` from the template: each feature **traced** to
use-case IDs, **sequenced** by dependency + deferral discipline, with a written
**sequencing rationale**. Pass the **backlog gate** (skill §3): no floating
features; core before peripheral.

## Gate 5 — HUMAN REVIEW

Present overview + ADRs + backlog with a short review guide. Wait for approval.
Address changes and re-present. Do not hand off unapproved.

## Gate 6 — HANDOFF

On approval, optionally create **GitHub Issues** from the P0 backlog with
`Depends on: #N` lines (backlog = GitHub Issues, `sdlc-common` §5). Update
`PROGRESS.md`/the board. Next step for the human: `/newproject` to scaffold, then
`/feature` on the earliest unblocked P0.

---

## Rules

- Traceability is mandatory (§2): a feature that can't name its use case is
  dropped or sent back to `/discovery` — it does not get built.
- Every contested decision gets an ADR with a metric; a decision without a metric
  is just a preference.
- Sequence by real dependencies + deferral, and write the rationale down — this
  is the part that was pure vibes before.
- Keep it curated; scale to the idea (§6).
