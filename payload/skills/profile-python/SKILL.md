---
name: profile-python
description: >
  Stack profile for Python repos in the SDLC — the concrete "how" for the Python
  stack (uv + hatchling, src/<pkg> layout, ruff, pytest). Renders the
  profile-common backbone: best practices, performance & scale, testing pyramid,
  security, reliability & resilience, and observability. Load it at
  IMPLEMENT/VERIFY/review of a Python change, when scaffolding a Python repo, or
  to learn the Python quality bar. It owns the Python security checklist that the
  sdlc-security Full-tier gate and /sdlc-harden delegate to.
---

# Profile — Python

The concrete Python stack profile — the "how" for every dimension of a Python
change. It **clones the [`profile-common`](../profile-common/SKILL.md) backbone**
(ADR-0001): the six quality dimensions below appear in the fixed skeleton order,
each filled with the Python-specific tools, commands, and idioms. This is the
**pilot** profile (F2/#90) — the reference pattern the other stack profiles clone.

**Stack at a glance:** `uv` + `hatchling`, `src/<pkg>` layout, stdlib `argparse`
CLI, `ruff` (lint + format), `pytest`, `requires-python >= 3.11`. The scaffolding
that embodies this lives in [`templates/`](templates/) and is consumed by
`/sdlc-newproject` (see [Scaffolding](#scaffolding)).

---

## 1. Best practices

*The Python style/idiom standard and the tooling that enforces it.* (CAP-1 ·
serves UC-001.)

**Tooling — `ruff` does both lint and format** (config in `pyproject.toml`):

- **Lint:** `ruff check .` — the template selects `["E", "F", "I", "UP", "B"]`
  (pycodestyle/pyflakes, import-sort, pyupgrade, bugbear). Add `S` for security
  (see [§4](#4-security)). Run `ruff check --fix .` to auto-fix.
- **Format:** `ruff format .` (and `ruff format --check .` in `test.sh`/CI) —
  `line-length = 100`, `target-version = "py311"`. Ruff format is the single
  formatter; do not also run `black`.

**Layout & packaging:**

- **`src/<pkg>` layout** — importable code under `src/<pkg>/`, tests under
  `tests/`, `pythonpath = ["src"]` so tests import the installed package, not a
  stray top-level module. `hatchling` builds the wheel from `src/<pkg>`.
- One console entry point via `[project.scripts]` → `<pkg>.cli:main`.

**Typing (standard; checker recommended, not required):**

- Annotate **public** function signatures and dataclass fields. Prefer modern
  builtins generics (`list[str]`, `dict[str, int]`, `X | None`) over `typing.List`
  — pyupgrade (`UP`) enforces this.
- A static type checker (**`mypy`** or **`pyright`**) is **recommended** but is
  **not yet wired into the `templates/` `test.sh`** — adding it there is a
  separate `/sdlc-feature` against the templates. Until then, treat typing as a
  hand-reviewed idiom, not a gated check.

**Idioms a reviewer checks by hand:** context managers (`with`) for every
resource; specific exceptions over bare `except:`; no mutable default args;
f-strings for formatting (never for SQL or shell — see [§4](#4-security));
`pathlib` over `os.path`; comprehensions over manual accumulation where it reads
cleaner.

## 2. Performance & scale

*What makes Python performance **checkable** — named signals over existing tools,
not adjectives (ADR-0003).* (CAP-4 · serves UC-004.) The agent must **flag or
clear** the changed path against at least one named signal below.

| Signal | Observe with | Flag-or-clear bar |
|---|---|---|
| **Hot-path cost** | `python -m cProfile -s cumtime <entry>`; `timeit` for a micro-benchmark of a tight function | A single call dominates cumulative time, or a function on the changed path is called far more than expected. |
| **Algorithmic complexity** | Read the changed path | A nested loop over the same input (O(n²)) or a membership test against a `list` in a loop (use a `set`/`dict`). |
| **Blocking IO in async** | Grep the changed path for sync calls inside `async def` | A blocking call (`requests`, `time.sleep`, sync file IO, a CPU-bound loop) inside a coroutine stalls the event loop — use the async client / `asyncio.to_thread`. |
| **Unbounded memory** | Read the changed path | Building a full `list`/`dict` from an unbounded source (a large file, a full query result) instead of streaming/iterating; an ever-growing cache with no eviction. |

Named signals + existing tools (`cProfile`, `timeit`) give falsifiability without
a bespoke benchmark harness (a declared non-goal, ADR-0003). Load/stress testing
at scale is out of v1 — revisit per project need. This dimension is expected to
**deepen per project**; a thin-but-honest read of the four signals is enough to
clear a typical change.

## 3. Testing pyramid

*The Python testing standard across the pyramid and its runner.* (CAP-2 · serves
UC-002.)

- **Framework:** `pytest`. `testpaths = ["tests"]`, `pythonpath = ["src"]` in
  `pyproject.toml`.
- **Runner:** the repo's `./test.sh` runs `ruff check` → `ruff format --check` →
  `pytest`. It is what the pre-push hook and CI both call — never invoke `pytest`
  ad-hoc as the gate.
- **Layer split:**
  - **Unit** — a function/class in isolation, no boundary. The bulk of the pyramid.
  - **Integration** — the code against a **real boundary** (a live service, a DB,
    secrets, a GPU). These carry the **`@pytest.mark.integration`** marker.
  - **e2e** — drive the installed console entry point end to end.
- **The opt-in integration lane (`sdlc-common` §3).** The default run **excludes**
  the integration lane (`pytest -m "not integration"`) so PR CI stays green
  without live services or secrets; `./test.sh --integration` runs the full
  suite. Its home is **local + nightly** (the pre-push hook), and each integration
  test **self-skips when its boundary is absent** so the lane stays non-blocking.
- **Mock-obligation.** Mocking a boundary in a unit test obligates **≥1 non-mocked
  test** at that boundary in the integration lane, **plus a VERIFY run** before
  Done — a green mock only proves the mock (`sdlc-common` §3, §5).

Cross-**language** testing (python↔sql, python↔frontend) is **not** here — see
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 4. Security

*The Python security checklist + scanner.* (CAP-3 · serves UC-003.) This section
is a **stack-specific floor** delegating the review **method** and the six-category
core to the shared **`sdlc-security`** skill (§2) — walk that in full; the checks
below are the highest-signal Python-specific ones. Consumed by the `sdlc-security`
Full-tier gate (§4) and by `/sdlc-harden`.

**Scanners — run both:**

- **`ruff check --select S .`** — the primary scanner. `ruff`'s `S` rules are
  flake8-bandit (Bandit) ported into the linter we already run, so security scanning
  needs no extra tool. (Standalone **`bandit -r src/`** is the equivalent if you
  prefer it; both surface the same B-codes.)
- **`pip-audit`** — scans installed/locked dependencies for known CVEs.

**The checklist** (each check maps to the Bandit/`ruff -S` code that catches it):

- **Command injection** — `subprocess(..., shell=True)` / `os.system` with any
  interpolated value (**B602/B605/B607**). Pass an **arg list** with
  `shell=False`; never build a shell string from external data.
- **Unsafe deserialization / dynamic exec** — `pickle.load` (**B301**),
  `yaml.load` without a safe loader → use **`yaml.safe_load`** (**B506**),
  `eval`/`exec` on untrusted input (**B307**). All are remote-code-execution
  vectors.
- **SQL injection** — parameterized queries only (`cursor.execute(sql, params)`);
  never f-string / `%` / `.format()` user data into SQL (**B608**).
- **Secrets & TLS** — no secrets in code, logs, tracebacks, or `argv`; never
  `requests(..., verify=False)` (**B501**); keep keys in env / a secret store.
  Watch hard-coded passwords (**B105/B106**).
- **Weak crypto / randomness** — no MD5/SHA1 for security (**B303/B324**); use
  `secrets`, not `random`, for tokens (**B311**).
- **Path & archive traversal** — constrain paths built from input (no `../`);
  guard `tarfile`/`zipfile` extraction against Zip-Slip (**B202**); create temp
  files with `tempfile` (**B108** flags hard-coded `/tmp`).
- **Network bind & debug** — no bind-all `0.0.0.0` by default (**B104**); never
  ship `debug=True` in a web app to production (**B201**).
- **Dependencies & supply chain** — pin deps, keep the lockfile current, run
  `pip-audit`; watch for typosquatted package names and unpinned `pip install`
  from untrusted indexes.

See the shared skill: **`sdlc-security`**.

## 5. Reliability & resilience

*How Python code survives partial failure at its boundaries — timeout, retry,
backoff, idempotency, graceful degradation.* (CAP-5 · serves UC-010.)

- **Always set a timeout** on a network call — `requests` defaults to **no
  timeout** and will hang forever (`httpx` defaults to 5s, but set it explicitly
  anyway). Pass `timeout=` on every request (a connect+read tuple for
  `requests`); set a deadline on `subprocess.run(..., timeout=)`.
- **Retry transient failures with capped exponential backoff + jitter** — wrap
  the boundary call (via `tenacity`, or a small hand-rolled loop) retrying only on
  transient errors (timeouts, 5xx, connection resets), never on a 4xx/logic error.
  Cap the attempts and the total wait.
- **Idempotency & partial failure** — a retried write must be safe to repeat (an
  idempotency key, an upsert); on give-up, **fail closed** with a clear error, and
  degrade gracefully where a fallback exists (cache, default) rather than crashing
  the whole run.
- **Catch narrowly at the boundary** — handle the specific exception the boundary
  raises (`requests.Timeout`, `ConnectionError`), not a blanket `except Exception`.

**Prove it with a failure-path test.** The retry/timeout/backoff behavior needs a
test that forces the failure (a mock that times out or returns 5xx, asserting the
retry/give-up path) — **co-located with the boundary's contract test** in the
integration lane, per [`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 6. Observability & logging

*How Python renders the shared logging policy.* (CAP-6 · serves UC-009.) This
dimension **renders — does not reinvent** — the authoritative
[`design/logging-policy.md`](../../../design/logging-policy.md).

- **Mechanism:** the stdlib **`logging`** module, one `logger = logging.getLogger(<tool>)`
  per tool. Do not use `print` for diagnostics.
- **Levels:** `INFO` (default, general progress) and `DEBUG` (detail); `ERROR`
  is always emitted. There is **no `WARN`**.
- **Level select:** **`--verbose`** sets the level to `logging.DEBUG` (there is no
  separate `--debug` flag).
- **Destination:** logs go to **stderr** (`logging.StreamHandler(sys.stderr)`);
  **stdout is reserved for real data** so a caller can pipe it.
- **Format:** `<ISO-8601 UTC timestamp> <LEVEL> <name>: <message>` — set the
  handler's `datefmt` and `converter = time.gmtime` for UTC.
- **Exceptions:** log the full traceback with **`logger.error(..., exc_info=True)`**
  (or `logger.exception(...)` inside an `except`).

See the authoritative policy: **`design/logging-policy.md`**.

---

## Scaffolding

*The Python project scaffolding — the templates a new repo is generated from.*
(CAP-7.) Per ADR-0004 this section **references the existing
[`templates/`](templates/) dir; it does not copy or re-invent it** — the templates
own the files, this profile owns the standards those files must satisfy.
`/sdlc-newproject` generates a Python repo from these templates, so a scaffolded
repo is **born compliant** with the dimensions above.

A generated Python repo inherits:

- **`pyproject.toml.tmpl`** — `hatchling` build, `src/<pkg>` packaging, the `ruff`
  config (§1), the `pytest` config and the `integration` marker (§3), the
  `[project.scripts]` entry point.
- **`test.sh.tmpl`** — the single test entry point: `uv sync` → `ruff check` →
  `ruff format --check` → `pytest`, with the `--integration` lane (§3).
- **`cli.py.tmpl` / `init.py.tmpl`** — the `argparse` CLI and package init,
  demonstrating the logging policy (§6): `--verbose`, stderr, UTC timestamps.
- **`setup.sh.tmpl`, `release.sh.tmpl`, `ci.yml.tmpl`, `test-pkg.py.tmpl`** — dev
  setup, release flow, GitHub CI (runs the fast lane), and a starter test.
- **`web/` (archetype `webapp`)** — a FastAPI service instead of the CLI: `web/
  pyproject.web.toml.tmpl` (fastapi/uvicorn/gunicorn/pydantic-settings/PyJWT +
  `S` security rules on), `web/app.py.tmpl` (`/healthz`+`/readyz`, request
  logging), `web/auth.py.tmpl` (JWT-bearer `Depends`), `web/settings.py.tmpl`,
  `web/test_app.py.tmpl` (hermetic `TestClient` tests), `web/Dockerfile.tmpl`
  (non-root). See [Web / API service](#web--api-service-when-applicable).

If a template is found non-conformant with a standard here, that is a normal
`/sdlc-feature` or `/sdlc-harden` item **against the templates**, filed separately
(ADR-0004) — do not fork the standard into the profile.

## Web / API service (when applicable)

*The standard tech stack for a Python repo that runs as an app server exposing
REST APIs.* Applies to the **`webapp`** archetype; `/sdlc-newproject --profile
python --archetype webapp` scaffolds it (see [Scaffolding](#scaffolding)). A
CLI/library repo states **N/A** here.

**Standard stack — FastAPI.**

- **Framework: [FastAPI](https://fastapi.tiangolo.com/) + Pydantic v2.** Request/
  response bodies are **typed Pydantic models**, so the boundary is validated by
  the same type annotations §1 already requires — no second validation dialect.
  OpenAPI/Swagger is generated from those types (a free contract-test surface for
  consumers, ties to [Cross-profile testing](#cross-profile-testing)).
- **Server: `uvicorn` (ASGI) in dev; `gunicorn -k uvicorn.workers.UvicornWorker`
  in prod** (multi-worker process manager over the ASGI app).
- **Alternative — Django REST Framework (DRF):** reach for **DRF** when you want
  Django's ORM + admin + migrations as the point, not just a JSON API. Don't
  rebuild Django out of FastAPI + SQLAlchemy + Alembic; conversely don't pull in
  Django for a thin typed API. **Flask** is not the standard (its minimalism means
  each service re-assembles validation/docs/auth differently — the drift a
  standard exists to prevent); a team already fluent in it may keep it.

**Project shape.** Routers per resource; **dependency injection (`Depends(...)`)**
for auth, settings, and DB sessions — the seam that makes handlers unit-testable
in isolation (§3).

**Authentication & authorization.** The invariant: **every privileged endpoint is
authorized server-side via a single `Depends(...)` dependency** — never trust the
client. Three schemes, all wired the same way:

- **OAuth2 / JWT bearer** *(the reference scheme the scaffold ships)* — `Authorization:
  Bearer <token>`, verified server-side with `PyJWT` (signature **and** `exp`);
  claims carry the subject + scopes/roles for authz. Enforced by a
  `require_principal` dependency; compose a `require_scope(...)` on top for
  per-route authz.
- **API key** — a per-client key in a header, **hashed at rest**, rate-limited;
  same `Depends(...)` shape (`require_api_key`). For machine/internal callers.
- **Session cookie** — an **httpOnly, `Secure`, `SameSite`** signed cookie **plus
  CSRF protection** for state-changing requests. For browser-first, same-site apps.

Whichever scheme: authorize on the server, fail closed with a bare `401`/`403`
(never leak *why* — §4, `sdlc-security` §2.6), and keep the check in one place.

**Config — 12-factor.** All config (secrets, DB URL, CORS origins) comes from the
**environment via `pydantic-settings`** (`BaseSettings`); **no secrets in code**
(§4). CORS is an **explicit allow-list, never `"*"`** when credentials are allowed.

**Database / ORM.** When the service needs a database, the standard is
**`SQLAlchemy` 2.x** (typed models, a session per request via `Depends`) with
**Alembic** migrations. **Parameterized queries only** — never f-string user data
into SQL (§4). *(The scaffold ships without a DB by default; adding the SQLAlchemy
+ Alembic layer is the next scaffolding increment.)*

**Health & readiness.** Expose **`/healthz`** (liveness — the process is up, no
dependency checks) and **`/readyz`** (readiness — dependencies configured/
reachable; returns `503` until ready). Load balancers and k8s probes depend on
the split.

**Reliability (§5) at the server.** Set a **timeout on every outbound call** to a
downstream; retry transient failures with capped backoff; a slow downstream must
not hang a worker. **Containerization:** the shipped `Dockerfile` is the standard
shape — **pinned slim base, a non-root `USER`, gunicorn+uvicorn entry, a
`HEALTHCHECK` on `/healthz`**.

**Testing (§3).** Exercise the app in-process with **Starlette's `TestClient`**
(fast lane — no external boundary); unit-test each auth/DB `Depends` in isolation;
a test against a **real** downstream carries `@pytest.mark.integration` and lives
in the opt-in lane.

## Cross-profile testing

Cross-**profile** (cross-language) testing — a Python component tested against a
component in another stack (python↔sql, python↔frontend) — is **owned by
`profile-common`**, not by any single profile (ADR-0002). See
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).
It is a **stub fleshed out in F6 (#94)** once ≥2 real profiles exist to exercise a
boundary; the Python side contributes the contract test + the co-located
resilience failure-path test (§5) at each boundary it participates in.

---

_Traceability: renders the `profile-common` backbone (F1/#89, ADR-0001) for the
Python stack. CAP-1 (best practices), CAP-4 (performance, ADR-0003), CAP-2
(testing), CAP-3 (security — folds in #85), CAP-5 (reliability), CAP-6
(observability), CAP-7 (scaffolding, ADR-0004). The **Web / API service** section
+ the `webapp` scaffold standardize FastAPI app-server projects (framework, auth,
config, health, containerization). Serves UC-001, UC-002, UC-004, UC-005, UC-009,
UC-010. Source: `/sdlc-architecture` backlog F2 (#90); security checklist subsumes
#85._
