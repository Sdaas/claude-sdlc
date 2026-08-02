# /sdlc-retrospective — reflect on a change or a session, and record the lessons

Triggered by `/sdlc-retrospective feature`, `/sdlc-retrospective session`, or
bare `/sdlc-retrospective`. Runs a short, gated reflection and writes **one**
durable markdown doc into the **working repo's** `docs/retrospectives/`.

**First, load the `sdlc-common` skill** — it defines the governance matrix and
the hard conventions (backlog = GitHub Issues, review before commit) this command
respects.

**This command reflects, writes one doc, and points — nothing more.** It does
not branch, fix, run other gates, or commit. Committing the doc is left to the
surrounding `/sdlc-feature` / `/sdlc-bugfix` close-out or to the human (rule #10).

**Two modes:**

| Mode | Lens | Doc written |
|---|---|---|
| **feature** | The change just shipped — outcome vs. acceptance criteria, what went well, friction, lessons. Usually invoked at Full-tier close-out, or ad hoc. | `docs/retrospectives/YYYY-MM-DD-feature-<issue>.md` |
| **session** | The work *session*, with an SDLC-improvement lens — what went wrong → which gate/command caused friction → how to improve the workflow. | `docs/retrospectives/YYYY-MM-DD-session.md` |

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

## Gate 4 — FOLLOW-UPS

Turn actionable lessons into candidate follow-ups (e.g. "add a boundary-inventory
step to `/sdlc-harden`", "clarify the VERIFY skip rule"). For each one:
- **Propose** it and ask whether to **file it as a GitHub issue** now (or to
  point at `/sdlc-feedback` to file it). File **only** on explicit per-item
  approval — one confirmation per item; never auto-file, never file silently.
- If the human declines, the item stays recorded in the doc.

When filing, use `gh issue create` with a clear title and a `type:*`/`path:*`
label read live from `gh label list` (never hard-code the set). Record any
created issue's number/URL in the doc's Follow-ups section.

## Gate 5 — WRITE

Create `docs/retrospectives/` if it does not exist, then write the doc with the
mode's filename. Use `<issue>` = the slug for feature mode; today's date for the
date. Templates:

**feature retro**
```
# Feature retro — #<issue>: <title>

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

## Follow-ups
- <action> — filed as #<n> / not filed
```

**session retro**
```
# Session retro — <YYYY-MM-DD>

## Session summary
<what the session covered>

## What went wrong / friction
- …

## Which gate or command
- <gate/command> — <what was missing or fought us>

## Proposed SDLC improvements
- <change to a command/skill/convention>

## Follow-ups
- <action> — filed as #<n> / not filed
```

## Gate 6 — POINT & STOP

Show the written doc's **path** and a short summary of the lessons and any filed
issues. Note that committing the doc is the human's / close-out's job. **Do not
commit.** Stop here.

---

## Rules

- Advisory: reflect, write one doc, point — never branch, fix, run other gates,
  or commit.
- One command, two modes; confirm the inferred mode when no argument is given.
- Follow-ups are **proposed**; file as issues only on explicit per-item approval.
  Read labels live (`gh label list`); never hard-code them.
- Curated lessons, not a transcript. Say the signal.
- Writes to the **working repo's** `docs/retrospectives/`.
- When the scope or mode is ambiguous, ask — do not guess.
