# /sdlc-retrospective — reflect on a change or a session, and record the lessons

Triggered by `/sdlc-retrospective feature`, `/sdlc-retrospective session`, or
bare `/sdlc-retrospective`. Runs a short, gated reflection into a **transient**
working retro (`RETRO.md` at the repo root, mirroring `SESSION_STATE.md`), routes
its findings to their durable homes, then **deletes** it. A retro is a working
artifact, not an archive — the value is the routed outputs, which live elsewhere.

**First, load the `sdlc-common` skill** — it defines the governance matrix and
the hard conventions (backlog = GitHub Issues, review before commit, the
transient/durable split of decision #7) this command respects.

**This command reflects, routes, and points — nothing more.** It does not branch,
fix, run other gates, or commit. Its outputs route to two durable destinations
(never a permanent retro doc):

- **Action items** ("do X") → **GitHub issues** (the backlog).
- **Durable principles** ("from now on always Y") → **`design/overview.md`**
  decisions, or **`sdlc-common`** when the principle is about the SDLC process
  itself (not a work item, so never an issue).

**Cardinal rule: routing must be complete before deletion.** The transient
`RETRO.md` is deleted only after every finding has landed in its durable home —
deletion is irreversible (the retro is never committed). Deletion happens at
**close-out**: the surrounding `/sdlc-feature` / `/sdlc-bugfix` close-out removes
`RETRO.md` (like `SESSION_STATE.md`); when this command is run **standalone**
(no owning workflow), it deletes `RETRO.md` itself at the end.

**Two modes:**

| Mode | Lens | Working retro |
|---|---|---|
| **feature** | The change just shipped — outcome vs. acceptance criteria, what went well, friction, lessons. Usually invoked at Full-tier close-out, or ad hoc. | `RETRO.md` |
| **session** | The work *session*, with an SDLC-improvement lens — what went wrong → which gate/command caused friction → how to improve the workflow. | `RETRO.md` |

---

## Mode select

Parse the argument:
- `feature` or `session` → use that mode.
- **No argument** → infer from context: an in-flight or just-closed change
  (`SESSION_STATE.md`, a recent close-out, the current `feature/` or `fix/`
  branch) suggests **feature**; a standalone reflection suggests **session**.
  **State the inferred mode and confirm** before proceeding — do not guess
  silently.

## Gate 1 — SCOPE

Establish the subject and gather context (read-only):
- **feature mode:** identify the change — the issue number (the slug), the branch,
  and what shipped. Read the issue, the diff/`git log` for the branch, and any
  `SESSION_STATE.md`.
- **session mode:** identify the session's timeframe and what it covered. Read
  `PROGRESS.md`, recent `git log`, and `SESSION_STATE.md`.

Summarize the scope back in one or two lines so the human can correct it.

## Gate 2 — REFLECT (interview)

Ask the human — do not fill answers in yourself. Keep it short.

**feature mode:**
- Did the result meet each **acceptance criterion**? Anything still open?
- What went **well** (worth repeating)?
- What caused **friction** (rework, confusion, a gate that fought you)?
- Any **surprises** — assumptions that proved wrong?

**session mode:**
- What **went wrong** or slowed the session down?
- **Which gate or command** was involved (e.g. INTERVIEW too thin, VERIFY
  skipped, a command missing a step)?
- What **change to the SDLC** would have prevented it?
- What went well and should be kept?

## Gate 3 — LESSONS

Distill the answers into a few **durable, curated lessons** — the signal, not a
transcript. Each lesson: what happened → what to do differently. Tie feature
lessons back to acceptance criteria where relevant.

## Gate 4 — WRITE (transient)

Write the working retro to `RETRO.md` at the repo root — the transient scratch
where the reflection is captured before it is routed. Do **not** create
`docs/retrospectives/` or any dated archive. Use the mode's template:

**feature retro**
```
# Feature retro (transient) — #<issue>: <title>

_Date: <YYYY-MM-DD> · Branch: <branch> · Tier: <tier>_

## Summary
<one-paragraph outcome>

## Outcome vs. acceptance criteria
- <criterion> — met / partially / open

## What went well
- …

## Friction
- …

## Lessons
- <what happened → what to do differently>

## Routing (filled in at Gate 5)
- <action> → issue #<n> / not filed
- <principle> → design/overview.md / sdlc-common / not adopted
```

**session retro**
```
# Session retro (transient) — <YYYY-MM-DD>

## Session summary
<what the session covered>

## What went wrong / friction
- …

## Which gate or command
- <gate/command> — <what was missing or fought us>

## Lessons
- <what happened → what to do differently>

## Routing (filled in at Gate 5)
- <action> → issue #<n> / not filed
- <principle> → design/overview.md / sdlc-common / not adopted
```

## Gate 5 — ROUTE (dual destinations)

Route each lesson to its durable home. **Propose each item and act only on
explicit per-item approval** — one confirmation per item; never auto-route,
never route silently. Record the destination back into `RETRO.md`'s Routing
section as you go.

- **Action item** ("do X") → **GitHub issue**. Use `gh issue create` with a clear
  title and a `type:*`/`path:*` label read live from `gh label list` (never
  hard-code the set). **Cite the origin** in the body (e.g. "from session retro
  2026-08-06") for traceability. Or point at `/sdlc-feedback` to file it.
- **Durable principle** ("from now on always Y") → a **`design/overview.md`**
  decision, or **`sdlc-common`** when it is about the SDLC process itself. This
  is a principle, not a work item, so it is **never** filed as an issue. Present
  the exact edit; apply it on approval.
- If the human declines an item, note it as "not filed / not adopted" — it is
  captured in `RETRO.md`, but `RETRO.md` is deleted at close-out, so a declined
  item is intentionally not preserved.

## Gate 6 — POINT & CLOSE

Show a short summary of the lessons, the issues filed, and the design/`sdlc-common`
edits made. Confirm routing is complete. Then:

- **Standalone run:** delete `RETRO.md` now (routing is complete).
- **From a `/sdlc-feature` / `/sdlc-bugfix` close-out:** leave `RETRO.md` for the
  close-out gate to delete (it removes `RETRO.md` alongside `SESSION_STATE.md`).

**Do not commit.** Stop here.

---

## Rules

- Advisory: reflect, route, point — never branch, fix, run other gates, or commit.
- One command, two modes; confirm the inferred mode when no argument is given.
- **Transient:** the retro is `RETRO.md` (working scratch), not a durable doc.
  Never create `docs/retrospectives/` or a dated archive.
- **Route before delete** (cardinal rule): every finding lands in a durable home
  — issues (actions) or `design/overview.md` / `sdlc-common` (principles) —
  before `RETRO.md` is deleted. Deletion happens at close-out (standalone runs
  delete it themselves).
- Routing is **proposed**; act only on explicit per-item approval. Read labels
  live (`gh label list`); never hard-code them. Cite the retro origin on each
  filed issue.
- Curated lessons, not a transcript. Say the signal.
