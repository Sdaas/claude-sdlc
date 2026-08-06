# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- `/sdlc-retrospective` retros are now **transient**: the command writes a working
  `RETRO.md`, routes findings to durable homes (action items → GitHub issues;
  principles → `design/overview.md` or `sdlc-common`), then deletes it at
  close-out. Replaces the durable `docs/retrospectives/` archive. (#81)

### Removed
- The scaffolder no longer creates `docs/retrospectives/` in generated repos;
  retros are transient. (#81)

First genuine tagged release. It consolidates everything built since the Phase 0
foundation — the repo was developed against a stale `0.1.0` that was never cut,
so this release establishes the real versioning baseline.

### Added
- Versioned installer (`apply.sh`) that copies the payload into `~/.claude` and
  records the installed version, git sha, and per-file content hashes in
  `~/.claude/.sdlc/`.
- `setup.sh` dev-dependency checker with `--verify` readiness checks (auth +
  version floors).
- Workflow commands: `/sdlc-newproject`, `/sdlc-feature`, `/sdlc-bugfix`,
  `/sdlc-harden`, `/sdlc-discovery`, `/sdlc-architecture`, `/sdlc-retrospective`,
  `/sdlc-resume`, `/sdlc-help`, and `/sdlc-feedback`.
- Stack profiles for shell, python, and frontend projects.
- `sdlc-security` skill and per-profile security stubs backing the
  security-review gate.
- VERIFY gate, Definition of Done, and the mock-obligation rule for
  external boundaries.
- Real-boundary testing scaffold: an integration test lane plus a clean-install
  CI job.
- `SESSION_STATE.md` checkpoint contract so `/sdlc-resume` can continue
  in-flight work across sessions.
- Logging policy applied across all profiles.

### Changed
- All SDLC slash commands are prefixed `sdlc-` to avoid collisions with
  Claude Code's built-in and third-party commands.
- README layout corrected to match the actual repo (design lives in `design/`).

### Fixed
- `apply.sh` no longer follows symlinks when writing or removing files,
  including through a symlinked parent directory.
- `release.sh` / `apply.sh` `--help` no longer leak script code into the usage
  output.

[Unreleased]: https://github.com/Sdaas/claude-sdlc/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Sdaas/claude-sdlc/releases/tag/v0.2.0
