# /sdlc-discovery — turn a fuzzy concept into gated requirements

Triggered by `/sdlc-discovery "one-line idea"` (or a confirmed natural-language
request to figure out *what* to build) at the idea stage — **before** a repo
exists. Produces the concept brief and use-case catalog that `/sdlc-architecture`
then consumes.

**First, load the `sdlc-discovery` skill** — it defines the artifacts, the
gates, the human-prose-vs-AI-distillation rule (§1), the traceability rule (§2),
and where artifacts live (§0). This command walks the gate sequence; the skill
defines what each term means.

**Prime rule (§1):** the human is the source of domain truth; you **interview,
structure, and challenge** — you do not author requirements. Keep the human's
prose verbatim under `In your words:`; label everything you infer as AI
distillation for approval.

**Hard rule (#10, from `sdlc-common`):** never write a final artifact past its
gate without the human's approval.

Follow the gates in order. Announce each gate. Do not skip or reorder.

**Checkpoint as you go.** On entering each gate, update a `SESSION_STATE.md`
(gitignored) in the workspace directory per the `sdlc-common` §5 convention, and
delete it at close-out — so `/sdlc-resume` can continue if the session ends
mid-flight.

---

## Gate 1 — FRAME

State the concept in one sentence. Confirm we are in discovery (idea stage, not
yet a code repo). Agree the **workspace directory** where `discovery/` artifacts
will be written. Wait for confirmation.

## Gate 2 — INTERVIEW · concept

Interview for: the **problem**, the **actors**, the **value proposition**, the
**scope boundary**, and — non-negotiable — the **non-goals**. Do not assume; ask.
Challenge for missing non-goals and unnamed actors. Capture the human's answers
as verbatim prose where they give it. Summarize back and confirm.

## Gate 3 — CONCEPT BRIEF

Write `discovery/concept.md` from the skill's `concept.md` template — verbatim
`In your words:` blocks plus your labeled distillation. Present it and pass the
**concept gate** (skill §3): non-goals written, every actor named, one-sentence
"what" agreed. If non-goals are empty, discovery is not done.

## Gate 4 — INTERVIEW · use cases

Per actor, elicit what they must be able to *do*. For each use case pin down:
trigger, main flow, pre/post-conditions, **priority** (P0/P1/P2), and a testable
**"done when"**. Accept free-form prose where the human gives it; distill beside
it. Flag any actor with no use case, and any use case with no clear actor.

## Gate 5 — USE-CASE CATALOG

Write `discovery/use-cases.md` from the template, with stable `UC-NNN` IDs
(architecture will trace back to these). Present it and pass the **use-case
gate** (skill §3): every use case has a priority and a "done when"; each traces
to an actor; no orphans.

## Gate 6 — HUMAN REVIEW & HANDOFF

Present both artifacts with a short review guide (what to read, in what order).
Wait for approval. On approval, point the human at `/sdlc-architecture` (which
requires these two artifacts to exist and be approved).

---

## Rules

- Interview and challenge — never invent requirements (§1). Everything is either
  "user said this" or "AI proposes — approve?".
- Non-goals are a gate requirement, not optional.
- Keep artifacts curated, not exhaustive; scale effort to the idea (§6).
- If the idea is too vague to name an actor, keep interviewing — do not jump to
  writing the brief.
