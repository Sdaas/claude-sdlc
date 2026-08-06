---
name: profile-shell
description: >
  Stack profile for shell (bash/zsh) repos in the SDLC — the concrete "how" for
  the shell stack. Currently carries the profile's starter security checklist,
  consumed by the sdlc-security Full-tier gate and by /sdlc-harden. Fuller profile
  content (test runner, layout, lint/format conventions) lives in the templates/
  dir and the shell-family skills for now; this SKILL.md will grow to own it.
---

# Profile — Shell

The shell stack profile. Scaffolding and conventions currently live in
`templates/` and the shell-family skills (`zsh-script`, `harden-shell-repo`); this
`SKILL.md` will grow to own the full profile. For now it carries the **security
checklist** that `sdlc-security` (§4) and `/sdlc-harden` delegate to.

## Security checklist (starter — non-exhaustive, see #84)

> A **floor, not a ceiling.** Walk `sdlc-security` §2 in full; these are the
> highest-signal shell-specific checks. Fleshing this out is tracked as **#84**.

- **Injection / quoting.** Unquoted `$var` and `$(...)` word-split and glob —
  quote every expansion. Never `eval` untrusted input; avoid building a command
  string from external data (use arrays: `cmd "${args[@]}"`).
- **Secrets in `argv`/env.** Secrets passed as CLI args are world-visible via
  `ps`. Read from a file/env, do not echo, keep them out of `set -x` traces.
- **Temp files & symlinks.** Create temp files with `mktemp` (not a predictable
  `/tmp/foo`), tight perms, and a `trap` cleanup. Do not follow symlinks when
  writing to a chosen path (TOCTOU); check before `rm -rf "$dir/"`.
- **Strict mode.** `set -euo pipefail` so a failed boundary call aborts rather
  than silently continuing on bad state.
- **Untrusted fetch-exec.** No `curl … | sh` on an unpinned/unverified source.
