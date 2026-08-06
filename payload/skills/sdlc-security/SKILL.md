---
name: sdlc-security
description: >
  The concrete, followable security-review checklist behind the Full-tier
  security-review gate. Load this whenever a Full-tier /sdlc-feature,
  /sdlc-bugfix, or /sdlc-harden run reaches its security-review pass. Defines the
  stack-agnostic six-category review keyed to the change's boundary inventory,
  the findings format (so the gate produces specific findings, not "looks fine"),
  how it pairs with the harness `/security-review` skill, and how stack-specific
  checks are delegated to the matching profile's security section. The command
  that loaded this skill walks the gate sequence; this skill defines what the
  security pass actually checks.
---

# SDLC — Security Review

The rulebook for the **security-review gate** that runs at **Full tier** (and any
time the human asks for one). Without it the gate is theater — "also a
security-review pass" with nothing to check. This skill makes the pass concrete:
a followable checklist that yields **specific findings**.

It builds on `sdlc-common` (tiers, paths, the boundary inventory, governance,
hard rules) — load that too. It is **stack-agnostic**: it owns the review
**workflow and the checklist core**; the concrete, stack-specific checks are
**delegated to the matching profile's security section** (see §4).

## How to run the pass (two complementary tools)

Run **both**, checklist-led:

1. **`/security-review`** (harness built-in) — an automated scan of the pending
   diff on the branch. Fast, catches known-bad patterns. It does **not** know the
   change's boundary inventory or intent, so it is a starting point, not the pass.
2. **This checklist** (§2) — the authority. Walk it **against the change's
   boundary inventory** (the external boundaries enumerated at the INTERVIEW
   gate: network services, subprocesses/CLIs, the filesystem, runtime
   dependencies, user-facing entry points). For **each boundary**, ask the §2
   questions. Fold the built-in's output into your findings; do not stop at it.

Report every issue in the **findings format** (§3). "Looks fine" is not an
acceptable result unless you can name the boundaries you checked and why each is
safe.

## 1. Scope the review to the change

You are reviewing **this change**, not auditing the whole repo. Anchor on:

- The **boundary inventory** from INTERVIEW/DESIGN — the security surface is
  where the change **crosses a trust boundary** (untrusted input enters, or a
  secret / privileged action leaves).
- The **diff** — new code paths, new inputs, new dependencies, new commands, new
  files written. A boundary the change does not touch is out of scope for this
  pass (note it, move on).

If the change touches **no** boundary and introduces no new dependency or
privileged action, say so in one line and the pass is complete — there is nothing
to attack.

## 2. The checklist (six categories, stack-agnostic core)

Walk each category against every boundary in scope. Each profile refines these
with concrete, stack-specific checks (§4).

1. **Input validation & injection.** Is external input (args, request bodies,
   env, file contents, CLI output) validated and safely handled before it reaches
   an interpreter — a shell, SQL, a template, a filesystem path, `eval`,
   deserialization? Untrusted data must never be concatenated into a command,
   query, or markup string. *(Boundaries: network, subprocess/CLI, filesystem,
   user-facing entry point.)*
2. **Secrets & credential handling.** Are secrets kept out of source, logs,
   error messages, `argv`, and any committed file? Read from env/secret store,
   never echoed, never in a stack trace. No new secret committed by this change.
   *(Boundaries: filesystem, network, dependency, logging.)*
3. **AuthZ & access control.** Does the change add or alter who-can-do-what? Is
   every new privileged action authorized on the server/trusted side (not the
   client)? No new path that skips an existing check; least privilege for any new
   token/role/file mode. *(Boundaries: network service, user-facing entry point.)*
4. **Filesystem & path safety.** Are paths built from untrusted input constrained
   (no `../` traversal, no symlink-following into a privileged target, no TOCTOU
   race)? Temp files created safely with tight permissions and cleaned up.
   *(Boundaries: filesystem, subprocess/CLI.)*
5. **Dependency & supply-chain.** Does the change add/upgrade a dependency? Is it
   pinned, from a trusted source, and audited (no known CVE, no typosquat, no
   unvetted `curl | sh` or CDN script)? Lockfile updated. *(Boundaries:
   dependency, network.)*
6. **Output & error handling (info leak).** Do errors, logs, or responses leak
   internal detail — stack traces, full paths, secrets, existence oracles — to an
   untrusted consumer? Fail closed, not open. *(Boundaries: network, user-facing
   entry point, logging.)*

## 3. Findings format (produce specifics, not verdicts)

Report each finding as one line so the human can triage:

```
[SEVERITY] category · boundary — the issue → the fix
```

- **SEVERITY** — `HIGH` (exploitable / secret exposure) · `MED` (needs a
  precondition or defense-in-depth gap) · `LOW` (hardening / hygiene).
- **category** — one of the six (§2). **boundary** — which inventory boundary.
- **the issue** — the concrete weakness, with the file/line. **the fix** — the
  specific remediation.

Example:
`[HIGH] injection · subprocess — apply.sh:132 passes $rel unquoted into cp → quote it / use printf %q`

Then **fix HIGH and MED findings** as part of the change (loop back to IMPLEMENT
if a fix is nontrivial). Record LOW findings the human declines as backlog issues.
End the pass with either a findings list or an explicit **"reviewed boundaries
X, Y, Z — no findings; here is why each is safe."**

## 4. Profile delegation (stack-specific checks)

The six categories are stack-agnostic; the **concrete** checks come from the
matching profile's security section (`sdlc-common` §7 — read the repo's
`CLAUDE.md` marker; if absent, infer the stack):

- **shell** → `profile-shell` `## Security checklist` (injection via unquoted
  expansion/`eval`, secrets in `argv`, temp-file/symlink safety).
- **python** → `profile-python` `## Security checklist` (`subprocess(shell=True)`,
  `yaml.load`/`pickle`, SQL string-building, deserialization).
- **frontend** → `profile-frontend` `## Security checklist` (`innerHTML`/
  `dangerouslySetInnerHTML` XSS, secrets in the bundle, dependency audit).

**Honest scope note.** The per-profile security sections currently ship as
**starters — non-exhaustive** (fleshing them out is tracked per profile: shell
#84, python #85, frontend #86). Treat a starter section as a floor, not a
ceiling: walk the stack-agnostic six (§2) fully even where the profile is thin,
and flag "no deep security checklist for `<profile>` yet" rather than implying the
starter is complete. A profile with **no** security section at all is itself a
finding — note it and fall back to §2. `/sdlc-harden` consumes the same profile
sections for its audit (#87), so one source of profile-security truth serves both.

## 5. What "done" means here

The security pass is Done when: `/security-review` has run on the diff; the §2
checklist has been walked against **every in-scope boundary** with its profile
refinement (§4); all **HIGH/MED** findings are fixed (or escalated with the
human's explicit sign-off); and the result is a **specific findings list or a
named-boundaries "no findings, here is why"** — never a bare "looks fine".

## References

- `sdlc-common` — tiers, boundary inventory, code/prose paths, governance (load first).
- `/security-review` — the harness built-in that scans the pending diff (§ how-to).
- `profile-{shell,python,frontend}` `## Security checklist` — stack-specific checks (§4).
