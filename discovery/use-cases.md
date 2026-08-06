# Use-Case Catalog — Profile Skills

> Produced by `/sdlc-discovery`. Each use case is something an actor must be able
> to *do*. Gate: every use case has a priority and a testable "done when"; each
> traces to an actor; no orphans. Architecture will trace components back to
> these IDs — keep the IDs stable.
>
> **Provenance:** UC-001…UC-008 were AI-proposed and human-approved ("your
> proposal is good"). UC-009 and UC-010 were added by the human (verbatim in
> each). Priorities below are the approved set.

## Priority legend

- **P0** — core; the initiative is pointless without it.
- **P1** — important; shipped soon after core.
- **P2** — later / deferred (peripheral after core).

## Actor key

**Agent** = the SDLC agent walking a command's gates · **Dev** = the developer ·
**`/sdlc-feature` · `/sdlc-newproject` · `/sdlc-harden`** = SDLC commands that
consume a profile. (All named in `concept.md` Actors.)

---

## UC-001 — Build a component to the profile's standard

- **Actor:** Agent (via `/sdlc-feature` IMPLEMENT) · **Priority:** P0
- **Trigger:** Building a component in stack S (shell / python / sql / frontend).

**Main flow (distilled):**
1. Agent loads `profile-<S>` and reads its **best-practice** standard.
2. Writes code that follows it; runs the profile's **lint/format tooling**.

- **Pre:** `profile-<S>` exists with a best-practice standard + named linter.
- **Post:** the component conforms; the standard followed is citable.
- **Done when:** code passes the profile's lint/format, and the agent can name
  the specific standard(s) it applied (not "looks idiomatic").

---

## UC-002 — Test a component to the pyramid

- **Actor:** Agent (tdd / VERIFY) · **Priority:** P0
- **Trigger:** A component needs tests.

**Main flow (distilled):**
1. `profile-<S>` defines the **unit / integration / e2e** expectations and the
   test runner for the stack.
2. Agent writes tests at each applicable level; runs them via `./test.sh`.

- **Pre:** profile defines test levels + runner for stack S.
- **Post:** the component has the profile's required test levels, all green.
- **Done when:** required levels exist and run via `test.sh`; each external
  boundary is exercised **un-mocked** at least once (`sdlc-common` §3).

---

## UC-003 — Security-review a change against the profile

- **Actor:** Agent (security-review gate) · **Priority:** P0
- **Trigger:** Full-tier security-review pass on a change in stack S.

