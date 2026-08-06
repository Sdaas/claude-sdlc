---
name: profile-frontend
description: >
  Stack profile for frontend / TypeScript repos in the SDLC — the concrete "how"
  for the frontend stack (Vite + framework-neutral vanilla TS, Vitest,
  tsc --noEmit + prettier). Renders the profile-common backbone: best practices,
  performance & scale, testing pyramid, security, reliability & resilience, and
  observability. Load it at IMPLEMENT/VERIFY/review of a frontend change, when
  scaffolding a frontend repo, or to learn the frontend quality bar. It owns the
  frontend security checklist that the sdlc-security Full-tier gate and
  /sdlc-harden delegate to.
---

# Profile — Frontend

The concrete frontend / TypeScript stack profile — the "how" for every dimension
of a browser-facing change. It **clones the
[`profile-common`](../profile-common/SKILL.md) backbone** (ADR-0001): the six
quality dimensions below appear in the fixed skeleton order, each filled with
frontend-specific tools, commands, and idioms — following the F2
[`profile-python`](../profile-python/SKILL.md) reference pattern and the F3
[`profile-shell`](../profile-shell/SKILL.md) / F4
[`profile-sql`](../profile-sql/SKILL.md) clones.

**Framework-neutral by design.** The stack is **Vite + vanilla TypeScript**, no
React or other framework baked in, so the profile is a **reusable base** rather
than a commitment to one framework for every project. React/Vue/Svelte idioms are
called out where they differ, but the standards below hold for plain TS and
transfer to any framework layered on top. (A richer React-specific profile —
component testing, ESLint configs, publish flow — is a documented next iteration.)

