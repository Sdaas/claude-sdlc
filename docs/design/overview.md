# SDLC — Design Overview

> The curated, end-to-end design of this system and its **key** decisions.
> Not a log of every decision — only the ones that shape the architecture.
> (This repo dogfoods its own "every repo has a `design/`" rule.)

## Purpose

A unified **agentic SDLC with a human in the loop (HITL)**: when asked to build
or fix software, the agent interviews for requirements, proposes a design,
iterates through review gates, writes code test-first, reviews it, and helps
ship it — pausing for human approval at each gate. Built for **personal and
small/medium-business** software. High quality, but deliberately simple.

Source of truth is **this repo** (`~/dev/claude-sdlc`); it is *applied* into the
global Claude config (`~/.claude`) so the process is available in every project
with no per-repo setup.

## Three-layer architecture

```
LAYER 1 · ENTRY COMMANDS (global, ~/.claude/commands)
   /discovery  /architecture   ← upstream: concept → use cases → arch → backlog
   /newproject  /feature  /bugfix  /harden  /retrospective  /sdlc-resume
   → classify work, pick a TIER, walk the gates
        │ drives
LAYER 2 · GATES (reusable, stack-agnostic skills)
   interview → design → design-review → plan → plan-review → tdd → verify →
   code-review(2-pass) → security-review → review-guide →
   HUMAN REVIEW (approval gate) → commit → pre-push → ci-monitor → retrospective
        │ calls into
LAYER 3 · STACK PROFILES (the concrete "how")
   shell │ python │ sql │ frontend
   each supplies: test runner, lint/format, layout, build/package,
   deploy target (e.g. brew), stack-specific review checklist
```

## Tier dial (effort auto-scales to the task)

| Tier | Branch | Gate path |
|---|---|---|
| **Quick** | **main** | classify → surgical change → verify → commit |
| **Standard** | own branch | interview(light) → design(brief) → tdd → verify → code-review → review-guide → **human review** → commit → pre-push |
| **Full** | own branch | every gate incl. design-review, plan-review, security-review, deploy(±brew), retrospective |

Even at **Quick** tier, the surgical change is shown to the human before it is
committed. **No tier ever commits before the human has approved.**

The orchestrator proposes a tier at CLASSIFY; the human confirms or overrides.

## Commands

| Command | Purpose |
|---|---|
| `/discovery` | **Upstream (what)** — interview a fuzzy concept into gated artifacts: concept brief + use-case catalog. Runs before a repo exists. |
| `/architecture` | **Upstream (how)** — capability map + C4-ish diagram + decision records (ADRs) + a traced, sequenced **feature backlog** that feeds `/feature`. |
| `/newproject` | **Greenfield** — interview → scaffold a new repo (README, `design/`, `test.sh`, `release.sh`, hooks, CI, git init). Interview picks the stack profile. |
| `/feature` | Add a capability to an existing SDLC repo. |
| `/bugfix` | Fix a bug (reproduce-first: failing test before the fix). |
| `/harden` | Retrofit the SDLC onto an existing non-SDLC repo. |
| `/retrospective` | Two modes: **feature retro** (this change) and **session retro** (what went wrong → how to improve the SDLC). |
| `/sdlc-resume` | Continue in-flight work from `SESSION_STATE.md` (reconciled with git + issues + `PROGRESS.md`). Named `/sdlc-resume` to avoid colliding with Claude Code's built-in `/resume`. |
| `/sdlc-help` | **Guide** — explain how the SDLC works, or map a how-to question to the right command/phase. Advisory and read-only. |
| `/sdlc-feedback` | **Feedback intake** — turn a reporter's message into a well-formed GitHub issue (prompts for detail if thin; degrades gracefully on missing auth/permissions). Files-and-points only. |

## Key decisions

