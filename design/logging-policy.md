# Logging Policy

> The logging convention for **all code the SDLC produces** — shell (bash/zsh),
> Python, and the frontend (webapp). Every stack profile is born compliant; the
> entry-point templates (`bin/<tool>`, `cli.py`, `main.ts`) demonstrate it.

## The rule in one screen

- **Two levels the user selects:** `INFO` (default) and `DEBUG`. The user opts
  into `DEBUG` with **`--verbose`** (there is no separate `--debug` flag).
- **`ERROR` is always emitted** — it is not a level the user selects. Any
  error/exception is logged at `ERROR`.
- **`INFO` = general progress.** Enough for a user to see what the program is
  doing. On by default.
- **`DEBUG` = detailed progress.** The verbose story — only shown under
  `--verbose`.
- **Destination: logs go to `stderr`; only real output/data goes to `stdout`.**
  This keeps a tool's stdout clean so it can be piped and parsed. (The webapp
  analogue is the **browser console** — see below.)
- **Line format:** `<ISO-8601 UTC timestamp> <LEVEL> <name>: <message>`
  e.g. `2026-08-03T10:22:01Z INFO widgetron: Starting.`
- **Exceptions log the full stack trace** (see the per-stack notes — Python and
  the webapp carry a complete trace; shell is best-effort by nature).

There is **no `WARN` level**. Levels are `DEBUG`, `INFO`, `ERROR`.

## Why stderr, not stdout

A logging line is diagnostics, not output. Sending it to `stdout` would pollute
the tool's real result — the thing a caller pipes into `jq`, a file, or another
program. So **all three levels go to `stderr`** and `stdout` is reserved for the
data the tool exists to produce. ("Send logs to standard output" resolves, in
Unix terms, to this split.)

## Per-stack mapping

| | Shell (bash/zsh) | Python | Frontend (webapp) |
|---|---|---|---|
| Mechanism | `log_debug` / `log_info` / `log_error` helpers | stdlib `logging`, one `logger` per tool | `log.debug` / `log.info` / `log.error` → `console.*` |
| Level select | `--verbose` sets `LOG_LEVEL=DEBUG` | `--verbose` sets level to `logging.DEBUG` | `--verbose` / build flag raises to DEBUG |
| Destination | `>&2` (stderr) | `stream=sys.stderr` | browser console (DevTools) |
| Timestamp | `date -u +%Y-%m-%dT%H:%M:%SZ` | `datefmt` + `converter = time.gmtime` (UTC) | `new Date().toISOString()` |
| Exceptions | best-effort: `log_error` message + `set -e` abort — a multi-frame trace is not portable across bash/zsh | `logger.error(..., exc_info=True)` — full traceback | `console.error(msg, err)` — Error's `.stack` |

### Shell caveat (deliberate)

The shell entry template is intentionally **cross-shell** (runs under both bash
and zsh) and avoids the bash-only machinery (`BASH_SOURCE`, `FUNCNAME` arrays)
that a Python-style multi-frame stack trace would require. So in shell, "log the
error" means: emit an `ERROR` line with the message (and, where practical, the
failing context) and let `set -e` abort. Full multi-frame traces are provided by
Python and the webapp, where the runtime supports them portably.

## How it scales with the tier dial

The policy is **uniform** — the levels, destination, and format are the same at
Quick, Standard, and Full. What scales is how much you *log*: a Quick change may
add a single `INFO`/`ERROR`; a Full feature narrates its progress at `INFO` and
its detail at `DEBUG`. The mechanism never changes.

## Where this lives

- This document is the authoritative policy.
- The three profile entry-point templates
  (`payload/skills/profile-*/templates/{bin-tool,cli.py,main.ts}.tmpl`)
  implement it, so every scaffolded project inherits it.
- Generated projects get a short "Logging" note in their `design/overview.md`
  pointing back at this convention.