**Stack at a glance:** **Vite** (dev server + build), **TypeScript** in `strict`
mode (`tsc --noEmit` as the type gate), **`prettier`** (format), **Vitest** (unit
+ component), **`npm`** + a committed lockfile, **Playwright** as the e2e option.
ESLint is **not yet wired** into the scaffold (a documented fast-follow). The
scaffolding that embodies this lives in [`templates/`](templates/) and is consumed
by `/sdlc-newproject` (see [Scaffolding](#scaffolding)).

---

## 1. Best practices

*The frontend style/idiom standard and the tooling that enforces it.* (CAP-1 ·
serves UC-001.)

**Tooling — `tsc` type-checks, `prettier` formats:**

- **Type-check:** `tsc --noEmit` with **`strict: true`** in `tsconfig.json` — the
  primary correctness gate (there is no separate compile step; Vite/esbuild
  transpiles, `tsc` type-checks). Run it in `test.sh`/CI. Treat a type error as a
  build failure, not a warning.
- **Format:** `prettier --check .` (in `test.sh`/CI) and `prettier --write .` to
  apply — one formatter, no bikeshedding. A `.prettierignore` excludes build
  output (`dist/`).
- **Lint (future):** **ESLint is not yet in the scaffold** — adding it (with
  `@typescript-eslint`) is a separate `/sdlc-feature` against the templates. Until
  then, `tsc --strict` + prettier + hand review are the gate; do not pretend a
  lint step exists that doesn't.

**Language & layout:**

- **TypeScript, not JavaScript**, for app code; **avoid `any`** (prefer `unknown` +
  narrowing, generics, and discriminated unions). Enable `strict`,
  `noUncheckedIndexedAccess`, and `noImplicitOverride` where the project tolerates
  it.
- **ES modules** (`"type": "module"`), `import`/`export` — no CommonJS in new
  code. Framework-neutral `src/` layout (entry + modules + `*.test.ts` co-located
  or under `tests/`).
- **The platform is the baseline:** prefer standard DOM/Fetch/URL APIs over a
  dependency where they suffice; reach for a library when it earns its bundle cost
  (see [§2](#2-performance--scale)).

**Idioms a reviewer checks by hand:** no `any` smuggled through a cast; narrow
`unknown` at boundaries (a `fetch` response is `unknown` until validated); `const`
over `let`; optional chaining / nullish coalescing (`?.`, `??`) over truthy
checks that swallow `0`/`""`; and framework escaping over manual DOM string-building
(ties to [§4](#4-security)).

## 2. Performance & scale

*What makes frontend performance **checkable** — named signals over existing
tools, not adjectives (ADR-0003).* (CAP-4 · serves UC-004.) The agent must **flag
or clear** the changed path against at least one named signal below.

| Signal | Observe with | Flag-or-clear bar |
|---|---|---|
| **Bundle-size budget** | `vite build` output (per-chunk sizes); `rollup-plugin-visualizer` for a treemap | A dependency (or a barrel import pulling a whole library) bloats a chunk past the project's budget. Prefer a lighter dep, tree-shakeable named imports, or a dynamic `import()` to code-split. |
| **Render / re-render cost** | Browser DevTools **Performance** panel; framework devtools (React Profiler, etc.) | A component re-rendering far more than its inputs change, or a large list rendered without virtualization. Memoize / key correctly / virtualize. |
| **Network waterfall** | DevTools **Network** panel | Serial request chains that could be parallel; a request blocking first paint; missing caching/compression. Parallelize, preload critical resources, lazy-load the rest. |
| **Main-thread blocking** | DevTools **Performance** → long tasks (>50ms) | A synchronous loop, large JSON parse, or heavy computation on the main-thread janks interaction (a long task). Chunk the work, defer it, or move it to a Web Worker. |

Named signals + browser-native tooling give falsifiability without a bespoke
benchmark harness (a declared non-goal, ADR-0003). For field data, **Lighthouse**
(or the Core Web Vitals — LCP/INP/CLS) scores the entry point. This dimension is
expected to **deepen per project** as real bundles and interactions emerge; a
thin-but-honest read of the four signals is enough to clear a typical change.

## 3. Testing pyramid

*The frontend testing standard across the pyramid and its runner.* (CAP-2 · serves
UC-002.)

- **Framework:** **Vitest** (Vite-native, Jest-compatible API). `npm test` runs
  `vitest run`.
- **Runner:** the repo's `./test.sh` runs `tsc --noEmit` → `prettier --check` →
  `vitest run` (and guards on `node`/`npm` being present). It is what the pre-push
  hook and CI both call — never invoke `vitest` ad-hoc as the gate.
- **Layer split:**
  - **Unit** — a pure function/module in isolation, no DOM, no network. The bulk
    of the pyramid.
  - **Component** — a component/DOM unit rendered in a simulated DOM
    (**`jsdom`/`happy-dom`** as Vitest's environment) and queried with
    **`@testing-library/dom`** (or the framework binding) — assert on
    role/text/behavior, not implementation details.
  - **Integration** — the code against a **real boundary** (a live API, a real
    backend, secrets). These live in the opt-in lane.
  - **e2e** — drive the built app in a real browser end to end with
    **[Playwright](https://playwright.dev/)** (the named e2e option; not shipped in
    the scaffold by default).
- **The opt-in integration lane (`sdlc-common` §3).** The default run excludes
  live-boundary tests so PR CI stays green without a backend or secrets;
  `./test.sh --integration` (or the project's lane flag) adds them. Its home is
  **local + nightly**, and each integration test **self-skips when its boundary is
  absent** (no API base URL / no server) so the lane stays non-blocking.
- **Mock-obligation.** Mocking `fetch`/an API in a unit or component test obligates
  **≥1 non-mocked test** at that boundary in the integration lane, **plus a VERIFY
  run** before Done — a green mock only proves the mock (`sdlc-common` §3, §5).

Cross-**language** testing (frontend↔python, frontend↔sql) is **not** here — see
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 4. Security

*The frontend security checklist + scanner.* (CAP-3 · serves UC-003.) This section
is a **stack-specific floor** delegating the review **method** and the six-category
core to the shared **`sdlc-security`** skill (§2) — walk that in full; the checks
below are the highest-signal frontend-specific ones. This is the **fleshed-out**
checklist (folds in #86; the earlier "starter" is subsumed). Consumed by the
`sdlc-security` Full-tier gate (§4) and by `/sdlc-harden`.

**Scanners — run both:**

- **`npm audit`** — scans the dependency tree for known CVEs (`npm audit --audit-level=high`
  in CI). The client bundle *is* its dependencies, so a vulnerable transitive dep
  ships to every user.
- **`gitleaks`** — the gap `npm audit` does **not** cover: secrets/API keys/tokens
  committed to the repo or inlined into the bundle. Run `gitleaks detect`.

**The checklist** (each maps to a concrete frontend vector):

- **XSS / DOM injection** — the top frontend risk. **`innerHTML`**,
  **`dangerouslySetInnerHTML`** (React), **`document.write`**, `insertAdjacentHTML`,
  and unsanitized templating with user data all execute injected markup. Prefer
  **`textContent`** and framework escaping; if you must inject HTML, **sanitize
  with DOMPurify** and constrain it. Never build DOM from an untrusted string.
- **Secrets in the client bundle** — anything inlined at build time (env vars,
  API keys, tokens) is **shipped to every user and public**. Keep secrets
  server-side; only `VITE_`-prefixed / explicitly-public values reach the client.
  `gitleaks` guards the committed case.
- **Cross-origin messaging & tabnabbing** — validate **`event.origin`** (and
  `event.source`) in every `postMessage` handler; add **`rel="noopener noreferrer"`**
  to `target="_blank"` links (reverse-tabnabbing lets the opened page rewrite
  `window.opener.location`); set a restrictive **Content-Security-Policy (CSP)** to
  contain injection and disallow inline script.
- **Auth token storage & CSRF** — prefer **httpOnly, `Secure`, `SameSite` cookies**
  over **`localStorage`** for auth tokens (a token in `localStorage` is readable by
  any XSS); protect state-changing requests against **CSRF** (SameSite + a CSRF
  token for cross-site forms).
- **Dependency & supply chain** — commit the **lockfile**, run **`npm audit`**, and
  avoid unvetted CDN **`<script>`** tags; if you must load from a CDN, pin the
  version and add **Subresource Integrity (SRI)** hashes. Watch typosquatted
  package names and postinstall scripts.
- **Clickjacking & framing** — set `X-Frame-Options`/CSP `frame-ancestors` so the
  app can't be embedded in a hostile iframe for UI-redress attacks.

See the shared skill: **`sdlc-security`**.

## 5. Reliability & resilience

*How frontend code survives partial failure at its boundaries — null/undefined
safety, error boundaries, timeout, retry, backoff, offline handling.* (CAP-5 ·
serves UC-010.)

- **Null/undefined safety.** `strict` TypeScript catches most, but network JSON is
  `unknown` at runtime — **validate at the boundary** (a schema check / type guard,
  e.g. `zod`) rather than trusting the type. Use optional chaining / nullish
  coalescing (`?.`, `??`) so a missing field degrades instead of throwing.
- **Error boundaries.** Isolate a failing subtree so one broken component doesn't
  blank the whole app — a framework **error boundary** (React `ErrorBoundary`, Vue
  `onErrorCaptured`) or, in vanilla TS, a `try/catch` around the render/mount of an
  independent widget. Show a fallback UI, not a white screen.
- **Timeout + retry on fetch/API calls.** `fetch` has **no default timeout** — wrap
  it with **`AbortController`** + `setTimeout` to bound it. Retry only **transient**
  failures (network error, timeout, 5xx) with capped exponential backoff + jitter;
  never retry a 4xx/logic error. Debounce user-triggered retries.
- **Offline / degraded network.** Handle the offline case (`navigator.onLine`, a
  failed fetch) with a clear message and a retry affordance; **fail closed** with a
  usable UI rather than a stuck spinner. Cache/last-known-good where it helps.

**Prove it with a failure-path test.** The timeout/retry/error-boundary behavior
needs a test that forces the failure (a mocked `fetch` that rejects/times out or
returns 5xx, asserting the retry/give-up/fallback path) — **co-located with the
boundary's contract test** in the integration lane, per
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).

## 6. Observability & logging

*How frontend renders the shared logging policy.* (CAP-6 · serves UC-009.) This
dimension **renders — does not reinvent** — the authoritative
[`design/logging-policy.md`](../../../design/logging-policy.md), mapped to the
**browser context** (there is no stderr in a browser; the console + an error-
reporting service are the destinations).

- **Mechanism:** the browser **`console`** — `console.debug` / `console.info` /
  `console.error` map to the policy's `DEBUG` / `INFO` / `ERROR` levels (there is
  **no `WARN`** in the policy). Wrap them in a tiny logger so a build flag can gate
  verbosity, rather than scattering bare `console.log`.
- **Level select:** a **verbose/debug** build flag (the browser parallel to
  `--verbose`) turns on `DEBUG` output; production ships quiet, `ERROR`-and-above.
- **Destination:** dev diagnostics go to the **console**; production errors should
  additionally go to an **error-reporting service** (Sentry-style) so failures in
  the field are observable, not lost in a user's console.
- **Source maps:** ship/publish **source maps** (to the error reporter, not
  necessarily to the public) so a minified production stack trace resolves to real
  file/line — the frontend parallel to a server stack trace.
- **Never log secrets or PII** ([§4](#4-security)): the console and the error
  reporter are readable/exportable — redact tokens and personal data before
  logging.

See the authoritative policy: **`design/logging-policy.md`**.

---

## Scaffolding

*The frontend project scaffolding — the templates a new repo is generated from.*
(CAP-7.) Per ADR-0004 this section **references the existing
[`templates/`](templates/) dir; it does not copy or re-invent it** — the templates
own the files, this profile owns the standards those files must satisfy.
`/sdlc-newproject --profile frontend` generates a frontend repo from these
templates (via `scaffold.sh`'s `render_frontend_profile`), so a scaffolded repo is
**born compliant** with the dimensions above.

A generated frontend repo inherits:

- **`package.json.tmpl`** — the `npm` scripts (`dev`/`build`/`preview`/`test`/
  `typecheck`/`format`) and pinned dev deps (Vite, TypeScript, Vitest, prettier).
- **`tsconfig.json.tmpl` / `vite.config.ts.tmpl`** — `strict` TypeScript ([§1](#1-best-practices))
  and the Vite build/test config.
- **`test.sh.tmpl`** — the single test entry point: guards on `node`/`npm`, then
  `tsc --noEmit` → `prettier --check` → `vitest run` ([§3](#3-testing-pyramid)).
- **`main.ts.tmpl` / `main.test.ts.tmpl` / `index.html.tmpl`** — a minimal
  framework-neutral entry point and a starter Vitest suite.
- **`setup.sh.tmpl`, `release.sh.tmpl`, `ci.yml.tmpl`, `prettierignore.tmpl`** —
  dev setup, release flow, GitHub CI (installs Node, runs the fast lane), and the
  prettier ignore list.

If a template is found non-conformant with a standard here, that is a normal
`/sdlc-feature` or `/sdlc-harden` item **against the templates**, filed separately
(ADR-0004) — do not fork the standard into the profile. Wiring **ESLint** into the
scaffold is one such tracked follow-up ([§1](#1-best-practices)).

## Cross-profile testing

Cross-**profile** (cross-language) testing — a frontend component tested against a
component in another stack (**frontend↔python**, **frontend↔sql** via an API) — is
**owned by `profile-common`**, not by any single profile (ADR-0002). See
[`profile-common` → Cross-profile testing](../profile-common/SKILL.md#cross-profile-testing).
It is a **stub fleshed out in F6 (#94)** once ≥2 real profiles exist to exercise a
boundary; the frontend side contributes the API **contract test** (the client's
`fetch` shape matches the server's response) + the co-located resilience
failure-path test ([§5](#5-reliability--resilience)) at each boundary it
participates in.

---

_Traceability: renders the `profile-common` backbone (F1/#89, ADR-0001) for the
frontend stack, cloning the F2/`profile-python` (#90) + F3/`profile-shell` (#91) +
F4/`profile-sql` (#92) pattern. CAP-1 (best practices), CAP-4 (performance,
ADR-0003), CAP-2 (testing), CAP-3 (security — the comprehensive checklist folds in
**#86**, subsuming the earlier starter), CAP-5 (reliability), CAP-6
(observability), CAP-7 (scaffolding, ADR-0004 — references `templates/`).
Framework-neutral (Vite + vanilla TS); a React-specific profile + ESLint wiring are
documented next iterations. Serves UC-001 (best practices), UC-002 (testing),
UC-004 (performance), UC-009 (observability), UC-010 (reliability). Source:
`/sdlc-architecture` backlog F5 (#93); security checklist subsumes #86._
