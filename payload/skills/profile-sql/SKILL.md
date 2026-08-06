---
name: profile-sql
description: >
  Stack profile for SQL / relational-database work in the SDLC — the concrete
  "how" for schema, migrations, and queries (PostgreSQL as the reference dialect,
  portable-first; sqlfluff, EXPLAIN ANALYZE, pgTAP). Renders the profile-common
  backbone: best practices, performance & scale, testing pyramid, security,
  reliability & resilience, and observability. Load it at IMPLEMENT/VERIFY/review
  of a schema/migration/query change, or to learn the SQL quality bar. It owns
  the SQL security checklist that the sdlc-security Full-tier gate and
  /sdlc-harden delegate to.
---

# Profile — SQL

The concrete SQL / relational-database stack profile — the "how" for every
dimension of a schema, migration, or query change. It **clones the
[`profile-common`](../profile-common/SKILL.md) backbone** (ADR-0001): the six
quality dimensions below appear in the fixed skeleton order, each filled with
SQL-specific tools, commands, and idioms — following the F2
[`profile-python`](../profile-python/SKILL.md) reference pattern and the F3
[`profile-shell`](../profile-shell/SKILL.md) clone.

Unlike shell and python, **SQL is inherently multi-dialect**. This profile takes
**PostgreSQL as the concrete reference** — every "run this" command is Postgres —
but is **portable-first**: each standard leads with the portable rule and calls
out where **MySQL** / **SQLite** (and others) diverge, so a team on another engine
still gets an actionable bar rather than Postgres trivia.

