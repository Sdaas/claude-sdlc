# claude-sdlc — Professional Review

_Reviewer: Claude (Opus 4.8) · Date: 2026-08-05 · Branch reviewed: `feature/25` @ `529599e`_

Scope: the whole repo — commands (`payload/commands/*.md`), skills
(`payload/skills/*/SKILL.md`), scaffolder + installer (`scaffold.sh`, `apply.sh`),
templates, tests, and docs. Reviewed against five dimensions: AI-usability,
human-readability, strengths, gaps, and correctness.

---

## 1. Summary judgment

This is a **genuinely well-conceived, opinionated SDLC** with a coherent
philosophy (HITL gates, review-before-commit, TDD, a real Definition-of-Done that
distinguishes "green tests" from "observed behavior"). The installer is
professionally engineered. The commands are clear and actionable for an AI. It is
**above hobby grade**.

Its central weakness is **single-source-of-truth discipline**: the same rules are
copy-pasted across many command files and cross-referenced by **fragile section
numbers** (`sdlc-common §3`, `§5`). This has already caused drift twice (the
`5→10` gate renumber; the `/help` and `/verify` collisions), and it will keep
doing so. There is also one **broken advertised feature** (`--license apache`) and
**incomplete dogfooding** (the repo violates several of its own rules). For a
process that preaches "VERIFY the real flow" and "test-first," these are the most
ironic — and most fixable — findings.

---

## 2. Are the skills/commands usable by AI (Claude)?

**Yes — this is the strongest dimension.**

- Commands are **thin gate-walkers**: numbered gates, explicit "wait for
  approval," "announce each gate," "do not skip or reorder." That is exactly the
  imperative, unambiguous shape an agent follows reliably.
- The **command → skill** split is right: the command walks the sequence; the
  skill (`sdlc-common`, `sdlc-discovery`, `sdlc-harden`) defines the vocabulary.
  Frontmatter `description:` fields are written as load-triggers, which is correct
  for auto-invocation.
