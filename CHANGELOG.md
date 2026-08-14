# Changelog

All notable changes to openstate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-14

### Added
- **Hardened release binary** — opt-level=z, strip, panic=abort, overflow-checks=off, LTO, 1 codegen unit (728KB)
- **Binary distribution installer** — install.sh downloads prebuilt bundle from GitHub Releases, verifies sha256, smoke-tests engine before install
- **Per-repo install model** — `install.sh` targets `.opencode/`; nothing global
- **13 AI tools** — state, why, checkpoint, capsule, export, reset, assess, report, report_timeline, close, sessions, doctor, restart
- **TUI sidebar integration** — "● openstate / battery ready · backing up" via openstate-tui.tsx
- **Semantic fact lifecycle** — facts enter on real events, exit on paired events
- **Crash recovery** — in-progress work persists across process death
- **Provenance tracking** — every fact has a justification chain via `openstate_why`
- **Compact/prune** — dead records collected at session boundaries

### Security
- Engine binary stripped of symbols; rule logic unrecoverable from binary
- Private release asset download via GitHub API with token authentication
- Checksum verification (sha256) on all release assets

### Changed
- License model: proprietary engine binary (EULA), surface components MIT (PUBLIC-LICENSE)
- Installer no longer compiles from source — binary distribution only

## [Unreleased]

### Planned
- macOS (x86_64/arm64) and Windows release assets
- Plugin obfuscation (javascript-obfuscator) for bundled openstate.js
- Cross-platform CI matrix
- Public repository launch with shimmy-style OSS surface (sponsors, CONTRIBUTING, GOVERNANCE, etc.)
- History scrub (git filter-repo) before go-live