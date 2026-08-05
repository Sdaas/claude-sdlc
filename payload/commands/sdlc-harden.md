# /sdlc-harden — bring an existing repo up to SDLC standards (gap analysis)

Triggered by `/sdlc-harden` (or a confirmed natural-language request to audit,
harden, modernize, or "bring up to standard" an existing repo) in a repo that was
built outside this SDLC, or built earlier and left behind as it evolved.

**First, load the `sdlc-common` skill AND the `sdlc-harden` skill** — `sdlc-common`
defines the tiers, code vs prose paths, governance, and hard rules; `sdlc-harden`
defines the standards checklist, the gap taxonomy, the two modes, the safety-net
cardinal rule, the hybrid close mechanism, and profile delegation. This command
walks the gate sequence; those skills define what each term means.

**Cardinal rule:** never refactor code that has no tests. Pin current behavior
with characterization tests (green on untouched code) **before** any
behavior-touching fix (`sdlc-harden` cardinal rule).

**Hard rule (#10):** never commit or push before the developer has reviewed and
approved.

Follow the gates in order. Do not skip or reorder. Announce each gate.

**Checkpoint as you go.** On entering each gate, update the repo-root
`SESSION_STATE.md` (gitignored) per `sdlc-common` §5, and delete it at close-out.
This lets `/sdlc-resume` continue the work if the session ends mid-flight.

---

## Gate 1 — CLASSIFY

Per `sdlc-common` §1–3 and `sdlc-harden` §1–2, state the target in one sentence
and propose:
- **Stack/profile** — read the repo's `CLAUDE.md` marker; if absent, infer the
  stack and **propose** a profile (`sdlc-harden` §7). This picks the concrete
  checklist.
- **Mode** — **audit** (default: safety net + infra + report, no logic edits) or
  **apply** (opt-in: also the guided close loop). `sdlc-harden` §1.
- **Tier** — Quick / Standard / Full — how much process wraps the work. **A
  shipped/packaged or security-sensitive target is Full.** Mode and tier are
  independent knobs (`sdlc-harden` §2).
- **Scope** — which directories/areas are in scope; anything explicitly
  off-limits ("don't touch this").
- **Issue + branch** — link or create the tracking issue; the number is the slug.
  Quick → `main`; else create `harden/<slug>` from up-to-date `main`.

Wait for the developer to confirm mode, tier, scope, and profile before continuing.

## Gate 2 — INVENTORY

Scan the repo and report **what SDLC scaffolding already exists** — tests, a
single `./test.sh`, CI, a pre-push hook, a standard README, `design/`, the
logging policy, backlog discipline. Fill the inventory table in
`sdlc-harden/templates/gap-report.md`. This is read-only; do not change anything
yet. Present the inventory.

## Gate 3 — SAFETY NET

The **cardinal rule** (`sdlc-harden`): before any behavior-touching fix, pin the
current behavior of the in-scope code with **characterization tests** (pass-now,
not fail-first) wired through a single `./test.sh`, and confirm **green on the
untouched code**. A characterization test that fails on unchanged code is
mis-written — fix it. **Block** any behavior-changing work until this net exists.
(Skippable only if the run proposes no behavior-touching fixes — state that.)

## Gate 4 — GAP REPORT

Audit each in-scope area against the standards checklist (`sdlc-harden` §3),
using the matching **profile's** concrete checks (§5/§7 — for shell, delegate to
the `harden-shell-repo` skill's deep checklist). Produce the **categorized**
report per the taxonomy (`sdlc-harden` §4): grouped by the four **areas**, each
finding tagged with its **risk class** (infra-doc / behavior-preserving /
behavior-changing) and a rough effort. Present the report.

## Gate 5 — PRIORITIZE (human-in-the-loop)

Walk the report with the developer. For each gap, record a decision: **close**,
**defer**, or **drop**. Then **file GitHub issues** for the **close + defer** set
only (report-first, not one-issue-per-raw-gap — `sdlc-harden` §6). If the repo is
not a git repo or `gh` is unavailable, write the report to a file and state why
(graceful degradation). Confirm the prioritized plan before closing anything.

## Gate 6 — CLOSE (hybrid)

Per `sdlc-harden` §5:
- **Infra-doc gaps → fix in-harden in both modes** (runner, hooks, CI, docs,
  characterization tests — no existing behavior changes).
- **Behavior-preserving + behavior-changing gaps → fix in-harden, apply mode
  only.** One **category at a time** under the green `./test.sh`: apply → re-run →
  green keeps it; red means behavior changed (with the human: intended → update
  the pinned test; regression → revert). **Behavior-changing** categories also
  need explicit **per-category sign-off** first.
- **Behavior / logic gaps → escalate** to `/sdlc-feature` (new capability) or
  `/sdlc-bugfix` (defect) via the filed issue — harden does not patch product
  logic itself.

**Audit mode stops here** once the safety net + agreed infra-doc gaps are closed:
deliver the final report and go to VERIFY. **Apply mode** additionally runs the
code-editing close loop above.

## Gate 7 — VERIFY (observe the real thing)

Green tests are not Done (`sdlc-common` §5). Drive the **real** repo flow and
confirm each acceptance criterion against observed behavior (use the `verify` /
`run` skills): `./test.sh` actually runs green; the pre-push hook fires; CI is
present and valid; issues were filed for the agreed set (or the degradation
reason is stated). For **every external boundary** touched (the target's own
runtime surface, plus this workflow's `gh`/git/filesystem/`./test.sh` use),
exercise it **un-mocked** at least once. Not Done until this passes; a defect
sends you back to CLOSE.

## Gate 8 — CODE REVIEW

Two-pass review of the change (`sdlc-common`): inline checklist then
`/code-review`. Confirm every in-harden change was covered by the safety net and
each behavior delta was intentional and signed off. Fix findings; loop back if a
defect surfaces. (Full tier: also a **security-review** pass.)

## Gate 9 — REVIEW GUIDE → HUMAN REVIEW → COMMIT & PUSH

- **Review guide** — list the changed files, a recommended review order, and one
  line each on why the file matters / where the key change is.
- **Human review (rule #10)** — wait for approval. Do not commit before it.
  Address requested changes and re-present.
- **Commit & push** — after approval, commit (referencing the relevant issue(s));
  push. The pre-push hook runs `./test.sh`; it must pass. Open a PR if the repo
  uses them; merge only with green CI and approval.

## Gate 10 — CLOSE OUT

- Update/close the GitHub issues for the gaps that were closed; leave the
  **deferred** issues open with their context; note **dropped** gaps in the
  report.
- Delete `SESSION_STATE.md`; the durable summary goes to the backlog / a report.
- Full tier: run a short retrospective (`/sdlc-retrospective`) and record lessons.

---

## Rules

- **Never refactor untested code** — pin behavior first (cardinal rule).
- **Audit is the default; apply is opt-in.** Mode ≠ tier (`sdlc-harden` §2).
- **Report first, then file issues** for the agreed close + defer set only —
  never one issue per raw gap.
- **Hybrid close** — infra/doc/behavior-preserving in-harden (category-at-a-time
  under green tests); behavior/logic escalates to `/sdlc-feature` / `/sdlc-bugfix`.
- **Delegate the stack checklist to the profile** — for shell, to
  `harden-shell-repo`; flag "no deep checklist yet" rather than inventing one.
- Review before commit (#10) — every tier. Trivial → `main`; else `harden/<slug>`.
- **Not Done on green tests alone** — VERIFY the real flow (`sdlc-common` §5).
- If the request is vague about scope or mode, ask before starting — do not guess.
