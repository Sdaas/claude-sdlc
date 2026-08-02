---
name: sdlc-common
description: >
  Shared vocabulary and rules for the agentic SDLC. Load this whenever running a
  workflow command (/sdlc-feature, /sdlc-bugfix, /sdlc-harden, /sdlc-newproject)
  or when deciding how much process a change needs. Defines tiers, the code vs
  prose paths, the governance matrix, and the non-negotiable conventions
  (branching, backlog, review-before-commit). The command that loaded this
  skill walks the actual gate sequence; this skill defines what each term means.
---

# SDLC — Common Conventions

This skill is the shared "rulebook" the workflow commands rely on. It does not
run a workflow itself — it defines the vocabulary and the hard rules so every
command behaves consistently.

## 1. Classify every change

Before any work, state the change in one plain sentence, then decide three
things and **confirm them with the human**:

1. **Tier** — how much process (see §2).
2. **Path** — code or prose (see §3).
3. **Issue + branch** — the backlog item and where the work happens (see §5).

Never start implementing before the human confirms the classification.

## 2. Tiers (effort scales to the task)

| Tier | Use when | Branch | Gates |
|---|---|---|---|
| **Quick** | Trivial: no logic/interface change, no new tests (typo, comment, doc tweak). If in doubt, it is NOT quick. | `main` | surgical change → **human review** → commit |
| **Standard** | Most features and bug fixes. | `feature/<slug>` or `fix/<slug>` | interview → design(brief) → implement → code-review → review-guide → **human review** → commit → pre-push |
| **Full** | Shipped/packaged, security-sensitive, or high-risk. | branch | Standard + design-review + security-review + retrospective |

Propose a tier; the human confirms or overrides.

## 3. Paths (how "implement" happens)

- **CODE path** — behavior/logic. **Test-first**: write a failing test → confirm
  red → implement → green → refactor. Where valuable, write the test as an
  isolated subagent that sees the requirements but NOT the implementation plan,
  so tests encode intent, not the code. All tests run via the repo's `test.sh`.
  **Hermetic tests are necessary, not sufficient.** Mocking an external boundary
  (a network service, a subprocess/CLI, the filesystem, a runtime dependency)
  only proves the mock — a red against a mock goes green as soon as the mock is
  satisfied, even if the real boundary is broken. So **mocking a boundary
  obligates ≥1 non-mocked test** (a real or contract test) at that boundary,
  marked **opt-in/skippable** (local + nightly) so PR CI stays green without
  secrets/GPUs, **plus a VERIFY run** (see §5, Definition of Done) before Done.
  Beware: the isolated test-writer subagent, handed a mocked boundary, tends to
  *reinforce* the mock — name the real boundary in its brief.
- **PROSE path** — markdown skills, docs, design, templates. No red-green.
  Instead: draft → **self-check against the prose checklist** (§4) → human
  review. Still gated by review-guide and review-before-commit.

Pick the path at classify. A change can be mixed (e.g. a code feature that also
edits docs) — run each file down its appropriate path.

## 4. Prose checklist (self-check before human review)

- Does it say one thing clearly, at the right altitude (no rambling)?
- Is it consistent with the design docs and the other skills/commands?
- Are cross-references (`#issue`, file paths, skill names) correct?
- Would a new reader act correctly from this alone? No leftover placeholders?
- Curated, not exhaustive — key points only (esp. `design/overview.md`).
- If the change crosses an external boundary or a user-facing entry point: is
  there a non-mocked (real/contract) test at that boundary, and was the real
  flow observed at VERIFY? (Definition of Done, §5.)

## 5. Hard conventions (non-negotiable)

- **Backlog = GitHub Issues.** Every change links to an issue; the issue number
  is the slug. Create one if it does not exist. Respect `Depends on: #N`.
- **Branching.** Trivial → `main`. Everything else → its own branch.
- **Review before commit (rule #10).** Never commit or push before the human has
  reviewed and approved. Present the review guide + changes, wait, then commit.
- **Review guide.** Before handing off, list the changed files, a recommended
  review order, and one line each on why the file matters / where the key change
  is. The human never guesses where the substance is.
- **Tests green before push and merge.** The pre-push hook and CI run `test.sh`.
- **Definition of Done = green tests AND observed behavior.** A change is Done
  only when its tests are green **and** the real user-facing flow has been
  observed meeting its acceptance criteria (the **VERIFY** gate). Green hermetic
  tests alone are never Done for a change that crosses an external boundary or a
  user-facing entry point — see the mock-obligation rule (§3). VERIFY is
  skippable only for a pure-internal/prose change with no runtime surface
  ("nothing to drive"), and only with an explicitly stated one-line reason.
- **All testing/release via scripts.** Use the repo's `test.sh` / `release.sh`;
  do not invent ad-hoc commands.
- **Design stays current.** Record only KEY decisions in `design/overview.md`.
- **Checkpoint in-flight work (`SESSION_STATE.md`).** Every gate-walking command
  (`/sdlc-feature`, `/sdlc-bugfix`, `/sdlc-newproject`, `/sdlc-discovery`,
  `/sdlc-architecture`) keeps a **repo-root `SESSION_STATE.md`** —
  machine-local, **gitignored**, one in-flight workflow at a time. **Update it
  on entering each gate** (and whenever the developer asks to checkpoint), then
  **delete it at close-out** (the durable summary goes to the backlog /
  `PROGRESS.md`, not here). `/sdlc-resume` reads it to continue across
  sessions. Format:

  ```
  command: /sdlc-feature issue: 19     tier: Standard    path: prose
  branch: feature/19     gate: 4 (IMPLEMENT)             updated: <ISO-8601>
  ## Context — decisions so far / what's done / what's next
  - <interview summary, design decisions, WIP, the immediate next action>
  ## Resume hint
  - <optional note-to-self for picking back up>
  ```

## 6. Governance matrix (who acts, who approves)

| Gate | Agent | Human |
|---|---|---|
| Classify (tier/path/issue) | proposes | approves |
| Interview | asks | answers |
| Design | drafts | approves |
| Implement (code/prose) | acts | spot-checks |
| Code / security review | performs | reviews findings |
| Review guide | produces map | reviews the code |
| Human review | waits | **approves before any commit** |
| Commit / merge | commits after approval | approves merge (needs green CI) |
| Retrospective | drafts | confirms lessons |

## 7. Stack detection

Read the repo's `CLAUDE.md` marker (archetype / profile / distribution) to know
the stack without re-asking. Use it to pick the right stack profile
(`profile-shell`, etc.) for scaffolding, tests, and the review checklist.

## 8. Naming convention (non-negotiable)

**Every SDLC-owned slash command is prefixed `sdlc-`** — `/sdlc-feature`,
`/sdlc-bugfix`, `/sdlc-newproject`, `/sdlc-discovery`, `/sdlc-architecture`,
`/sdlc-retrospective`, `/sdlc-resume`, `/sdlc-help`, `/sdlc-feedback`, and any
future one (e.g. `/sdlc-harden`). Claude Code and third-party tools keep adding
built-in/global commands and skills (`/help`, `/verify`, …); an unprefixed name
collides with them sooner or later (#45). When authoring a **new** command or
skill for this repo, name it `sdlc-<name>` from the first draft — do not ship
it unprefixed and rename later.
