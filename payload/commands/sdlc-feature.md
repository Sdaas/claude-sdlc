# /sdlc-feature — add a capability to an existing SDLC repo

Triggered by `/sdlc-feature "description"` (or a confirmed natural-language
feature request) in a repo that already follows this SDLC.

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

**Boundary inventory.** Enumerate the external boundaries this feature touches —
network services, subprocesses/CLIs, the filesystem, runtime dependencies, and
any user-facing entry point. This list drives the VERIFY gate (Gate 5) and the
mock-obligation rule (`sdlc-common` §3). If there are none, say so.

## Gate 3 — DESIGN (brief)

State the approach and any alternatives considered. Record only the **key**
decisions into `design/overview.md` (curated). For each boundary from the Gate 2
inventory, state **how it will be really exercised** (the non-mocked test and the
VERIFY step). Present it; get agreement.
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

## Gate 5 — VERIFY (observe the real thing)

Green tests are not Done (`sdlc-common` §5). Drive the **real** user-facing flow
once and confirm **each Gate 2 acceptance criterion** against observed behavior
(use the `verify` / `run` skills). For **every external boundary** in the Gate 2/3
inventory, exercise it **un-mocked** at least once — a mocked test only proved the
mock.

- **Required** when the change touches an external service/dependency or a
  user-facing entry point.
- **Skippable only** for a pure-internal or prose change with no runtime surface
  ("nothing to drive") — and then you must **state the one-line reason** for
  skipping (e.g. "no runtime surface: prose-only change").

Not Done until this passes. If VERIFY surfaces a defect, go back to IMPLEMENT.

## Gate 6 — CODE REVIEW

Two-pass review of the change (prose: checklist review). Fix findings.
(Full tier: also a security-review pass.)

## Gate 7 — REVIEW GUIDE

Present the changed files, a recommended review order, and one line per file on
why it matters / where the key change is.

## Gate 8 — HUMAN REVIEW (approval gate — rule #10)

Wait for the developer to review and approve. Do not proceed to commit until
approved. Address any requested changes and re-present.

## Gate 9 — COMMIT & PUSH

After approval:
- Commit with a clear message referencing the issue.
- Push. The pre-push hook runs `./test.sh`; it must pass.
- Open a PR if the repo uses them; merge only with green CI and approval.

## Gate 10 — CLOSE OUT

- Close (or update) the GitHub issue.
- Full tier: run a short retrospective (`/sdlc-retrospective`) and record lessons.

---

## Rules

- Review before commit (#10) — every tier, including Quick.
- Trivial → `main`; everything else → its own branch.
- Tests green before push and merge; all via `./test.sh`.
- **Not Done on green tests alone** — VERIFY the real flow, and exercise every
  external boundary un-mocked once (`sdlc-common` §3, §5). Skip only with a
  stated reason when there's no runtime surface.
- If the description is ambiguous, ask before starting — do not guess scope.
