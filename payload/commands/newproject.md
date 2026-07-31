# /newproject — start a new SDLC repo

Triggered by `/newproject` (or a natural request to "start a new project/repo").

Greenfield workflow: interview the developer, scaffold a repo that already
follows this SDLC, then initialize git and (optionally) create the GitHub repo.
Human-in-the-loop at every step. Follow the steps in order — do not skip or
reorder.

**Hard rule (SDLC #10):** never commit or push before the developer has
reviewed and approved. Present changes, wait for approval, then commit.

Prerequisite: the SDLC is installed (`~/.claude/skills/sdlc-common/scaffold.sh`
exists). If it does not, tell the developer to run `apply.sh` from the
claude-sdlc repo first.

---

## Step 1 — Interview

Ask these, grouping where natural. Do not assume answers.

Core:
1. **Name & purpose** — repo name + one sentence.
2. **Archetype** — cli / library / service / webapp / pipeline.
3. **Primary stack (profile)** — shell / python / sql / frontend (+ optional secondary).
4. **Distribution** — none / brew / pip / npm / container.
5. **Repo hosting** — create a GitHub repo now? Visibility (**default: private**).
6. **License** — mit (default) / apache / none.

Also capture (recorded into `design/overview.md` at Step 4):
7. **Known constraints** — security / performance / scale, if any.
8. **Key design & usability considerations** — anything shaping the design up front.

Note to the developer: detailed per-feature requirements come later via
`/feature`; this interview is only to stand up the repo.

Only the **shell** profile is fully implemented today. If another profile is
chosen, say so — the core skeleton is generated but stack files are not yet.

## Step 2 — Confirm

Summarize the answers back. Map them to the scaffolder arguments and state the
default tier for future work. Get explicit confirmation before scaffolding.

## Step 3 — Scaffold

Choose the target directory (default: `./<name>` under the current directory;
or the current directory if it is empty and the developer prefers). Then run:

```bash
~/.claude/skills/sdlc-common/scaffold.sh \
  --target <dir> \
  --name <name> \
  --purpose "<purpose>" \
  --profile <profile> \
  --archetype <archetype> \
  --distribution <distribution> \
  --license <license> \
  --author "$(git config user.name)"
```

Show the generated tree.

## Step 4 — Record design inputs

Edit `<dir>/design/overview.md`: fill the **Constraints** and **Design &
Usability Considerations** sections from answers 7–8. Keep it curated — key
points only.

## Step 5 — Review before commit (gate)

Present the scaffolded files with a short **review guide** (what to look at
first). **Wait for the developer's approval.** Do not proceed to commit until
approved.

## Step 6 — Initialize git

After approval:

```bash
cd <dir>
git init
./install-hooks.sh          # install the pre-push test gate
git add -A
git status --short          # show what will be committed
```

On confirmation, make the first commit:

```bash
git commit -m "Initial scaffold (SDLC)"
```

## Step 7 — Optional GitHub repo

If hosting was requested, confirm visibility (default private) and create it:

```bash
gh repo create <owner>/<name> --private --source=. --remote=origin --push
```

The pre-push hook runs `./test.sh` before the push completes.

## Step 8 — Seed backlog + hand off

- Offer to create initial GitHub Issues for the first planned capabilities
  (the backlog lives in Issues).
- Tell the developer: **run `/feature "…"` to build the first capability.**

---

## Rules

- Review before commit (SDLC #10) — applies to the scaffold and the first commit.
- The initial scaffold is the first commit on `main`. Later non-trivial work
  goes on its own branch (`feature/<slug>`); only trivial changes go on `main`.
- All testing and release run through `./test.sh` and `./release.sh`.
- If the description is ambiguous, ask before scaffolding — do not guess scope.