**Main flow (distilled):**
1. Agent runs the profile's **security tooling** and walks its **security
   checklist** (the `sdlc-security` delegation from #60).

- **Pre:** `profile-<S>` has a `## Security checklist` + named tool.
- **Post:** specific findings (severity · boundary → fix) or a named-safe result.
- **Done when:** the pass yields specific findings, not "looks fine".
  *(Folds in the in-flight per-profile security issues #84 / #85 / #86.)*

---

## UC-004 — Check a component for performance & scalability

- **Actor:** Agent (code-review / VERIFY) · **Priority:** P1
- **Trigger:** A component has a perf/scale-sensitive path.

**Main flow (distilled):**
1. `profile-<S>` names the stack's **perf/scale signals + tooling** (e.g. a
   profiler, SQL `EXPLAIN`/index checks, frontend bundle-size/render budget,
   shell process/loop cost).
2. Agent evaluates the component against them.

- **Pre:** profile defines checkable perf signals (the hard open question).
- **Post:** perf/scale risks are surfaced or explicitly cleared.
- **Done when:** the agent can name a concrete perf/scale risk **or** state
  "none, checked against <signal>" — citing the profile's signal, not a vibe.

---

## UC-005 — Scaffold a new repo from the profile

- **Actor:** `/sdlc-newproject` · **Priority:** P1
- **Trigger:** Starting a new repo in stack S.

**Main flow (distilled):**
1. `/sdlc-newproject` seeds the repo with the profile's standards and, for
   **shell / python only**, its **scaffolding templates**.

- **Pre:** profile carries standards; shell/python profiles carry templates.
- **Post:** the new repo is born compliant with the profile.
- **Done when:** a freshly scaffolded repo passes its own profile's checks with
  no hand-holding. *(Non-goal: not replacing existing `templates/`.)*

---

## UC-006 — Harden an existing repo against the profile

- **Actor:** `/sdlc-harden` · **Priority:** P1
- **Trigger:** Auditing an existing repo in stack S.

**Main flow (distilled):**
1. `/sdlc-harden` audits the repo against the profile's **five dimensions** and
   reports gaps in its categorized report.

- **Pre:** profile defines the five-dimension standard.
- **Post:** gaps are reported against concrete profile standards.
- **Done when:** the gap report cites the profile's standards across all four
  dimensions. *(Security consumer wiring already tracked as #87.)*

---

## UC-007 — Test a cross-component (cross-language) boundary

- **Actor:** Agent + Dev · **Priority:** P0
- **Trigger:** A component in stack X calls/consumes a component in stack Y.

**Main flow (distilled):**
1. The interacting boundary gets a **contract / integration test** (the core
   motivation: components are written in a mix of stacks and interact).
2. An **e2e path** exercises the X→Y flow across the app.

- **Pre:** both components exist; the boundary is in the boundary inventory.
- **Post:** the boundary is covered by a real (non-mocked) test + an e2e path.
- **Done when:** the X→Y boundary has a non-mocked contract/integration test and
  an e2e path exercises it. *(This is a **cross-profile** concern, not owned by
  any single profile — architecture must decide where it lives.)*

---

## UC-008 — Read the profile to know the standard

- **Actor:** Dev · **Priority:** P2
- **Trigger:** Developer wants to know the bar for stack S.

**Main flow (distilled):**
1. Dev reads `profile-<S>` and understands the standard without asking.

- **Done when:** a new reader can act correctly from the profile alone (the
  `sdlc-common` §4 prose bar).

---

## UC-009 — Apply a standardized observability & logging policy per profile

- **Actor:** Agent (IMPLEMENT / code-review) · **Priority:** P1
- **Trigger:** Building or reviewing a component in stack S.

**In your words:**
> each profile should have a standardized observability and logging policy

**Main flow (distilled):**
1. `profile-<S>` carries the stack's rendering of the shared **logging policy**
   (`design/logging-policy.md`, #24 — leveled logging, stderr for logs / stdout
   for data, ISO-8601 UTC) **plus** stack-specific observability (e.g. structured
   logs, request/trace context, metrics hooks where applicable).
2. Agent writes/reviews the component against it.

- **Pre:** the shared logging policy exists (#24); profile extends it for stack S.
- **Post:** the component follows the profile's observability/logging standard.
- **Done when:** the component conforms to the profile's logging/observability
  standard and the agent can verify it against a named check.

---

## UC-010 — Build a component to be reliable & resilient

- **Actor:** Agent (IMPLEMENT / code-review) · **Priority:** P1
- **Trigger:** Building or reviewing a component in stack S, especially one that
  depends on external tools/services.

**In your words:**
> we also want each profile to have reliable and resilence code. Eg. shell
> scripts shoud check dependencies, code should check for null objects, if code
> makes an API call that fails/times out then an exponential backoff and retry
> should be done, etc

**Main flow (distilled):**
1. `profile-<S>` defines the stack's **reliability & resilience** standard —
   e.g. **dependency/precondition checks** (shell: required tools present),
   **null/empty-object safety**, and **retry with exponential backoff + timeout**
   on external calls that can fail/hang.
2. Agent writes/reviews the component against it (and, where testable, adds a
   test that exercises the failure path — ties to UC-002/UC-007).

- **Pre:** profile defines the reliability standard + any named tooling for stack S.
- **Post:** the component degrades gracefully on dependency/null/timeout faults.
- **Done when:** the agent can point to the reliability standard the component
  satisfies (dependency check present · null-safe · failing external call retried
  with backoff+timeout) **or** state why a given check does not apply.

---

## Traceability note

No orphan actors: every actor in `concept.md` appears above (Agent: UC-001-004,
007, 009, 010; Dev: UC-007-008; `/sdlc-feature`: UC-001-004, 009, 010 via the
agent; `/sdlc-newproject`: UC-005; `/sdlc-harden`: UC-006). Architecture
(`components.md`) will trace each backlog feature back to these IDs.
