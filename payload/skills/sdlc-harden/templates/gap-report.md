# Harden gap report — <repo name>

> Produced by `/sdlc-harden` on <date>. Mode: <audit|apply>. Tier: <Quick|Standard|Full>.
> Stack/profile: <shell|python|frontend|…> (marker: <present|inferred>).
> This is the prioritization artifact — issues are filed only for the agreed
> **close + defer** gaps (see `sdlc-harden` §6).

## Inventory — what already exists

| SDLC scaffolding | Present? | Notes |
|---|---|---|
| Tests | <yes/no> | <framework / count / green?> |
| Single `./test.sh` runner | <yes/no> | |
| CI workflow | <yes/no> | |
| Pre-push hook | <yes/no> | |
| README (standard outline) | <partial/no> | <which sections missing> |
| `design/overview.md` | <yes/no> | |
| Logging policy | <yes/no> | |
| Backlog = Issues | <yes/no> | |

## Safety net

<Characterization tests pinned for the untested code slated for change, green on
untouched code — or "n/a, no behavior-touching fixes proposed".>

## Gaps — grouped by area, tagged by risk

Risk classes: **infra-doc** · **behavior-preserving** · **behavior-changing**.
Decision (filled with the human): **close** · **defer** · **drop**.

### Area 1 — Test net + `./test.sh` runner

| # | Gap | Risk | Effort | Decision |
|---|---|---|---|---|
| | | | | |

### Area 2 — CI + pre-push hook

| # | Gap | Risk | Effort | Decision |
|---|---|---|---|---|
| | | | | |

### Area 3 — Docs (README + `design/`)

| # | Gap | Risk | Effort | Decision |
|---|---|---|---|---|
| | | | | |

### Area 4 — Logging + coding standards + backlog

| # | Gap | Risk | Effort | Decision |
|---|---|---|---|---|
| | | | | |

## Escalations (behavior/logic → gated commands)

| # | Gap | Command | Issue |
|---|---|---|---|
| | | `/sdlc-feature` \| `/sdlc-bugfix` | #… |

## Summary

- **Close now:** <#…>
- **Defer (issue filed):** <#…>
- **Drop (recorded, not filed):** <…>
- **Known limits:** <e.g. "no deep hardening checklist for <profile> yet">