- Instructions are concrete and testable ("confirm red," "state the one-line
  reason," "read `gh label list` live — never hard-code").

**Friction for an AI:**

- **Brittle cross-references.** Rules are cited by number (`sdlc-common §3`, `§5`,
  "rule #10"). The design overview's own history records `Gates renumbered 5→10;
  review-scan caught cross-ref drift`. Numbers are the wrong anchor — a rename
  five months from now silently breaks a dozen citations, and the agent has no
  way to detect the dangling reference. **Use stable named anchors** ("the
  mock-obligation rule," "the review-before-commit rule") instead of `§N`.
- **Repetition across files raises reconciliation cost.** Every gate-walking
  command re-states the same preamble (load `sdlc-common`, rule #10, "checkpoint
  as you go," the VERIFY block, the Rules footer). An agent must load 2–3 files
  and reconcile overlapping copies. It works, but it is more surface to keep
  consistent than necessary.
- **No machine-checkable contract.** Adherence rests entirely on the model
  following prose faithfully. Given the drift already seen, a tiny consistency
  linter (see §5) would pay for itself immediately.

## 3. Are they readable by humans?

**Largely yes.** The README's 6-section outline, the tier/governance tables, and
the design overview are well-written and genuinely explain the *why*. The
`/sdlc-help` command gives a live, non-drifting orientation.

**Readability issues:**

- **`docs/design/overview.md` has duplicate section numbering.** The "Key
  decisions" list runs 1–11, then the "Backlog, branching, CI, and review guide"
  section **restarts at 6–10**. So "decision #6," "#8," "#10" are each ambiguous —
  and "rule #10" (review-before-commit), cited everywhere, lives in the *second*
  #10. This is confusing for a human and a landmine for the numeric cross-refs.
- **High jargon density, no glossary.** tier · path · gate · boundary inventory ·
  mock-obligation · characterization test · cardinal rule · VERIFY · Definition of
  Done. Each is defined *somewhere*, but a newcomer faces a steep, scattered
  vocabulary with no single one-page glossary.
- **Process-to-payload ratio is high.** ~1,500 lines of process prose wrap what
  ships as a shell/python/frontend scaffolder plus gated workflows. The stated
  target is "personal and SMB… high quality, but **deliberately simple**." The
  *artifact* is not simple. That tension is worth an honest look (see §6).

## 4. What this does well

1. **A real Definition of Done.** "Green tests AND observed behavior," the
   mock-obligation rule, and the VERIFY gate are hard-won, correct engineering —
   retro-born from a concrete failure (medical-ocr#7). This is the best idea in
   the repo.
2. **Review-before-commit as an inviolable rule** across every tier, including
   Quick. Rare discipline, clearly stated.
3. **The installer (`apply.sh`) is professionally built.** Owned-path manifest,
   collision guard, stale removal, dry-run, reversible uninstall, version+sha
   stamp, bash-3.2 compatible. Tested. This is production-quality tooling.
4. **Self-hosting with explicit graduation criteria.** Building the SDLC *with*
   itself, gated on "~3–4 clean runs + no process gaps," is disciplined and honest.
5. **Retro-driven evolution.** Multiple features trace to a specific past failure.
   The system learns.
6. **Pragmatic collision-avoidance.** The `sdlc-` prefix rule, learned from real
   `/help` / `/verify` collisions and then written down once, is exactly right.
7. **Graceful degradation** in `/sdlc-feedback` and `/sdlc-harden` (missing auth,
   no `gh`, no label permission → never lose the user's words) shows maturity.

## 5. Gaps & opportunities for improvement

**High value:**

- **Add a docs-consistency test to `./test.sh`.** Cheap, and it directly attacks
  the recurring drift. It could assert: every command file is `sdlc-` prefixed;
  every `SKILL` name a command claims to load actually exists; every `§N` /
  "rule #N" reference resolves to a real section; no command references a
  renamed/removed command. This is the single highest-leverage addition — a
  TDD-first project has *no test on its own primary artifact* (the prose).
- **Replace numeric cross-refs with stable named anchors**, and de-duplicate the
  repeated command preamble into one referenced block (partly tracked as #11,
  "extract orchestrator"). One edit site per rule instead of N.
- **Fix the duplicate numbering** in `overview.md` and give "review before commit"
  a stable name rather than "#10."

**Medium value:**

- **Under-specified security-review gate.** Full tier "also runs a
  security-review pass," but there is no security checklist skill/content behind
  it (contrast the detailed harden/discovery skills). The gate has a name but no
  teeth. A `/security-review` skill already exists in the harness — wire to it or
  write the checklist.
- **A one-page human glossary / quickstart.** Lower the onboarding cliff.
- **Run `release.sh`.** `VERSION` is still `0.1.0` after ~11 shipped features; the
  "explicit versioning" key decision is currently aspirational. Add a CHANGELOG.
- **Distribution options outreach.** The interview offers pip/npm/container, but
  deploy wiring beyond brew is unbuilt (#15 open). Fine — but say so at the point
  of choice, as `/sdlc-newproject` already does for the `sql` profile.

## 6. What this is doing wrong (sharper critique)

1. **Broken advertised feature — `--license apache`.** `/sdlc-newproject` offers
   "mit / apache / none"; `scaffold.sh` accepts `apache` and looks for
   `licenses/apache-2.0.tmpl` — **which does not exist** (only `mit.tmpl` is
   present). Any user choosing Apache gets `scaffold.sh: error: no license
   template for: apache` and a failed scaffold. **No test covers it.** For a
   TDD-first, "VERIFY the real flow" SDLC, a broken option in the *scaffolder's
   own matrix* is the most ironic possible defect. Fix: add the template (and an
   `apache` alias) or remove the option — and test **both** license paths.

2. **Single-source-of-truth is violated in practice.** Rules are copy-pasted
   across commands and cited by fragile numbers. The project has been bitten by
   exactly this twice already. This is the structural root cause behind several
   other findings, not a cosmetic nit.

3. **Incomplete dogfooding — "physician, heal thyself."** The SDLC prescribes
   things this very repo does not do:
   - It mandates a curated **`design/overview.md`**; this repo keeps it at
     **`docs/design/overview.md`**, and the README Developer Guide even says "the
     design lives in `design/`." The scaffolder and `CLAUDE.md.tmpl` both hard-code
     `design/`, so a scaffolded repo and the meta-repo disagree.
   - **§7 stack-detection** relies on a repo-root **`CLAUDE.md` marker**; this repo
     has **none**.
   - The README Developer Guide lists a root **`templates/`** directory — it does
     **not exist** (templates live under `payload/skills/sdlc-common/templates/`).
   - **`PROGRESS.md` is stale**: it lists #24 and #25 as "PR TBD," but both are
     merged in git history; the #24 retrospective doc under
     `docs/retrospectives/` is untracked.
   None of these is severe alone, but together they undercut the "every repo
   carries its current design / marker / cursor" claim the SDLC sells.

4. **Ceremony vs. the stated audience.** The system markets "deliberately simple"
   for "personal and SMB" software, yet delivers a dense, multi-gate,
   multi-vocabulary process. For a solo dev fixing a typo, the Quick tier is fine;
   for anything Standard+, the overhead is real. This may be the right trade — but
   it should be a *conscious* one, and the "deliberately simple" framing currently
   oversells how light it is.

---

## 7. Prioritized recommendations

| # | Action | Why | Effort |
|---|---|---|---|
| 1 | Fix/remove `--license apache`; test both license paths | Broken shipped feature, no coverage | S |
| 2 | Add a docs-consistency test to `./test.sh` (prefix, skill-exists, `§N`/`#N` resolves) | Kills the recurring drift class; tests the primary artifact | M |
| 3 | Replace `§N`/`#N` cross-refs with stable named anchors; de-dup command preamble | Single-source-of-truth; fewer edit sites | M |
| 4 | Fix duplicate numbering in `overview.md`; name "review-before-commit" | Removes ambiguity behind every "#10" citation | S |
| 5 | Reconcile dogfooding: `docs/design` vs `design/`, add root `CLAUDE.md`, refresh `PROGRESS.md`, track/commit the retro doc, fix README `templates/` claim | Practice what it preaches | S–M |
| 6 | Give the security-review gate real content | Full-tier gate currently has no checklist | M |
| 7 | Run `release.sh` off 0.1.0; add a CHANGELOG; add a human glossary/quickstart | Versioning becomes real; lower onboarding cliff | S |

**Bottom line:** strong bones, sound philosophy, professional installer. Tighten
the single-source-of-truth story, add one small consistency test, fix the Apache
path, and finish dogfooding — and this graduates from "very good work-in-progress"
to "trustworthy."
