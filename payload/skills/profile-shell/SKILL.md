---
name: profile-shell
description: >
  Stack profile for shell (bash/zsh) repos in the SDLC — the concrete "how" for
  the shell stack (cross-shell bin/ tools, shellcheck + shfmt, bats, mktemp/trap
  hygiene). Renders the profile-common backbone: best practices, performance &
  scale, testing pyramid, security, reliability & resilience, and observability.
  Load it at IMPLEMENT/VERIFY/review of a shell change, when scaffolding a shell
  repo, or to learn the shell quality bar. It owns the shell security checklist
  that the sdlc-security Full-tier gate and /sdlc-harden delegate to.
---

# Profile — Shell

The concrete shell (bash/zsh) stack profile — the "how" for every dimension of a
shell change. It **clones the [`profile-common`](../profile-common/SKILL.md)
backbone** (ADR-0001): the six quality dimensions below appear in the fixed
skeleton order, each filled with shell-specific tools, commands, and idioms —
following the F2 [`profile-python`](../profile-python/SKILL.md) reference pattern
(#91 clones #90).

This profile **references, does not absorb, the shipped shell-family skills**:
authoring a new script is **[`zsh-script`](../zsh-script/SKILL.md)**, adding a
feature is `add-shell-feature`, fixing a bug is `fix-shell-bug`, and bringing an
existing repo up to standard is
**[`harden-shell-repo`](../harden-shell-repo/SKILL.md)**. Those skills carry the
step-by-step workflow; this profile carries the **standards** they and the SDLC
gates check against (a non-goal is re-teaching their procedure here).

**Stack at a glance:** cross-shell `bin/<tool>` entry points (run under **both**
bash and zsh, no bash-only machinery), `set -euo pipefail` strict mode,
`shellcheck` (lint) + `shfmt` (format), `bats-core` tests, `mktemp` + `trap`
temp-file hygiene. The scaffolding that embodies this lives in
[`templates/`](templates/) and is consumed by `/sdlc-newproject` (see
[Scaffolding](#scaffolding)).

---

## 1. Best practices

*The shell style/idiom standard and the tooling that enforces it.* (CAP-1 ·
serves UC-001.)

**Tooling — `shellcheck` lints, `shfmt` formats:**

- **Lint:** `shellcheck bin/<tool> *.sh` — the static analyzer that catches the
  bulk of shell footguns (unquoted expansions **SC2086**, word-splitting
  **SC2046**, unsafe `eval`, useless `cat`, `[ ]` vs `[[ ]]` pitfalls). It is the
  first thing `./test.sh` runs and is also the primary security scanner (see
  [§4](#4-security)). Fix findings; suppress only with a justified inline
  `# shellcheck disable=SCxxxx` naming the reason.
- **Format:** `shfmt -d .` (diff / check in `test.sh`/CI) and `shfmt -w .` to
  apply — one formatter, consistent indentation and layout. Match the repo's
  existing `shfmt` flags (e.g. tabs vs. `-i N`) rather than reformatting wholesale.

**Strict mode & layout:**

- **`set -euo pipefail`** at the top of every script: `-e` abort on error, `-u`
  error on unset var, `-o pipefail` so a failing stage in a pipe fails the
  pipeline. This is the single most important shell reliability idiom (see
  [§5](#5-reliability--resilience)).
- **`bin/<tool>` layout** — the executable entry point under `bin/`, sourced
  helpers under `lib/`, tests under `tests/`. A `main "$@"` function at the
  bottom, so the file is sourceable for testing without executing.

**Cross-shell discipline (deliberate):** the entry template runs under **both bash
and zsh** and avoids bash-only machinery (`${BASH_SOURCE}`, `FUNCNAME`,
`declare -A` where zsh differs). Keep it that way — the testing pyramid ([§3](#3-testing-pyramid))
exercises the tool under each shell to prove it.

**Idioms a reviewer checks by hand:** quote **every** expansion (`"$var"`,
`"${arr[@]}"`); build commands as **arrays** (`cmd "${args[@]}"`), never by
string-concatenation; `$(...)` over backticks; `[[ ]]` over `[ ]` for tests;
`printf` over `echo` for anything with escapes or leading `-`; a `trap` cleanup
for every temp file; prefer builtins/parameter-expansion over spawning `sed`/`awk`/`cat`
in hot paths (see [§2](#2-performance--scale)).

## 2. Performance & scale

*What makes shell performance **checkable** — named signals over existing tools,
not adjectives (ADR-0003).* (CAP-4 · serves UC-004.) The agent must **flag or
clear** the changed path against at least one named signal below.

| Signal | Observe with | Flag-or-clear bar |
|---|---|---|
| **Process-spawn / fork cost** | Read the changed path; `bash -x` to see each spawn | An external binary (`sed`/`awk`/`grep`/`cat`) or a `$(...)` subshell **spawned per loop iteration** — a fork each time. Hoist it out, or do the work in one `awk`/parameter-expansion pass. |
| **Useless use of a subprocess** | Read the changed path | `cat file \| grep …`, `echo "$x" \| sed …`, `$(cat f)` where a builtin does it (`grep … file`, `${x//a/b}`, `$(<f)`). Each is an avoidable fork. |
| **Algorithmic complexity** | Read the changed path | A nested loop over the same input (O(n²)), or a repeated linear scan (re-`grep`-ing a file inside a loop) — build an associative array / sort-join once. |
| **Streaming vs. slurping** | Read the changed path | Reading a whole large file into a variable (`x=$(<big)`) or `for line in $(cat big)` instead of streaming (`while IFS= read -r line; do … done < big`) — memory and word-splitting both bite. |

Named signals + existing tools give falsifiability without a bespoke benchmark
harness (a declared non-goal, ADR-0003). For a real micro-benchmark, **`time`**
(shell builtin) or **`hyperfine`** (multi-run, statistical) on the entry point.
This dimension is expected to **deepen per project**; a thin-but-honest read of
the four signals is enough to clear a typical change.

## 3. Testing pyramid

*The shell testing standard across the pyramid and its runner.* (CAP-2 · serves
UC-002.)

- **Framework:** **`bats-core`** (`tests/*.bats`). A dev dependency — `./test.sh`
  errors with install hints if `bats` is absent.
- **Runner:** the repo's `./test.sh` runs `shellcheck` → (`shfmt -d`) → `bats
  tests/`. It is what the pre-push hook and CI both call — never invoke `bats`
  ad-hoc as the gate.
- **Layer split:**
  - **Unit** — a single function/helper in isolation (source the script, call the
    function), no external boundary. The bulk of the pyramid.
  - **Integration** — the tool against a **real boundary** (a live service, a CLI
    it shells out to, real files, secrets). Lives under **`tests/integration/*.bats`**.
  - **e2e** — drive the `bin/<tool>` entry point end to end (`run ./bin/<tool> …`,
    assert `$status`/`$output`).
- **Cross-shell.** Every tool must work under **both bash and zsh** — the suite
  runs the entry point under each (`run bash ./bin/<tool>`, `run zsh ./bin/<tool>`,
  the latter self-skipping when `zsh` is absent).
- **The opt-in integration lane (`sdlc-common` §3).** `./test.sh` runs the fast
  lane only (`bats tests/`, non-recursive — skips `tests/integration/`);
  **`./test.sh --integration`** adds the lane. Its home is **local + nightly**
  (the pre-push hook), and each integration test **self-skips (`bats skip`) when
  its boundary is absent** so the lane stays non-blocking. PR CI runs the fast
  lane only.
- **Mock-obligation.** Faking a boundary in a unit test obligates **≥1 non-mocked
  test** at that boundary in the integration lane, **plus a VERIFY run** before
  Done — a green mock only proves the mock (`sdlc-common` §3, §5).

Cross-**language** testing (shell↔python, shell↔sql) is **not** here — see
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 4. Security

*The shell security checklist + scanner.* (CAP-3 · serves UC-003.) This section
is a **stack-specific floor** delegating the review **method** and the six-category
core to the shared **`sdlc-security`** skill (§2) — walk that in full; the checks
below are the highest-signal shell-specific ones. Consumed by the `sdlc-security`
Full-tier gate (§4) and by `/sdlc-harden`.

**Scanners — run both:**

- **`shellcheck`** — the primary scanner (already the [§1](#1-best-practices)
  linter). It catches most injection/quoting vulnerabilities directly: unquoted
  expansion (**SC2086**), word-splitting (**SC2046**), unsafe `eval`, and glob
  pitfalls. Security scanning therefore needs no extra shell tool for these.
- **`gitleaks`** — the gap `shellcheck` does **not** cover: secrets committed to
  the repo or leaked in scripts. Run `gitleaks detect` (brew: `gitleaks`) as the
  secret-scanning companion.

**The checklist** (each maps to a concrete shell vector):

- **Injection / word-splitting** — unquoted `$var` / `$(...)` word-split and
  glob-expand; **quote every expansion** (**SC2086/SC2046**). Never `eval`
  untrusted input. Never build a command string from external data — use an
  **array** (`cmd "${args[@]}"`). A hostile `$IFS` changes how unquoted values
  split; do not rely on the default, and quote.
- **Glob injection** — an attacker-controlled filename beginning with `-` becomes
  an option to the next command; end option lists with `--` (`rm -- "$f"`) and
  quote globs you don't intend to expand.
- **Secrets in `argv`/env** — secrets passed as CLI args are world-visible via
  **`ps`**; env vars leak to child processes. Read secrets from a file (tight
  perms) or a secret store; keep them out of **`set -x`** traces (`set +x` around
  the use); never `echo` them. `gitleaks` guards the committed-secret case.
- **Temp files & symlinks (TOCTOU)** — create temp files with **`mktemp`** (never
  a predictable `/tmp/foo`), with tight perms and a **`trap` cleanup**. Do not
  follow symlinks when writing to a chosen path; a check-then-use on a shared dir
  is a TOCTOU race.
- **Strict-mode gaps & destructive commands** — a missing `set -euo pipefail`
  lets a failed step continue on bad state. An unset var in **`rm -rf "$VAR/"`**
  (with `-u` off) expands to `rm -rf /` — guard with `${VAR:?}` and validate the
  path before any destructive `rm`.
- **Untrusted fetch-exec** — no **`curl … | sh`** on an unpinned/unverified
  source; download, verify a checksum/signature, then run. The same caution
  applies to command substitution on data fetched from the network.

See the shared skill: **`sdlc-security`**. Cross-check the best-practices baseline
in **`harden-shell-repo`**.

## 5. Reliability & resilience

*How shell code survives partial failure at its boundaries — dependency checks,
null/empty-var safety, timeout, retry, backoff, idempotency.* (CAP-5 · serves
UC-010.)

- **Dependency preflight.** Check every required external tool is present up front
  — `command -v jq >/dev/null || { log_error "jq required"; exit 1; }` — so the
  script fails fast with a clear message instead of midway with a cryptic
  `command not found`.
- **Null/empty-var safety.** `set -u` catches unset vars; use **`${VAR:?message}`**
  to require a value, **`${VAR:-default}`** for an intentional default, and
  **`"${arr[@]}"`** (quoted) so an empty array doesn't misbehave. This is the same
  guard that prevents the `rm -rf "$VAR/"` disaster ([§4](#4-security)).
- **Timeout on external calls.** Wrap a call that can hang in **`timeout <dur>
  cmd …`** so a stuck boundary aborts rather than blocking forever.
- **Retry transient failures with capped backoff.** A small hand-rolled loop —
  retry only on transient failure (a timeout, a 5xx, a connection reset), with an
  exponential-ish **`sleep`** **backoff** and a capped attempt count; never retry
  a deterministic/logic error.
- **Idempotency & cleanup.** A retried step must be safe to repeat (`mkdir -p`,
  `ln -sf`, an idempotency key); a **`trap 'cleanup' EXIT INT TERM`** removes temp
  state on every exit path, including failure. On give-up, **fail closed** with a
  clear `log_error` and a non-zero exit.

**Prove it with a failure-path test.** The timeout/retry/backoff behavior needs a
bats test that forces the failure (a stub on `PATH` that exits non-zero or sleeps,
asserting the retry/give-up path) — **co-located with the boundary's contract
test** in the integration lane, per
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 6. Observability & logging

*How shell renders the shared logging policy.* (CAP-6 · serves UC-009.) This
dimension **renders — does not reinvent** — the authoritative
[`design/logging-policy.md`](../../../design/logging-policy.md).

- **Mechanism:** the **`log_debug` / `log_info` / `log_error`** helpers the
  `bin-tool` template ships (a single `log LEVEL msg` under the hood). Do not use
  bare `echo` to stdout for diagnostics.
- **Levels:** `INFO` (default, general progress) and `DEBUG` (detail); `ERROR` is
  always emitted. There is **no `WARN`**.
- **Level select:** **`--verbose`** sets `LOG_LEVEL=DEBUG` (there is no separate
  `--debug` flag).
- **Destination:** all log lines go to **stderr** (`>&2`); **stdout is reserved
  for real data** so a caller can pipe it.
- **Format:** `<ISO-8601 UTC timestamp> <LEVEL> <tool>: <message>` — the helper
  uses `date -u +%Y-%m-%dT%H:%M:%SZ`.
- **Exceptions (deliberate shell caveat):** shell has no portable multi-frame
  stack trace across bash/zsh, so "log the error" means emit an `ERROR` line with
  the message (and failing context where practical) and let `set -e` abort. Full
  traces are a Python/webapp affordance, not shell (see the policy's shell caveat).

See the authoritative policy: **`design/logging-policy.md`**.

---

## Scaffolding

*The shell project scaffolding — the templates a new repo is generated from.*
(CAP-7.) Per ADR-0004 this section **references the existing
[`templates/`](templates/) dir; it does not copy or re-invent it** — the templates
own the files, this profile owns the standards those files must satisfy.
`/sdlc-newproject` generates a shell repo from these templates, so a scaffolded
repo is **born compliant** with the dimensions above.

A generated shell repo inherits:

- **`bin-tool.tmpl`** — the cross-shell `bin/<tool>` entry point: `set -eu`, the
  `log_debug/info/error` helpers demonstrating the logging policy ([§6](#6-observability--logging)),
  `--help`/`--verbose`, stdout-for-data / stderr-for-logs.
- **`test.sh.tmpl`** — the single test entry point: `shellcheck` → `bats tests/`,
  with the `--integration` opt-in lane ([§3](#3-testing-pyramid)).
- **`tool.bats.tmpl`** — a starter bats suite that already runs the tool under
  **both bash and zsh** ([§3](#3-testing-pyramid)).
- **`setup.sh.tmpl`, `release.sh.tmpl`, `ci.yml.tmpl`, `formula.rb.tmpl`** — dev
  setup, release flow, GitHub CI (runs the fast lane), and a Homebrew formula for
  distribution.

If a template is found non-conformant with a standard here, that is a normal
`/sdlc-feature` or `/sdlc-harden` item **against the templates**, filed separately
(ADR-0004) — do not fork the standard into the profile. For the hands-on workflow
of authoring or hardening a script, use the shell-family skills
(**`zsh-script`**, **`harden-shell-repo`**).

## Cross-profile testing

Cross-**profile** (cross-language) testing — a shell component tested against a
component in another stack (shell↔python, shell↔sql) — is **owned by
`profile-common`**, not by any single profile (ADR-0002). See
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).
It is a **stub fleshed out in F6 (#94)** once ≥2 real profiles exist to exercise a
boundary; the shell side contributes the contract test + the co-located resilience
failure-path test ([§5](#5-reliability--resilience)) at each boundary it
participates in.

---

_Traceability: renders the `profile-common` backbone (F1/#89, ADR-0001) for the
shell stack, cloning the F2/`profile-python` pattern (#90). CAP-1 (best practices),
CAP-4 (performance, ADR-0003), CAP-2 (testing), CAP-3 (security — folds in #84),
CAP-5 (reliability), CAP-6 (observability), CAP-7 (scaffolding, ADR-0004 —
references `templates/`). References, does not absorb, the shell-family skills
(`zsh-script`, `harden-shell-repo`). Serves UC-001, UC-002, UC-004, UC-005,
UC-009, UC-010. Source: `/sdlc-architecture` backlog F3 (#91); security checklist
subsumes #84._
