# `/sdlc-resume` — Design

Continue in-flight SDLC work across sessions. Tracks Issue #19. Built by
`/feature` (prose path). Two halves: **(A)** the `/sdlc-resume` command that
orients and hands off, and **(B)** a `SESSION_STATE.md` checkpoint that the
gate-walking commands write so resume can be precise.

## Why not just `/resume`

Claude Code ships a built-in `/resume` (resumes a past conversation). To avoid
the collision — and to match the `/sdlc-help` / `/sdlc-feedback` meta-command
family — this command is `/sdlc-resume`.

## Two kinds of state, deliberately separated

- **`SESSION_STATE.md` — transient mid-flight checkpoint (B).** Repo-root,
  **gitignored**, machine-local. One in-flight workflow at a time. A gate-walking
  command **updates it on entering each gate** (and on an explicit checkpoint
  request) and **deletes it at close-out**. It captures the precise resume point:
  command, issue, tier, path, branch, gate, context, and an optional resume hint.
- **`PROGRESS.md` — durable between-work cursor.** Survives close-out; the
  human-maintained `▶ Current status` + `NEXT ACTION` + session log. Not a
  substitute for the checkpoint and not deleted.

This split is the core decision: checkpoint = *where I am inside a command*;
cursor = *where the project is between commands*. `/sdlc-resume` reads both.

## `SESSION_STATE.md` schema

```
command: /feature      issue: 19     tier: Standard    path: prose
branch: feature/19     gate: 4 (IMPLEMENT)             updated: <ISO-8601>
## Context — decisions so far / what's done / what's next
- <interview summary, design decisions, WIP, the immediate next action>
## Resume hint
- <optional note-to-self for picking back up>
```

Defined once in `sdlc-common` §5 (the shared rulebook); each gate-walker carries
a one-line pointer to that rule rather than re-specifying the mechanism (DRY).

## Which commands checkpoint

The five gate-walkers: `/feature`, `/bugfix`, `/newproject` (repo-root state) and
the upstream `/discovery`, `/architecture` (state in the product **workspace**
dir, since a repo may not exist yet). `/sdlc-help` and `/sdlc-feedback` are not
gated workflows and do not checkpoint.

## `/sdlc-resume` behavior

1. **Read** durable state: `SESSION_STATE.md` (if present); git branch/diff/log
   (when the workspace is a git repo); `gh issue list` + the in-flight issue;
   `PROGRESS.md` cursor.
2. **Reconcile** — treat `SESSION_STATE.md` as a *hint*, git + issues as ground
   truth; surface discrepancies (state says Gate 8 but no commits; branch is
   `main`; issue already closed).
3. **Propose one path** — resume the owning command at its recorded gate, or (if
   nothing is in flight) the next backlog item by the selection rule. Wait.
4. **Hand off** on approval; the owning command resumes its gates and keeps
   checkpointing. `/sdlc-resume` is **read-only until approval** — it never edits,
   branches, or runs a gate itself (same posture as `/sdlc-help`).

## Supersedes

The untracked `docs/resume-prompt.md` (a manual paste-this-to-resume prompt) is
removed — `/sdlc-resume` is its automated, reconciled replacement.

## Deferred (follow-up)

`/sdlc-pause` — a thin command for an explicit **mid-gate** flush (snapshot now +
a dictated resume hint). Not needed for #19: the contract already supports
on-demand checkpointing and a resume-hint field, so the behavior exists; a
dedicated command is sugar — a candidate follow-up (would depend on #19),
deferred for now.
