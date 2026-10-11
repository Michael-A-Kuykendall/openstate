# Changelog

All notable changes to openstate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Session hooks for Claude Code, Kiro and GitHub Copilot that put the capsule into the context automatically, as OpenCode does.

## [0.1.0] - release date set at go-live

The first public release: an OpenCode extension, installed per repository, with an MCP server for other hosts.

### Added
- **Local project-state engine** — records what is true, done, failed, blocked and decided from the OpenCode session's own events, keeps one store per repository (`.openstate/state.jsonl`), and retracts facts that a later event supersedes or that you close.
- **14 state tools** — `openstate_state`, `openstate_capsule` (start-of-session resume contract), `openstate_report` (what is broken or stuck), `openstate_report_timeline` (sessions in the order they appeared, paged), `openstate_why` (rule chain for a derived fact; for a recorded fact, the session it came from), `openstate_assess` (replay a prior session, or a span with `newest-N`, `oldest-N`, `range:A-B` or a title search), `openstate_sessions`, `openstate_checkpoint`, `openstate_export`, `openstate_close` (with `dry_run`), `openstate_reset`, `openstate_doctor`, `openstate_restart`, `openstate_toast`.
- **22 structural tools** — AST search and literal text search, bounded symbol and text-region reads, references, symbol overview, declarations and implementations, and preview/apply pairs for symbol edits, renames, inserts, moves and deletes, exact-anchor text edits, and new files. Symbol tools work in 18 languages (Rust, Python, TypeScript, TSX, JavaScript, Go, C, C++, Java, Bash, C#, Kotlin, Lua, PHP, Ruby, Scala, Solidity, Swift).
- **Structural profile** — `enforce`, `shadow` or `off`; enforce routes code edits through the structural tools and writes the matching OpenCode permission rules and one `AGENTS.md` block.
- **Capsule in context** — the resume capsule is added to the model's context at the start of every session and again after each compaction, unchanged in between so prompt caching keeps working; `OPENSTATE_CAPSULE=off` turns it off.
- **Frontier views** in capsule and report — resume cursor, validation status (with a hint when nothing has been verified yet), and the git change frontier. Report and capsule are deterministic and agree on the current task.
- **Sidebar status line and completion toasts** in the OpenCode TUI, with `openstate_toast` to turn toasts off per project.
- **MCP server** for every other host (Claude Code, Muse, Kiro, GitHub Copilot in VS Code), shipped in the bundle as one file, `mcp/openstate-mcp.mjs`; 34 tools (all but `openstate_restart` and `openstate_toast`).
- **Installer** — per-repository or `--global`; sha256 verification and an engine smoke test before anything is written; `--check`; `--uninstall` keeps `.openstate/` state and your own config; clear refusal on platforms without a prebuilt bundle.

### Security
- The engine and plugin make no network calls; state stays on disk in the repository.
- Release assets are verified by sha256 before install; the engine binary is stripped.

### License
- Proprietary engine (EULA, `LICENSE`); documentation, skill, installer and plugin bundle MIT (`PUBLIC-LICENSE`). Both ship inside the release bundle.
- Licenses are sold through Stripe and issued by Keygen.
