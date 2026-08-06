---
name: profile-frontend
description: >
  Stack profile for frontend/TypeScript repos in the SDLC — the concrete "how"
  for the frontend stack. Currently carries the profile's starter security
  checklist, consumed by the sdlc-security Full-tier gate and by /sdlc-harden.
  Fuller profile content (Vite + TS, Vitest, tsc + prettier conventions) lives in
  the templates/ dir for now; this SKILL.md will grow to own it.
---

# Profile — Frontend

The frontend stack profile (Vite + TS, Vitest, `tsc --noEmit` + `prettier`).
Scaffolding conventions currently live in `templates/`; this `SKILL.md` will grow
to own the full profile. For now it carries the **security checklist** that
`sdlc-security` (§4) and `/sdlc-harden` delegate to.

## Security checklist (starter — non-exhaustive, see #86)

> A **floor, not a ceiling.** Walk `sdlc-security` §2 in full; these are the
> highest-signal frontend-specific checks. Fleshing this out is tracked as **#86**.

- **XSS / DOM injection.** `innerHTML`, `dangerouslySetInnerHTML`,
  `document.write`, and unsanitized templating with user data — prefer
  `textContent` / framework escaping; sanitize any HTML you must inject.
- **Secrets in the bundle.** Anything inlined at build (env vars, API keys) ships
  to the client and is public. Keep secrets server-side; only expose public
  values.
- **Cross-origin & tabnabbing.** Validate `event.origin` in `postMessage`
  handlers; add `rel="noopener noreferrer"` to `target="_blank"` links; set a
  Content-Security-Policy.
- **Token storage & CSRF.** Prefer httpOnly cookies over `localStorage` for auth
  tokens; protect state-changing requests against CSRF.
- **Dependencies / supply chain.** Commit the lockfile, run `npm audit`, avoid
  unvetted CDN `<script>` tags (or pin + SRI).
