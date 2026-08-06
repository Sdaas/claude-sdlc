# `/sdlc-newproject` — Design

Greenfield workflow: interview the developer, then scaffold a new repo that
already follows this SDLC (README, `design/`, tests, hooks, CI). Tracks
Issues #1 and #6.

## Interview (asked by the `/sdlc-newproject` command)

Core (always):
1. **Name & purpose** — repo name + one sentence.
2. **Archetype** — CLI tool / library / service / web app / data-pipeline.
3. **Primary stack (profile)** — shell / python / sql / frontend (+ optional secondary).
4. **Distribution** — none / Homebrew / pip / npm / container.
5. **Repo hosting** — create GitHub repo now? **default: yes, private**.
6. **License** — MIT (default) / Apache-2.0 / none.

Also (recorded into `design/overview.md`):
7. **Known constraints** — security / performance / scale, if any.
8. **Key design & usability considerations** — anything shaping the design up front.

Product requirements per feature are gathered later by `/sdlc-feature`, not here.

## Scaffolder architecture

To stay testable and script-driven, `/sdlc-newproject` does **not** free-hand files.
It runs a template-based scaffolder that ships in `payload/` (so a global install
can scaffold anywhere):

```
payload/skills/sdlc-common/scaffold.sh          # renders templates -> target
payload/skills/sdlc-common/templates/core/      # stack-agnostic templates
payload/skills/sdlc-common/templates/licenses/  # MIT, Apache-2.0
payload/skills/profile-shell/templates/         # shell-specific (later increment)
```

`scaffold.sh` substitutes `{{PLACEHOLDERS}}` (NAME, PURPOSE, ARCHETYPE, PROFILE,
DISTRIBUTION, LICENSE, AUTHOR, YEAR) using bash string replacement (no sed
escaping pitfalls; bash 3.2 compatible). It refuses to write into a non-empty
target unless `--force`. Built **test-first** (`tests/test_scaffold.sh`).

CLI:
```
scaffold.sh --target DIR --name NAME --purpose "..." --profile shell \
  --archetype cli --distribution none|brew|pip|npm|container \
  --license mit|apache|none --author "Name" [--force]
```

## Scaffold tree

Stack-agnostic core (every repo):
```
README.md            # 6 sections, pre-filled from interview
LICENSE              # per choice
.gitignore
VERSION              # 0.1.0
CLAUDE.md            # stack marker (archetype/profile/distribution) + pointer to SDLC
design/overview.md   # Purpose, Architecture (TBD), Key Decisions, Constraints
hooks/pre-push       # blocks push unless test.sh is green
install-hooks.sh
.github/workflows/ci.yml
```

Shell profile adds (later increment):
```
test.sh              # runs bats (works under bash AND zsh)
release.sh
bin/<tool>           # strict-mode executable with --help/--verbose
tests/<tool>.bats    # bats suite; target script exercised under bash + zsh
Formula/<tool>.rb    # only if distribution = Homebrew
```

## Decisions

- **Repo hosting:** interview asks; **default create private repo + first push**.
- **CLAUDE.md:** yes — a small per-repo marker recording archetype/profile/
  distribution (so future `/sdlc-feature` sessions know the stack without re-asking)
  plus a one-line pointer to the global SDLC.
- **Shell tests:** **bats**, invoked via `test.sh`; the target script must run
  under **both bash and zsh**, and the suite exercises it under both.
- **Interview depth:** core 6 + constraints + key design/usability considerations.

## Build order

1. `scaffold.sh` + core templates, test-first (this increment).
2. Shell profile templates (test.sh/bats/bin/release/Formula).
3. `/sdlc-newproject` command wiring: interview → scaffold.sh → git init →
   optional `gh repo create` → first commit → handoff to `/sdlc-feature`.