**Stack at a glance:** ANSI-SQL-first with **PostgreSQL** as reference dialect,
`snake_case` identifiers, versioned forward-only migrations (tool-neutral —
Alembic / Flyway / Liquibase / sqitch), **`sqlfluff`** (dialect-aware lint +
format), `EXPLAIN (ANALYZE, BUFFERS)` for plans, **pgTAP**/`pg_prove` for in-DB
tests. **SQL ships no scaffolding in v1** (see [Scaffolding](#scaffolding)) — a
SQL change lives inside a host application repo and runs through *that* repo's
`./test.sh`.

---

## 1. Best practices

*The SQL style/idiom standard and the tooling that enforces it.* (CAP-1 · serves
UC-001.)

**Tooling — `sqlfluff` lints and formats** (config in `.sqlfluff`, set
`dialect = postgres` or your engine):

- **Lint:** `sqlfluff lint .` — a **dialect-aware** analyzer that catches
  layout, capitalization, ambiguous references, and unqualified columns. It is
  the SQL parallel to `ruff` / `shellcheck` and is also the primary security
  linter (see [§4](#4-security)). Fix findings; suppress only with a justified
  inline `-- noqa: <rule>` naming the reason.
- **Format:** `sqlfluff format .` (and `sqlfluff lint` in the host `test.sh`/CI) —
  one formatter, consistent keyword case and indentation.

**Naming & schema conventions (portable):**

- **`snake_case`** for tables, columns, and constraints; singular-or-plural table
  names, chosen once and kept consistent. Name constraints explicitly
  (`pk_`/`fk_`/`uq_`/`ck_` prefixes) so a migration diff and an error message name
  the object, not a generated hash.
- **Every table has an explicit primary key**; declare foreign keys, `NOT NULL`,
  `UNIQUE`, and `CHECK` constraints in the schema — the database is the last line
  of integrity, not the app. Prefer surrogate keys (`bigint`/`uuid`) with natural
  keys enforced by a `UNIQUE` constraint.
- **Types portably:** timestamps as `timestamptz` (Postgres) / `TIMESTAMP` — store
  UTC; money as `numeric`/`DECIMAL`, never `float`. Watch divergence: `SERIAL`
  vs. `AUTO_INCREMENT` vs. `INTEGER PRIMARY KEY` (SQLite); `boolean` is emulated as
  `TINYINT` in MySQL and has no dedicated type in SQLite.

**Migration conventions (tool-neutral — the *convention* is the standard, not the
tool):**

- **Versioned, ordered, and checked in** — migrations live in the repo, applied in
  a fixed order, with a recorded version table. Common tools: **Alembic** (the
  stack profile-python's webapp section already names), **Flyway**, **Liquibase**,
  **sqitch** — pick one per repo; the conventions below hold for all.
- **Forward-only, one logical change per migration**, small and reviewable. Provide
  a **reversible down** where practical; where a down is unsafe (a destructive
  data change), say so explicitly rather than shipping a lossy rollback.
- **Expand/contract for zero-downtime**: add nullable → backfill → enforce →
  drop old, across separate migrations, so a deploy never requires the app and
  schema to change in lockstep.

**Idioms a reviewer checks by hand:** explicit column lists (never `SELECT *` in
app code); qualified column references in multi-table queries; set-based
operations over row-by-row cursors; `JOIN … ON` over comma-joins; explicit
transaction boundaries; and portability — flag engine-specific syntax that the
target dialects (MySQL/SQLite) don't share.

## 2. Performance & scale

*What makes SQL performance **checkable** — named signals over the query planner,
not adjectives (ADR-0003).* (CAP-4 · serves UC-004.) The agent must **flag or
clear** the changed query/schema against at least one named signal below.

| Signal | Observe with | Flag-or-clear bar |
|---|---|---|
| **Full-table scan / missing index** | `EXPLAIN (ANALYZE, BUFFERS) <query>` (Postgres); `EXPLAIN ANALYZE` (MySQL); `EXPLAIN QUERY PLAN` (SQLite) | A `Seq Scan` / full scan on a large table where a filter or join column has no supporting index. Add the index, or justify the scan (small/one-off table). |
| **N+1 query pattern** | Read the changed app path; count queries per request | A query issued **once per row** of a prior result (the ORM lazy-load trap) instead of one set-based join / `IN` / batched fetch. |
| **Non-SARGable predicate** | Read the query + its `EXPLAIN` | A function or cast wrapping an indexed column (`WHERE lower(email) = …`, `WHERE col::text = …`, leading-wildcard `LIKE '%x'`) defeats the index — rewrite, or add an expression/functional index. |
| **Unbounded result / row growth** | Read the query; check row-count assumptions | `SELECT` with no `LIMIT`/pagination over a table that grows without bound; a join whose cardinality multiplies rows. Paginate with keyset (`WHERE id > :last`) over large `OFFSET`. |

Reading the **query plan** gives falsifiability without a bespoke benchmark
harness (a declared non-goal, ADR-0003). For a real timing, `EXPLAIN ANALYZE`
reports actual vs. estimated rows and execution time. Load/stress testing at
scale is out of v1 — revisit per project need. This dimension is expected to
**deepen per project** as real data volumes and access patterns emerge; a
thin-but-honest read of the signals against the changed path is enough to clear a
typical change.

## 3. Testing pyramid

*The SQL testing standard across the pyramid and its runner.* (CAP-2 · serves
UC-002.)

- **Runner — the host app's `./test.sh`.** SQL has **no standalone test runner of
  its own** (and no scaffolding — see [Scaffolding](#scaffolding)): a schema or
  migration lives inside a consuming application repo, so its tests run through
  **that repo's `./test.sh`** (e.g. `pytest` against a real database for a Python
  repo). Never invent an ad-hoc SQL test command as the gate.
- **Layer split:**
  - **Unit** — a single function/view/query or a `CHECK`/constraint in isolation.
    Pure-SQL logic can be unit-tested **in-database with [pgTAP](https://pgtap.org/)**,
    run via **`pg_prove`** (the Postgres parallel to bats' single-purpose runner).
  - **Integration** — migrations and queries against a **real database**: apply
    every migration **up** on an empty DB (and **down** where reversible), then
    assert the resulting schema and query results.
  - **e2e** — the host application driving real queries end to end against a
    seeded database.
- **What to test:** migration **up/down** correctness, schema constraints actually
  reject bad rows, query correctness against **seed-data fixtures** (a known,
  version-controlled dataset), and idempotency of re-runnable migrations.
- **The opt-in DB-integration lane (`sdlc-common` §3).** Tests needing a live
  database live in the host repo's **opt-in integration lane** (`pytest -m
  integration` / `./test.sh --integration`), **local + nightly**, and each test
  **self-skips when no database is present** (no `DATABASE_URL` / no reachable
  server) so PR CI stays green without a provisioned DB.
- **Mock-obligation.** Mocking the database in a unit test obligates **≥1
  non-mocked test** against a real database in the integration lane, **plus a
  VERIFY run** before Done — a green mock only proves the mock (`sdlc-common` §3,
  §5). SQL is the boundary the mock stands in for; prove it once for real.

Cross-**language** testing (python↔sql, shell↔sql) is **not** here — see
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 4. Security

*The SQL security checklist + scanner.* (CAP-3 · serves UC-003.) This is a **new
section** — SQL was absent from the earlier per-stack security work (#84–86), so
this profile establishes the SQL floor from scratch. It is a **stack-specific
floor** delegating the review **method** and the six-category core to the shared
**`sdlc-security`** skill (§2) — walk that in full; the checks below are the
highest-signal SQL-specific ones. Consumed by the `sdlc-security` Full-tier gate
(§4) and by `/sdlc-harden`.

**Scanners:**

- **`sqlfluff`** — the primary linter ([§1](#1-best-practices)), reused here: its
  templating/parsing surfaces dynamically-assembled SQL and unqualified-reference
  smells that correlate with injection risk. Static SQL analysis needs no extra
  tool for these.
- **`gitleaks`** — the gap `sqlfluff` does **not** cover: connection strings,
  passwords, and DSNs committed in migration files, seed data, or `.sql` scripts.
  Run `gitleaks detect` as the secret-scanning companion.

**The checklist** (each maps to a concrete SQL vector):

- **Injection / parameterization** — **parameterized queries only** (bind
  parameters / prepared statements: `WHERE id = $1`); **never** concatenate or
  interpolate external data into a SQL string. Dynamic identifiers (table/column
  names, which can't be bound) must be **allow-listed**, never passed through from
  input. `sqlfluff` flags the string-built SQL smell; the host-language profile
  (e.g. `ruff -S` **B608**) flags it at the call site.
- **Least-privilege grants** — the application role gets only the `GRANT`s it
  needs (`SELECT`/`INSERT`/`UPDATE`/`DELETE` on named tables), **never** `SUPERUSER`
  / `DBA` / `ALL PRIVILEGES` for routine app access. Separate migration
  (DDL-capable) and runtime (DML-only) roles. Revoke the default `PUBLIC` schema
  grants. Consider **row-level security** (Postgres RLS) for multi-tenant data.
- **Secrets & connection strings** — no passwords, DSNs, or connection URLs in
  migrations, seed files, code, or logs; source them from the environment / a
  secret store (see the host profile's config standard). Require **TLS** on the
  connection (`sslmode=require` and verify the cert where possible). `gitleaks`
  guards the committed-secret case.
- **PII handling** — classify columns holding personal data; **encrypt at rest**
  (or application-layer for the most sensitive), **mask/redact** in non-prod
  copies and in logs (see [§6](#6-observability--logging) — never log row data),
  and honor **retention/deletion** (a documented purge path, not indefinite
  storage). Least-privilege (above) limits who can read PII at all.
- **`search_path` & definer safety** — `SECURITY DEFINER` functions run with the
  **owner's** privileges: pin an explicit `search_path` on them (a mutable
  `search_path` lets a caller shadow a referenced object and hijack execution).
  Prefer `SECURITY INVOKER` unless elevation is the deliberate point.
- **Destructive-DDL & data-loss guards** — a migration with `DROP` / `TRUNCATE` /
  a wide `DELETE`/`UPDATE` gets extra review; wrap it in a transaction, take a
  backup/snapshot first, and confirm the `WHERE` clause. An unbounded
  `UPDATE`/`DELETE` (no `WHERE`) is the SQL parallel to `rm -rf` — guard it.

See the shared skill: **`sdlc-security`**.

## 5. Reliability & resilience

*How SQL code survives partial failure at its boundaries — timeouts, transaction
safety, retry on transient errors, idempotency, null semantics.* (CAP-5 · serves
UC-010.)

- **Set timeouts.** A connection or query can hang forever; set a **connection
  timeout** and a **statement timeout** (`SET statement_timeout` in Postgres, or
  the driver's `statement_timeout`/`max_execution_time`) so a stuck query aborts
  rather than pinning a connection. Bound migration lock waits (`lock_timeout`) so
  a blocked `ALTER` fails fast instead of queueing behind traffic.
- **Transaction / rollback safety.** Wrap a multi-statement change in an explicit
  transaction so it commits **all or nothing**; on error, **roll back** cleanly
  and release locks. Keep transactions short — a long-held transaction blocks
  vacuum and other writers. Choose the **isolation level** deliberately
  (`READ COMMITTED` default; `SERIALIZABLE` when correctness needs it).
- **Retry transient failures with capped backoff.** Retry **only** transient
  errors — a **deadlock** (Postgres `40P01`), a **serialization failure** (`40001`
  under `SERIALIZABLE`/`REPEATABLE READ`), or a connection reset — with
  exponential-ish backoff and a capped attempt count; **never** retry a constraint
  violation or other deterministic/logic error. Use a **connection pool** with
  health-checked connections so a dropped backend is recycled, not reused.
- **Idempotency.** A retried migration or write must be safe to repeat: guard DDL
  with `IF NOT EXISTS` / `IF EXISTS`, prefer **`INSERT … ON CONFLICT`** (upsert)
  over blind insert, and make backfills resumable (bounded batches keyed by a
  cursor). On give-up, **fail closed** with a clear error and a non-zero exit.
- **NULL semantics — handle explicitly.** SQL three-valued logic bites: `NULL =
  NULL` is **unknown** (use `IS NULL` / `IS DISTINCT FROM`); `NOT IN (… NULL …)`
  silently returns no rows; aggregates skip `NULL`; and a `UNIQUE` constraint
  treats `NULL`s as distinct. Decide `NULL` vs. a sentinel/`DEFAULT` per column
  and test the boundary.

**Prove it with a failure-path test.** The timeout/retry/rollback behavior needs
a test that forces the failure (induce a deadlock/serialization error or a
statement-timeout and assert the retry/give-up path) — **co-located with the
boundary's contract test** in the integration lane, per
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 6. Observability & logging

*How SQL renders the shared logging policy.* (CAP-6 · serves UC-009.) This
dimension **renders — does not reinvent** — the authoritative
[`design/logging-policy.md`](../../../design/logging-policy.md). SQL's "logs" are
the **database server's** diagnostics plus the host application's query logging;
this profile maps those to the policy (it is **real for SQL, not N/A**).

- **Mechanism:** the database server log plus host-app query logging. In Postgres,
  **`log_min_duration_statement`** logs any statement slower than a threshold (the
  slow-query log — the primary performance-observability lever, ties to
  [§2](#2-performance--scale)); **`auto_explain`** captures the **plan** of slow
  statements automatically for after-the-fact diagnosis. MySQL's `slow_query_log`
  + `long_query_time` are the equivalents.
- **Levels:** map server verbosity to the policy — routine progress at `INFO`,
  detailed statement/plan logging at `DEBUG` (enabled deliberately, not in steady
  state), and failures always at `ERROR`. There is **no `WARN`** in the policy.
- **Level select:** the host tool's **`--verbose`** turns on the detailed
  (statement/plan) logging; steady state stays quiet so `stdout`/query output is
  the real data.
- **Destination:** diagnostics go to the **server log / stderr**, **never mixed
  into query result output** — a caller consuming rows must not receive log lines.
- **Never log secrets or PII** ([§4](#4-security)): bind-parameter **values** and
  personal-data columns must be redacted/masked in any statement logging; log the
  parameterized statement text, not the substituted row data.

See the authoritative policy: **`design/logging-policy.md`**.

---

## Scaffolding

**`N/A — why`.** SQL ships **no scaffolding** in v1 (CAP-7 covers shell and python
only; ADR-0004). There is no `profile-sql/templates/` dir and `/sdlc-newproject`
does not generate a standalone SQL repo — a SQL change lives **inside a host
application repo** (a Python service, etc.), and inherits that repo's scaffolding
(entry point, `test.sh`, hooks, logging). The section is kept, not dropped, per
the profile-common rule that **"N/A is stated, never dropped"** (ADR-0001): a
missing section reads as an oversight; an explicit N/A is a decision. If a v1+
project needs standalone SQL scaffolding (a migrations skeleton, a seed harness),
that is a future `/sdlc-feature` against a new `templates/` dir — filed
separately, not forked into this profile.

## Cross-profile testing

Cross-**profile** (cross-language) testing — a SQL schema/query tested against a
component in another stack (**python↔sql**, **shell↔sql**) — is **owned by
`profile-common`**, not by any single profile (ADR-0002). See
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).
It is a **stub fleshed out in F6 (#94)** once ≥2 real profiles exist to exercise a
boundary; the SQL side contributes the schema/query **contract test** (the app's
query matches the live schema) + the co-located resilience failure-path test
([§5](#5-reliability--resilience)) at each boundary it participates in. SQL is the
canonical **real boundary** the `sdlc-common` §3 mock-obligation rule targets: the
one un-mocked run at VERIFY exercises a live database before Done.

---

_Traceability: renders the `profile-common` backbone (F1/#89, ADR-0001) for the
SQL stack, cloning the F2/`profile-python` (#90) + F3/`profile-shell` (#91)
pattern. CAP-1 (best practices), CAP-4 (performance, ADR-0003 — query plans),
CAP-2 (testing — via the host app's `test.sh`), CAP-3 (security — the **new** SQL
checklist, sql was absent from #84–86), CAP-5 (reliability), CAP-6
(observability). Scaffolding is **N/A** for SQL (CAP-7 shell/python only,
ADR-0004). PostgreSQL is the reference dialect, portable-first (MySQL/SQLite
divergence called out). Serves UC-001 (best practices), UC-002 (testing), UC-004
(performance), UC-009 (observability), UC-010 (reliability). Source:
`/sdlc-architecture` backlog F4 (#92)._
