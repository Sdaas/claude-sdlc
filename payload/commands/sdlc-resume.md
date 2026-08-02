# /sdlc-resume — continue in-flight SDLC work across sessions

Triggered by `/sdlc-resume` in a repo that follows this SDLC, typically at the
start of a fresh session. It reconstructs where you left off and proposes how to
continue — it **never acts without your approval**.

(Named `/sdlc-resume`, not `/resume`, to avoid colliding with Claude Code's
built-in `/resume`.)

**First, load the `sdlc-common` skill** — it defines the `SESSION_STATE.md`
checkpoint convention (§5), the tiers/paths, and the hard rules. This command
consumes that state; `sdlc-common` defines what it means.

**Read-only until you approve (hard rule).** `/sdlc-resume` orients and proposes.
It reads state, reconciles it with reality, and recommends the next step — it
does **not** edit files, create branches, or run a gate on its own. Once you
approve, it hands off to the owning command (`/sdlc-feature`, `/sdlc-bugfix`,
…), which runs its own gates.

---

## Step 1 — Read the durable state

Gather, in this order, whatever exists:

1. **`SESSION_STATE.md`** (repo root, if present) — the precise checkpoint: which
   command, issue, tier, path, branch, the gate it stopped at, the context, and
   any resume hint.
2. **Git reality** (when the workspace is a git repo) — `git status` (branch +
   uncommitted changes), `git log` (recent commits), and the current branch name
   (a `feature/<n>` or `fix/<n>` branch names the in-flight issue and path). An
   upstream `/sdlc-discovery` runs before a repo exists — there, lean on
   `SESSION_STATE.md` + the `discovery/` artifacts instead.
3. **Backlog** — `gh issue list` (open issues) and the in-flight issue
   (`gh issue view <n>`), respecting `Depends on: #N`.
4. **Cursor** — `PROGRESS.md`'s `▶ Current status` + `NEXT ACTION`, if the repo
   keeps one.

## Step 2 — Reconcile and diagnose

Cross-check the sources; **surface any discrepancy** rather than trusting one
blindly. For example: `SESSION_STATE.md` says Gate 8 but the branch has no
commits; the state names `feature/12` but you're on `main`; the issue is already
closed; uncommitted changes exist with no recorded state. State what you found
in plain terms: *"You were mid-`/sdlc-feature` on #19 (`feature/19`), stopped at
Gate 4 (IMPLEMENT); the branch has uncommitted changes in `payload/commands/`."*

## Step 3 — Propose the next step (wait for approval)

Based on the reconciled picture, recommend **one** clear path:

- **Resume in-flight work** — if there's a live `SESSION_STATE.md` (or a
  feature/fix branch with uncommitted work): propose **re-entering the owning
  command at the recorded gate** with the recorded context, and let its
  human-review gate re-approve anything mid-flight.
- **Start the next item** — if nothing is in flight: propose the next backlog
  item using the selection rule (earliest open milestone → issue whose
  `Depends on` are all closed → `PLAN.md` order), i.e. `/sdlc-feature <n>` /
  `/sdlc-bugfix <n>`.

Present the plan and **stop**. Do not launch the command — let the developer
invoke it (or say "go") so the choosing happens *with* them.

## Step 4 — Hand off

On approval, hand control to the owning command. That command resumes its own
gate sequence and continues checkpointing `SESSION_STATE.md` per `sdlc-common`
§5. `/sdlc-resume`'s job ends at the handoff.

---

## Rules

- **Advisory until approved** — orient and propose; never edit, branch, or run a
  gate on your own.
- **Reconcile, don't trust blindly** — `SESSION_STATE.md` is a hint; git + issues
  are ground truth. Flag conflicts.
- **One in-flight workflow** — resume the single checkpointed command; if none,
  pick the next backlog item *with* the developer.
- If the state is ambiguous or stale, ask before proposing — do not guess.
