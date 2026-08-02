# /sdlc-help — explain how the SDLC works, and answer how-to questions

Triggered by `/sdlc-help` (overview) or `/sdlc-help "a question"` (e.g.
`/sdlc-help how do I add a feature?` or
`/sdlc-help I forgot something in architecture — how do I go back and fix it?`).
This is the **guide** to the SDLC: it explains and points; it never does the work.

**First, load the `sdlc-common` skill** — it is the source of truth for the
tiers, the code-vs-prose paths, the governance matrix, and the hard rules. For
any question about the upstream phase (concept, use cases, architecture,
backlog), also load `sdlc-discovery`. Answer from these skills, not from memory.

**Read the installed commands live.** Before answering, read the command files
in `~/.claude/commands/*.md` (and the loaded skills) so the help reflects what is
actually installed — never hard-code a command list, which would drift as
commands change.

**Read-only (hard rule).** `/sdlc-help` is advisory. It explains the process and
names the command to run — it **never** edits files, creates branches, runs a
workflow gate, or otherwise changes the repo. When the answer is "run
`/sdlc-feature`", say so and stop; let the human invoke it.

---

## Mode 1 — no argument: explain how the SDLC works

Give a concise orientation, drawn from the installed commands and skills:

1. **The phase flow** — the upstream `/sdlc-discovery → /sdlc-architecture`
   (concept → use cases → architecture → traced, sequenced backlog), then the
   build commands `/sdlc-newproject`, `/sdlc-feature`, `/sdlc-bugfix`,
   `/sdlc-harden`, closing with `/sdlc-retrospective` and `/sdlc-resume`.
2. **Classify every change** — tier (Quick / Standard / Full) and path
   (code / prose), confirmed with the human before any work (`sdlc-common` §1–3).
3. **The gate sequence** — interview → design → implement → code-review →
   review-guide → **human review** → commit → pre-push. Announce each gate; never
   skip or reorder.
4. **The backlog is GitHub Issues** — every change links to an issue; the issue
   number is the slug. Trivial work goes to `main`; everything else gets its own
   branch.
5. **Review before commit (rule #10)** — nothing is committed or pushed before
   the human has reviewed and approved.
6. **Command index** — one line per installed command (derive the list from
   `~/.claude/commands/`, do not hard-code it).

End by inviting a specific question: `/sdlc-help "…"`.

## Mode 2 — a question: map it to the right command / phase

1. **Interpret** the question and map it to the phase or command that owns it —
   e.g. "add a feature" → `/sdlc-feature`; "fix a bug" → `/sdlc-bugfix`; "start
   a new project" → `/sdlc-newproject`; "figure out what to build" →
   `/sdlc-discovery`; "revise the architecture" → re-run `/sdlc-architecture` on
   the existing artifacts; "retrofit an existing repo" → `/sdlc-harden`.
2. **Explain the concrete steps** the human takes, grounded in the owning
   skill's gates (`sdlc-common` / `sdlc-discovery`). If they are mid-workflow and
   want to change an earlier decision, explain how to go back — usually re-enter
   the earlier command/gate and let its human-review gate re-approve the change.
3. **Point at the command to run** (e.g. "run `/sdlc-feature 34`") and stop. Do
   not launch it.
4. If the question is ambiguous, ask a clarifying question before answering —
   do not guess what they meant.

---

## Rules

- Advisory and **read-only** — explain and point; never edit, branch, or run a
  gate.
- The skills (`sdlc-common`, `sdlc-discovery`) are the source of truth; read the
  installed commands live so help never drifts.
- Point the human at the command; let them invoke it.
- When unsure what the human is asking, ask — do not guess.
