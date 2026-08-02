# /feature — add a capability to an existing SDLC repo

Triggered by `/feature "description"` (or a confirmed natural-language feature
request) in a repo that already follows this SDLC.

**First, load the `sdlc-common` skill** — it defines the tiers, the code vs prose
paths, the governance matrix, and the hard rules referenced below. This command
walks the gate sequence; `sdlc-common` defines what each term means.

**Hard rule (#10):** never commit or push before the developer has reviewed and
approved.

Follow the gates in order. Do not skip or reorder. Announce each gate.

**Checkpoint as you go.** On entering each gate, update the repo-root
`SESSION_STATE.md` (gitignored) per `sdlc-common` §5, and delete it at close-out.
This lets `/sdlc-resume` continue the work if the session ends mid-flight.

---

## Gate 1 — CLASSIFY

Per `sdlc-common` §1–3, state the feature in one sentence and propose:
- **Tier** — Quick / Standard / Full.
- **Path** — code / prose (or mixed; run each file down its own path).
- **Issue** — link the GitHub issue, or create one (`gh issue create`). The
  issue number is the slug. Respect any `Depends on: #N`.
- **Branch** — Quick → `main`; else create `feature/<slug>` (from up-to-date
  `main`). Read the repo's `CLAUDE.md` marker to know the stack/profile.

Wait for the developer to confirm the classification before continuing.

## Gate 2 — INTERVIEW

Interview to full clarity. Cover: the goal, inputs/outputs, edge cases, error
handling, constraints (security/performance/scale), and **acceptance criteria**
("done when…"). For a prose change, pin down intent, scope, and audience.
Do not assume — ask. Summarize back and confirm.

## Gate 3 — DESIGN (brief)

State the approach and any alternatives considered. Record only the **key**
decisions into `design/overview.md` (curated). Present it; get agreement.
(Full tier: run a design-review pass before proceeding.)

## Gate 4 — IMPLEMENT

**CODE path:**
1. Write the failing test(s) first (via the repo's test framework). Where
   valuable, write them as an isolated subagent that sees the requirements but
   not the implementation plan.
2. Run `./test.sh` — **confirm red** (show the failure).
3. Implement the minimum to pass. Match the existing code's style/dialect.
4. Run `./test.sh` — **confirm green**. Refactor if needed, keeping green.

**PROSE path:**
1. Draft the artifact.
2. Self-check against the `sdlc-common` §4 prose checklist.

## Gate 5 — CODE REVIEW

Two-pass review of the change (prose: checklist review). Fix findings.
(Full tier: also a security-review pass.)

## Gate 6 — REVIEW GUIDE

Present the changed files, a recommended review order, and one line per file on
why it matters / where the key change is.

## Gate 7 — HUMAN REVIEW (approval gate — rule #10)

Wait for the developer to review and approve. Do not proceed to commit until
approved. Address any requested changes and re-present.

## Gate 8 — COMMIT & PUSH

After approval:
- Commit with a clear message referencing the issue.
- Push. The pre-push hook runs `./test.sh`; it must pass.
- Open a PR if the repo uses them; merge only with green CI and approval.

## Gate 9 — CLOSE OUT

- Close (or update) the GitHub issue.
- Full tier: run a short retrospective (`/retrospective`) and record lessons.

---

## Rules

- Review before commit (#10) — every tier, including Quick.
- Trivial → `main`; everything else → its own branch.
- Tests green before push and merge; all via `./test.sh`.
- If the description is ambiguous, ask before starting — do not guess scope.