1. **Delivery is global; versioning is explicit.** `apply.sh` **copies**
   `payload/{commands,skills}` into `~/.claude` and writes
   `~/.claude/.sdlc/{manifest,version}` (version + git sha + owned-path manifest).
   Collision-guarded (never clobbers files it doesn't own), stale-removing,
   reversible. Flat command names. No backups — this repo's git history is the
   recovery path.
2. **Spec-driven with HITL gates.** Following the 2026 industry pattern
   (requirements → design → plan, human approval between each). The spec is the
   contract; code is what ships.
3. **TDD is mandatory at Standard+.** Red → green → refactor. Where valuable,
   the test-writer runs as an **isolated subagent** that cannot see the
   implementation plan, so tests encode requirements, not intended code.
4. **All testing and release run through shell scripts** (`test.sh`,
   `release.sh`) that the developer can invoke directly. Gates *call* these
   scripts rather than inventing ad-hoc commands.
5. **Every repo carries its design.** A curated `design/` (end-to-end design +
   **key** decisions only) plus a 6-section `README`
   (Purpose · Quick Start · User Guide · Developer Guide · Automated Testing
   Guide · Release Process).
6. **`setup.sh` separates *install* from *readiness*.** The install check
   (`command -v`) runs for **all** deps, always. Additional per-dep readiness
   checks — declared in a `CHECKS` table as `command|type|spec…` — run only for
   the deps that declare them, and only under `--verify` (opt-in). Two check
   types: `auth` (spec is a probe command that must exit 0, e.g.
   `gh auth status`) and `version` (spec is `min-version|version-probe`, compared
   by one shared comparator). Auth is inherently a tool-specific probe; version
   shares the comparison but still needs a per-tool probe to read the installed
   version. A failing readiness check prints the fix and exits non-zero. Mirrored
   into the scaffold template so every new repo inherits it. (#37)
7. **Cross-session continuity = transient checkpoint + durable cursor.** Every
   gate-walking command keeps a gitignored, machine-local **`SESSION_STATE.md`**
   (one in-flight workflow; updated on each gate; **deleted at close-out**) — the
   *transient* mid-flight state. **`/sdlc-resume`** reads it and **reconciles it
   with ground truth** (git branch/diff, open issues, `PROGRESS.md`) to propose
   resuming the owning command at its gate, or the next backlog item — advisory,
   never auto-acting. `PROGRESS.md` remains the *durable* between-work cursor.
   Named `/sdlc-resume` (not `/resume`) to avoid Claude Code's built-in. (#19)
8. **Done = green tests AND observed real behavior (#42).** Hermetic tests are
   necessary, not sufficient — a red written against a **mock** goes green when
   the mock is satisfied, proving only the mock. A first-class **VERIFY** gate in
   `/feature` and `/bugfix` (after IMPLEMENT, before code review) drives the real
   user-facing flow and exercises **every external boundary un-mocked once**.
   Mocking a boundary **obligates ≥1 non-mocked** (real/contract) test there,
   kept **opt-in/skippable** so PR CI needs no secrets/GPUs; Done is enforced by
   the VERIFY observation + that test's existence, not by blocking CI. VERIFY is
   skippable — with a stated reason — only when there is no runtime surface to
   drive. Retro-born from medical-ocr#7, where fully-green hermetic tests hid a
   missing runtime dependency and a truncation default. The rule lives once in
   `sdlc-common` (§3 mock-obligation, §4 checklist, §5 Definition of Done) and is
   walked by both commands.
9. **Real-boundary tests have a scaffolded home, and pre-push is their runner
   (#43).** #42 *mandates* a non-mocked test at every boundary; #43 gives it a
   place to live. The **python** and **shell** profiles split their suite into a
   fast/hermetic default and an **opt-in integration lane** (`./test.sh
   --integration`): python via a registered `integration` pytest marker
   (default run is `-m "not integration"`), shell via a `tests/integration/`
   directory the default `bats tests/` skips. The lane's home is **local**, not
   CI — its boundaries (a running service, GPUs, secrets) can't exist on a stock
   runner — so the **pre-push hook runs `./test.sh --integration`**, and
   integration tests **self-skip when their boundary is absent** (non-blocking,
   but automatic when it's up). PR CI keeps running the fast lane only; the
   python CI adds a **clean-install** job (`uv sync --no-dev` + run the tool)
   that fails loudly on an **undeclared runtime dependency** (the medical-ocr#7
   `Pillow` case). No integration job ships in CI (honest: it can't provide the
   boundary). Cross-profile, `/newproject` scaffolds a "fresh clone → run once"
   path and adds "run the tool once" to the Definition of Done. Frontend gets
   the same lanes in a later issue.

## Backlog, branching, CI, and review guide

6. **GitHub Issues are the backlog.** Feature requests and bug reports live as
   GitHub issues. `/feature` and `/bugfix` link to (or create) an issue at
   CLASSIFY; the issue number is the preferred artifact slug. The issue is the
   single source of truth for "what's queued."
7. **Branching policy.** **Trivial** features/bugs (Quick tier) are committed
   directly to **main**. Everything else gets its own branch
   (`feature/{slug}` or `fix/{slug}`) and merges via a reviewed change.
8. **CI + pre-push gate.** Every scaffolded repo ships with (a) a **GitHub
   Actions CI** workflow that runs `test.sh`, and (b) a local **pre-push hook**
   that runs `test.sh` and **blocks the push if any test fails**. Green tests
   are a precondition for both push and merge.
9. **Review guide (change map).** After implementation, before handing work to
   the human, the agent presents a **review guide**: the list of changed files,
   a **recommended review order**, and a one-line "why this file matters / where
   the key change is" for each. The human never has to guess which files hold
   the substance. This is its own gate (`review-guide`).
10. **Review before commit (hard rule).** The agent **never commits or pushes
    before the human has reviewed and approved.** The order is always: implement
    → present the review guide + working-tree changes → **human reviews** →
    on approval, commit and push. Committing first and reviewing after is
    forbidden — it turns review into a rubber stamp. Applies to every tier,
    including Quick, and to docs as well as code.

## Governance matrix (who acts, who approves)

| Gate | Agent | Human |
|---|---|---|
| CLASSIFY / tier + issue | proposes | approves |
| INTERVIEW | asks | answers |
| DESIGN / PLAN | drafts | approves each section |
| TDD / CODE | acts | spot-checks |
| CODE / SECURITY REVIEW | performs | reviews findings |
| REVIEW GUIDE | produces map | reviews the code |
| HUMAN REVIEW | waits | **approves before any commit** |
| COMMIT / MERGE | commits only after approval | approves merge (needs green CI) |
| RETROSPECTIVE | drafts | confirms lessons |

## Stack profiles (implemented)

- **shell** — bats (cross-shell bash+zsh), shellcheck, `bin/<tool>`, brew Formula.
- **python** — `uv` + hatchling, `src/<pkg>` layout, stdlib argparse CLI, `ruff`
  (lint+format), pytest, `requires-python >= 3.11`. `test.sh` guards on `uv`.
- **frontend** — Vite + vanilla TypeScript (framework-neutral, no React), npm,
  Vitest, `tsc --noEmit` + `prettier --check`. `test.sh` guards on node/npm.
  Kept framework-neutral so the profile is a reusable base, not a commitment to
  React for every front-end project.

## Out of scope (for now)

- Model/token-usage optimization (deferred).
- Rich SQL profile, and a richer front-end profile (React/component testing,
  ESLint, publish flow) — the current front-end profile is a lightweight first
  pass, improved next iteration.
- Migrating the existing global shell skills into `profile-shell` (kept working
  standalone until `profile-shell` is proven).
