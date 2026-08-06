# Concept — Profile Skills (first-class stack profiles)

> Produced by `/sdlc-discovery`. Curated, not exhaustive. Keep it to one page.
> `In your words:` blocks are the human's verbatim ground truth — never
> overwrite them. Everything else is AI distillation, subject to approval.
>
> **Adaptation note:** this initiative enhances the **existing** `claude-sdlc`
> repo (it is not greenfield). Discovery's *method* applies; artifacts live
> in-repo (`discovery/` → `architecture/` → GitHub issues).

## One-sentence what

Elevate the SDLC's stack **profiles** (shell · python · sql · frontend) from
template bundles into first-class **profile skills**, each defining checkable
standards for **best practices, performance & scalability, the testing pyramid
(unit / integration / e2e), and security** — plus the **cross-profile** concern
of testing components that interact across languages.

## Problem

**In your words:**
> *(Q1 — endorsed the AI framing verbatim: "you got it right.")*

**Distilled (confirmed by the human):** When `/sdlc-feature` builds a component in
python, sql, shell, or frontend, the agent leans on generic language knowledge
with no **repo-blessed standard** for that stack. Quality, performance, test
depth, and security therefore vary with the agent's improvisation, and there is
**no consistent bar across a multi-language app** whose components interact. The
profiles exist as template bundles (+ a thin security stub from #60) but carry no
standards an agent can be held to.

## Actors

*(Q2 — human endorsed the AI framing verbatim: "you got it right.")* The
"users" of a profile skill are mostly **non-human**: agents and commands.

| Actor | Role / why they touch the system |
|---|---|
| **SDLC agent** | Primary consumer — reads the profile skill during IMPLEMENT / VERIFY / code-review / security-review to write and check stack-appropriate code. |
| **Developer (you)** | Reads the profile to know the standard; approves at gates. |
| **`/sdlc-feature`** | Builds one component at a time *against* the profile's standards. |
| **`/sdlc-newproject`** | Scaffolds a new repo *from* the profile (templates + standards). |
| **`/sdlc-harden`** | Audits an existing repo *against* the profile's standards (security section already wired via #87). |

## Value proposition

**In your words:**
> *(Q3 — endorsed the AI framing: "your framing is ok.")*

**Distilled (confirmed):** A component built via `/sdlc-feature` in **any** of the
four stacks comes out idiomatic, performance-conscious, tested at every pyramid
level, and secure — **without the developer hand-holding each time** — and a
multi-language app holds one consistent quality bar across its interacting parts.

## Scope boundary

Each profile skill owns **five quality dimensions**:

1. **Best practices** — language idioms, layout, lint/format conventions.
2. **Performance & scalability** — checkable perf/scale signals per stack.
3. **Testing pyramid** — unit / integration / e2e.
4. **Security** — the `sdlc-security`-delegated checklist (#60).
5. **Reliability & resilience** — fault-tolerance: dependency checks,
   null/empty-object safety, retry/backoff/timeout on failing external calls.

Each dimension is expressed as up to **three kinds of content**:

- **(a) Prose standards / checklists** the agent reasons against — **all four
  profiles.**
- **(b) Named runnable tooling** (linters, profilers, scanners, test runners) —
  **all four profiles.**
- **(c) Scaffolding templates** — **shell and python only.**

**In your words (Q4, verbatim — the (a)/(b)/(c) refer to content-kinds above):**
> Definitely (a) and (b). The (c) may make sense for shell scripts, and python
> script/libraries, but its difficult to do it for front-end and sql. So do (c)
> only for shell scripts, and python scrips + modules/libraries.

**In your words (reliability & resilience — dimension 5, verbatim):**
> we also want each profile to have reliable and resilence code. Eg. shell
> scripts shoud check dependencies, code should check for null objects, if code
> makes an API call that fails/times out then an exponential backoff and retry
> should be done, etc

**In scope (now):**
- All **four** profiles as first-class skills — **SQL is a full peer in v1**
  (greenfield: new `profile-sql`, changes its current "out of scope" status).
- The **five dimensions** above, each with content-kinds (a)+(b), plus (c) for
  shell & python.
- A **cross-profile** concern: contract/integration/e2e testing at the boundaries
  where components in different stacks interact (ties to the boundary inventory
  in `sdlc-common`).
- This initiative **produces the concept + architecture + a sequenced backlog**;
  it does not build the skills here (see non-goals).

**Non-goals (explicitly NOT building):**
- **Discovery ends at a backlog.** The actual profile-skill building happens
  later via `/sdlc-feature`, one profile at a time. This initiative delivers the
  gated artifacts and the sequenced issue backlog, not the finished skills.
- **Do not replace `templates/`.** Profile skills sit alongside the existing
  scaffolding template dirs; we do not remove or rewrite them.
- **No CI / infra overhaul.** Not redesigning CI, release, or the harness;
  profiles assume the runtimes/CI that already exist.
- **Do not absorb the shipped shell skills.** `zsh-script`, `harden-shell-repo`,
  `add-shell-feature`, `fix-shell-bug` keep working standalone; `profile-shell`
  **references** them rather than swallowing them now.

## Open questions

- **What makes "performance & scalability" *checkable*** per stack? (The hardest
  dimension — architecture must define concrete signals/tooling, not vibes.)
- **How is cross-language e2e actually driven** in a repo spanning four stacks?
  (One `test.sh`? A dedicated e2e lane? Resolve in `/sdlc-architecture`.)
- **Relationship of (c) scaffolding to existing `templates/`** and to
  `/sdlc-newproject` — extend vs. reference (resolve in architecture).
- Folds in existing open issues #84/#85/#86 (per-profile security) as the
  security dimension of each profile.
