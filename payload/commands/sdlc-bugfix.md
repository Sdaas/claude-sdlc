# /sdlc-bugfix — fix a bug in an existing SDLC repo (reproduce-first)

Triggered by `/sdlc-bugfix "what's wrong"` (or a confirmed natural-language bug
report) in a repo that already follows this SDLC.

**First, load the `sdlc-common` skill** — it defines the tiers, the code vs prose
paths, the governance matrix, and the hard rules referenced below. This command
walks the gate sequence; `sdlc-common` defines what each term means.

**Defining rule:** a failing test **reproduces the bug before** the fix exists.
No fix is written until the bug is demonstrably reproduced (red). Fix the **root
cause**, not the symptom.

**Hard rule (#10):** never commit or push before the developer has reviewed and
approved.

Follow the gates in order. Do not skip or reorder. Announce each gate.

**Checkpoint as you go.** On entering each gate, update the repo-root
`SESSION_STATE.md` (gitignored) per `sdlc-common` §5, and delete it at close-out.
This lets `/sdlc-resume` continue the work if the session ends mid-flight.

---

## Gate 1 — CLASSIFY

Per `sdlc-common` §1–3, state the bug in one sentence and propose:
- **Tier** — the ladder:
  - **Quick** — a genuinely trivial one-line fix (typo, wrong constant). Still
    reproduce-first *if a test is feasible*.
  - **Standard** — most bugs.
  - **Full** — when **any** of these holds: the bug is **security-sensitive** (a
    vulnerability); its root cause is a **design flaw** (the real fix changes a
    component contract/interface); it touches a **shipped/packaged surface**
    (`release.sh`, delivery/`apply.sh`, a published artifact); or it is
    **high-blast-radius** (changes a shared interface, affects many callers, or
    risks data/state migration). Full = Standard + design-review + security-review
    + retrospective.
- **Path** — code (the usual: reproduce with a failing test) or prose (a wrong
  instruction in a doc/command/skill — no red-green; fix → re-verify). Mixed is
  fine; run each file down its own path.
- **Issue** — link the GitHub issue, or create one (`gh issue create`). The issue
  number is the slug. Respect any `Depends on: #N`.
- **Branch** — Quick → `main`; else create **`fix/<slug>`** (from up-to-date
  `main`). Read the repo's `CLAUDE.md` marker to know the stack/profile.

Wait for the developer to confirm the classification before continuing.

## Gate 2 — REPRODUCE & DIAGNOSE

Interview to a reliable reproduction, not just a description:
- **Exact repro** — the inputs, state, and steps that trigger the bug, and the
  observed wrong behavior vs. the expected behavior.
- **Root-cause hypothesis** — *why* it happens, at the right altitude. Name the
  smallest true cause; for a security bug, name the **input class**, not the one
  payload.
- **Escalation check (design flaw).** If the root cause is architectural — the
  honest fix changes a component's contract or an existing decision — **stop**.
  Do not patch at the wrong altitude. Recommend re-running **`/sdlc-architecture`**
  to revise the relevant decision/ADR first, then return and implement the fix under
  **Full** (design-review before coding).
- **Security check.** If the bug is a vulnerability, raise the tier to **Full**
  and treat the reproduction as an **exploit** (see Gate 4).
- **Boundary inventory.** Name the external boundaries in play — network
  services, subprocesses/CLIs, the filesystem, runtime dependencies, the
  user-facing entry point where the symptom appears. If the bug lives at a
  **mocked** boundary, that mock is likely why it shipped: the fix owes a
  non-mocked test there (`sdlc-common` §3) and a VERIFY of the real symptom
  (Gate 5).

Summarize the repro + root cause back to the developer and confirm before fixing.

## Gate 3 — DESIGN (brief)

State the fix approach and any alternatives. Confirm the fix addresses the root
cause named in Gate 2 (not the symptom). For each boundary from the Gate 2
inventory, state **how it will be really exercised** (the non-mocked test and the
VERIFY step). Record only **key** decisions into `design/overview.md` (curated).
Present it; get agreement.
(Full tier: run a design-review pass before proceeding.)

## Gate 4 — IMPLEMENT

**CODE path (reproduce-first):**
1. Write a **failing test that reproduces the bug** — asserting the *correct*
   behavior the bug currently violates. For a security bug, this is an
   **exploit/regression test** that demonstrates the vulnerability. Where
   valuable, write it as an isolated subagent that sees the repro but not the fix.
2. Run `./test.sh` — **confirm red** (show the failure = the bug reproduced).
3. Fix the **root cause** with the minimum change. Match the code's style/dialect.
4. Run `./test.sh` — **confirm green**. The reproducing test **stays** as a
   permanent regression test. Refactor if needed, keeping green.

**PROSE path** (a wrong instruction in a doc/command/skill):
1. Correct the artifact at the root of the confusion, not just the sentence.
2. Self-check against the `sdlc-common` §4 prose checklist, and **re-verify** the
   corrected instruction actually produces the right outcome.

## Gate 5 — VERIFY (observe the real thing)

Green tests are not Done (`sdlc-common` §5). Drive the **real** flow and confirm
the **reported symptom is actually gone** — not just that the regression test is
green. For **every external boundary** in the Gate 2/3 inventory, exercise it
**un-mocked** at least once; if the bug lived at a mocked boundary, this is the
step that would have caught it (use the `verify` / `run` skills).

- **Required** when the bug touches an external service/dependency or a
  user-facing entry point.
- **Skippable only** for a pure-internal or prose fix with no runtime surface
  ("nothing to drive") — and then **state the one-line reason** for skipping.

Not Done until this passes. If the real symptom persists, go back to IMPLEMENT.

## Gate 6 — CODE REVIEW

Two-pass review of the change (prose: checklist review). Confirm no new
regressions and that the root cause — not just the reported symptom — is closed.
Fix findings.

**Full tier — security-review pass:** load the `sdlc-security` skill and run its
pass — invoke the harness `/security-review` on the diff **and** walk the
`sdlc-security` checklist against the Gate 2 boundary inventory (with the matching
profile's security section). Produce **specific findings** in the skill's format,
not "looks fine"; fix HIGH/MED before proceeding.

## Gate 7 — REVIEW GUIDE

Present the changed files, a recommended review order, and one line per file on
why it matters — including **the regression test and the line where the root
cause was fixed**.

## Gate 8 — HUMAN REVIEW (approval gate — rule #10)

Wait for the developer to review and approve. Do not proceed to commit until
approved. Address any requested changes and re-present.

## Gate 9 — COMMIT & PUSH

After approval:
- Commit with a clear message referencing the issue (state the root cause fixed).
- Push. The pre-push hook runs `./test.sh`; it must pass.
- Open a PR if the repo uses them; merge only with green CI and approval.

## Gate 10 — CLOSE OUT

- Close (or update) the GitHub issue (note the root cause and the regression test).
- Full tier: run a short retrospective (`/sdlc-retrospective`) and record lessons.

---

## Rules

- **Reproduce before you fix.** No fix without a red test first (code path),
  when a test is feasible.
- **Fix the root cause, not the symptom.** If the root cause is a design flaw,
  escalate to `/sdlc-architecture` — do not bandaid.
- Review before commit (#10) — every tier, including Quick.
- Trivial → `main`; everything else → `fix/<slug>`.
- Tests green before push and merge; all via `./test.sh`.
- **Not Done on green tests alone** — VERIFY the real symptom is gone, and
  exercise every external boundary un-mocked once (`sdlc-common` §3, §5). A green
  regression test against a mock is exactly the failure that ships bugs.
- If the report is vague, get a reliable repro before starting — do not guess.
