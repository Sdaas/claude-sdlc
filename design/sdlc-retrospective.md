# Design — `/sdlc-retrospective`

A two-mode reflection command. It runs a short, gated retro into a **transient**
working `RETRO.md`, routes its findings to durable homes, then **deletes** it. It
is advisory: it reflects, routes, and points — it never branches, fixes, or
commits.

Depends on: #12 (`/sdlc-feature`). Tracked by #18. Made transient by #81.

## Two modes

| Mode | Lens | Working retro |
|---|---|---|
| **feature** | The change just shipped: outcome vs. acceptance criteria, what went well, friction, lessons. Typically invoked at Full-tier close-out from `/sdlc-feature` or `/sdlc-bugfix`, or ad hoc. | `RETRO.md` |
| **session** | The work *session*, with an SDLC-improvement lens: what went wrong → which gate/command caused friction → how to improve the workflow. | `RETRO.md` |

Mode is chosen by an explicit arg (`/sdlc-retrospective feature` / `/sdlc-retrospective
session`). With no arg, the command infers from context
(`SESSION_STATE.md` / recent close-out) and **confirms** before proceeding.

## Gate path

SCOPE (subject + context) → REFLECT (interview) → LESSONS (distill) →
WRITE (transient `RETRO.md`) → ROUTE (dual destinations; per-item approval) →
POINT & CLOSE (delete at close-out).

## Key decisions

1. **One command, two modes** — not two commands. Matches `overview.md` and #18.
2. **Transient, not archived (#81).** The retro is a working artifact (`RETRO.md`,
   sibling of `SESSION_STATE.md`), not a durable doc. Its value is the routed
   outputs; the retro itself is deleted at close-out. A permanent archive
   contradicted "Backlog = GitHub Issues" and the transient/durable split of
   decision #7.
3. **Dual routing; human decides per item.** Actionable lessons → GitHub issues
   (or `/sdlc-feedback`); durable principles → `design/overview.md` or
   `sdlc-common`. Never auto-routed. Cardinal rule: **route before delete** —
   deletion is irreversible (the retro is never committed).
4. **Never commits.** It writes, routes, and points; committing is out of scope
   (keeps rule #10 clean, command single-purpose).
5. **Deleted at close-out**, like `SESSION_STATE.md`: the surrounding
   `/sdlc-feature` / `/sdlc-bugfix` close-out removes `RETRO.md`; a standalone run
   deletes it itself once routing is complete.
6. **Scaffolder change (#81).** Dropping `docs/retrospectives/` from `scaffold.sh`
   (and its test) is part of this decision — generated repos no longer inherit a
   retro archive, dissolving the #56/#58-class dogfooding gap by construction.
