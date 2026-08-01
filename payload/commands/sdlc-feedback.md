# /sdlc-feedback — turn a message into a well-formed GitHub issue

Triggered by `/sdlc-feedback "a message"` — e.g.
`/sdlc-feedback /feature didn't ask me to confirm the tier` or
`/sdlc-feedback blah blah doesn't work`. Captures the reporter's feedback and
files it as a GitHub issue on the current repo, prompting for detail when the
message is thin.

**This command files an issue — nothing more.** It does not fix the problem,
create a branch, or start `/feature` / `/bugfix`. After filing it may *point* at
the next command; the human invokes it.

**The reporter may not be the repo author.** Handle missing auth and missing
permissions gracefully (see the ladder in step 5) — never dead-end and never
lose the reporter's words.

---

## Gate 1 — PREFLIGHT

Before drafting, confirm the tooling is usable:

1. **Authenticated `gh`.** Run `gh auth status`. If it fails (not installed, or
   not logged in), stop and tell the reporter to authenticate first — suggest
   they type `! gh auth login` in this session — then re-run `/sdlc-feedback`.
2. **Target repo.** Resolve the repo with `gh repo view`. Note if Issues are
   disabled or the reporter lacks access; that path is handled in step 5.

## Gate 2 — GATHER

Take the `<message>`. Decide whether it already answers:

- **What happened** (the observed behavior), and
- **What I expected** (the desired behavior), and — for a bug —
- **Which command / phase** it happened in.

If any are missing, ask the reporter for them (and, when useful, **steps to
reproduce**). Ask; do not guess. Keep the reporter's **original words verbatim**
for the issue body.

## Gate 3 — CLASSIFY

Read the repo's labels **live** with `gh label list` — do not hard-code the set.
Propose one `type:*` label (`type:bug` for something broken, `type:feature` for a
request/enhancement, `type:docs`, `type:tech-debt`) and, only when clear, a
`path:*` label. If the type is ambiguous, ask the reporter.

## Gate 4 — CONFIRM (never file silently)

Show the drafted **title**, **body**, and **label**, and get an explicit yes
before filing. Body template:

```
## What happened
<observed behavior>

## What I expected
<desired behavior>

## Context
Command/phase: <e.g. /feature, DESIGN gate> · Tier: <if known>

## Steps to reproduce
<numbered steps — omit for non-bugs>

## In the reporter's words
<the original message, verbatim>
```

## Gate 5 — FILE (with a graceful-degradation ladder)

On approval, try to file — and degrade rather than fail:

1. `gh issue create --title <…> --body-file <…> --label <label>`.
2. If it fails because the reporter **lacks permission to set labels**, retry
   **without `--label`**, and add a line to the body asking a maintainer to
   triage/label.
3. If **`gh label list`** was denied (no read access), skip classification and
   file **unlabeled**.
4. If **issue creation itself** fails (Issues disabled, or no access to the
   repo), **print the full drafted issue** so the reporter can paste it into the
   web UI or file it from their fork. Never lose the feedback.

## Gate 6 — REPORT

Report the created issue's **URL** (or, on the fallback path, the drafted text
and where to submit it). If the issue names a fixable workflow problem, you may
point at the command that would address it — but do not start it.

---

## Rules

- Files an issue and points — never fixes, branches, or runs a gate.
- Read labels live (`gh label list`); never hard-code the label set.
- Always confirm the drafted issue before filing; never file silently.
- Degrade gracefully on missing auth or permissions; never lose the reporter's
  words.
- When the message or the label is ambiguous, ask — do not guess.
