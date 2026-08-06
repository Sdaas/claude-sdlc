---
name: profile-python
description: >
  Stack profile for Python repos in the SDLC — the concrete "how" for the Python
  stack. Currently carries the profile's starter security checklist, consumed by
  the sdlc-security Full-tier gate and by /sdlc-harden. Fuller profile content
  (uv + hatchling, src layout, ruff, pytest conventions) lives in the templates/
  dir for now; this SKILL.md will grow to own it.
---

# Profile — Python

The Python stack profile (`uv` + hatchling, `src/<pkg>` layout, `ruff`, pytest).
Scaffolding conventions currently live in `templates/`; this `SKILL.md` will grow
to own the full profile. For now it carries the **security checklist** that
`sdlc-security` (§4) and `/sdlc-harden` delegate to.

## Security checklist (starter — non-exhaustive, see #85)

> A **floor, not a ceiling.** Walk `sdlc-security` §2 in full; these are the
> highest-signal Python-specific checks. Fleshing this out is tracked as **#85**.

- **Command injection.** `subprocess(..., shell=True)` and `os.system` with any
  interpolated value — pass an arg **list** with `shell=False`; never build a
  shell string from external data.
- **Unsafe deserialization.** `pickle.load`, `yaml.load` (use `yaml.safe_load`),
  and `eval`/`exec` on untrusted input are remote-code-execution vectors.
- **SQL injection.** Parameterized queries only (`cursor.execute(sql, params)`);
  never f-string / `%`-format user data into SQL.
- **Secrets & TLS.** No secrets in code, logs, or tracebacks; never
  `requests(..., verify=False)`; keep keys in env/secret store.
- **Path & archive traversal.** Constrain paths built from input (no `../`); guard
  `tarfile`/`zipfile` extraction (Zip Slip); use `tempfile` for temp files.
- **Dependencies.** Pin deps, keep the lockfile current, run `pip-audit`; watch
  for typosquatted package names.
