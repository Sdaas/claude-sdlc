# Design — `/retrospective`

A two-mode reflection command. It runs a short, gated retro and writes one
durable markdown doc into the **working repo's** `docs/retrospectives/`. It is
advisory: it reflects, writes, and points — it never branches, fixes, or commits.

Depends on: #12 (`/feature`). Tracked by #18.

## Two modes

| Mode | Lens | Doc |
|---|---|---|
| **feature** | The change just shipped: outcome vs. acceptance criteria, what went well, friction, lessons. Typically invoked at Full-tier close-out from `/feature` or `/bugfix`, or ad hoc. | `docs/retrospectives/YYYY-MM-DD-feature-<issue>.md` |
| **session** | The work *session*, with an SDLC-improvement lens: what went wrong → which gate/command caused friction → how to improve the workflow. | `docs/retrospectives/YYYY-MM-DD-session.md` |

Mode is chosen by an explicit arg (`/retrospective feature` / `/retrospective
session`). With no arg, the command infers from context
(`SESSION_STATE.md` / recent close-out) and **confirms** before proceeding.

## Gate path

SCOPE (subject + context) → REFLECT (interview) → LESSONS (distill) →
FOLLOW-UPS (propose; file as issues only on per-item approval) →
WRITE (the doc) → POINT & STOP.

## Key decisions

1. **One command, two modes** — not two commands. Matches `overview.md` and #18.
2. **Propose, human decides** on follow-ups. Actionable lessons are offered as
   GitHub issues (or a pointer to `/sdlc-feedback`); never auto-filed. Honors the
   backlog = Issues convention without surprising the human.
3. **Never commits.** It writes and presents the doc; committing is left to the
   surrounding close-out or the human (keeps rule #10 clean, command
   single-purpose).
4. **No shell changes.** `apply.sh` ships `payload/**` generically, so the new
   command file installs with no code change; existing apply tests cover the copy.
5. **Writes to the working repo**, so retros live with the project they reflect
   on — self-hosted here in this repo's `docs/retrospectives/`.
