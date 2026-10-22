# openstate — Frequently Asked Questions

---

## General

### What is openstate?
OpenState gives coding agents two equal capabilities: structural code search, read and edit with guarded preview-to-apply writes, and a persistent, provenance-backed record of what is true in a project — decisions, finished and failed work, what is blocked — kept local and available across sessions through OpenCode and MCP. It is native in **OpenCode**, and it reaches other coding agents — Claude Code, Muse, Kiro, GitHub Copilot, Codex and any other MCP host — through the bundled MCP server.

### Who is this for?
Developers using coding agents who need guarded structural code operations and project state across sessions. OpenCode provides native automatic capture and capsule injection. Standard MCP clients, including Claude Code, Codex and Cursor, use the same tools and supported stored-session recovery on demand.

### Is it open source?
**Engine binary**: Proprietary (commercial EULA) — protects the core invention.  
**Surface**: MIT licensed — docs, skill, installer, plugin bundle.  
**Commercial licensing**: Available for embedding — contact `michaelallenkuykendall@gmail.com`.

### Why not fully open source?
The fact-derivation engine (the "how") is the differentiated IP. The surface (what you install, the skill, the docs) is MIT. This lets us sell the product while protecting the invention.

---

## Installation

### How do I install?
```bash
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash
```

### What does it install?
The installer writes to the global OpenCode config directory by default; `--repo` or `OPENSTATE_CONFIG_DIR` selects a project's `.opencode/`. The bundle contains:
- `bin/openstate-engine` (the state engine) and `bin/ast-grep` (structural search backend)
- `plugins/openstate/index.js` (plugin) and `plugins/openstate/tui.js` (sidebar status line and toasts)
- `skills/openstate/SKILL.md` (AI usage skill)
- `mcp/openstate-mcp.mjs` (standard MCP server)
- `structural-tools-profile.json` (structural tools mode) and `package.json` (TUI dependency)

### Does it need Rust/Node to install?
No Rust: the installer downloads a prebuilt binary and plugin bundle. It does need Node.js, which it uses to update `.opencode/package.json` and other JSON config.

### Per-repo or global?
Global by default: the installer writes once under your OpenCode config directory so every repository inherits it (and, only if you turn the structural profile to `enforce`, one marked block in `AGENTS.md`); per-repo state still goes to each repository's `.openstate/`, which ignores itself in git. `--repo` (or `OPENSTATE_CONFIG_DIR`) targets a single repository's `.opencode/` instead.

### How do I verify?
```bash
./install.sh --check
```

---

## Usage

### What tools does the AI get?
Both native OpenCode and the bundled MCP server expose 36 tools: the 14 state/lifecycle tools below, plus 22 structural tools (AST and text search, bounded reads, references, declarations, and preview/apply edits, renames, inserts, moves, deletes and new files; symbol tools in 18 languages). MCP clients need a stdio registration; enabled/disabled tool policies can hide tools until corrected and the connection reloaded.

- `openstate_state` — full project state
- `openstate_why` — provenance for any fact
- `openstate_checkpoint` — force flush
- `openstate_capsule` — resume contract
- `openstate_export` — full JSON dump
- `openstate_reset` — deliberate wipe
- `openstate_assess` — absorb prior session
- `openstate_report` — "what's broken"
- `openstate_report_timeline` — chronological view
- `openstate_close` — retract false positives
- `openstate_sessions` — list prior sessions
- `openstate_doctor` — engine health
- `openstate_restart` — checkpoint and restart the native sidecar, or report next-call cold start for one-shot MCP
- `openstate_toast` — persist completion-notification preference; OpenCode renders toasts

The skill tells the AI when to use each.

### What are the structural tools for?

Reading, searching and editing code by definition instead of by whole file. The agent searches for a name with `openstate_ast_search`, reads just that function or type with `openstate_read_symbol`, and changes it through a preview and an apply. A preview writes nothing; an apply writes only what its preview showed, once, and is refused if the file changed so that the previewed change no longer fits. See [Structural tools](STRUCTURAL-TOOLS.md).

### Do the structural tools save tokens?

Per read, they return less: in one measured case, reading a complete function from a 63 KB file returned 97% less data than reading the file. A whole-session token total has not been shown to fall; what is measured is completion cost: tokens per completed work item in the openstate repo fell from about 16M to 10.6M (34%) and per commit from 16.0M to 11.05M (31%) between August and September 2026 while completions rose, and a repo adopting the tools via Claude Code fell from 14.3M to 0.9M tokens per commit while non-adopting repos were flat or worse except one that improved in a lighter work phase. That is observed co-movement in the maintainer's projects, not a controlled study. A small edit still takes three calls (search, preview, apply) where a direct editor takes one.

### Can the agent still use its own read and edit tools?

Yes, by default. The skill and the MCP server's instructions ask the agent to prefer the structural tools for code, and nothing is disabled. In OpenCode you can opt in to more: installing with `OPENSTATE_STRUCTURAL_TOOLS=enforce` denies the built-in read, grep and edit tools, so reads and edits go through the structural tools; `OPENSTATE_STRUCTURAL_TOOLS=off` undoes it.

### What's the "session start ritual"?
1. In native OpenCode, read the injected capsule. In an MCP client without capsule injection, call `openstate_capsule` for the project root (`openstate_state` and `openstate_report` provide full detail).
2. Announce to user: "openstate loaded · objective: X · validation stale · branch: main"
3. `openstate_report` only if something looks broken or stuck

### What is a capsule?
A structured JSON contract, injected automatically in native OpenCode and read on demand through MCP. The measured size was a median about 500, at most about 1,600 tokens across 21 real project stores. Contains:
- **Resume cursor**: current task, active files, last action, blocker, next action
- **Validation**: test status, edits since green, stale/failed/current
- **Change frontier**: modified/added/deleted files, uncommitted status

---

## Privacy & Data

### Where does my data live?
Project state stays local in `.openstate/state.jsonl`; `.openstate` can be a directory, symlink or local pointer. The engine sends no runtime telemetry. Host history discovery may contact the configured OpenCode API, while release downloads use GitHub. Choose a local history source when offline access is required.

### Can I inspect the state?
Yes, through the tools: `openstate_state`, `openstate_report`, `openstate_why <fact_id>`, and `openstate_export` for a full dump. The file format itself is internal and may change between versions.

### What about secrets?
The engine sees what the agent sees: your messages, the commands it runs with their exit codes and the first 4,000 characters of tool output, file paths, and git status. What it keeps stays in `.openstate/` in your repository and is never sent anywhere. Treat `.openstate/` like shell history: it holds commands verbatim, so a secret typed on a command line is in it. The engine writes a `.gitignore` of `*` inside `.openstate/`, so git ignores it without any change to your own `.gitignore`.

---

## Engine & Architecture

### How does it work?
1. **Observer Plugin** (TypeScript) captures OpenCode events
2. **Rust Engine** derives facts, maintains provenance, handles retraction
3. **Capsule** injected at session start

### What does "retractable" mean here?
When a later event contradicts or completes something (a fix lands, a decision is replaced, a run succeeds after failing), the outdated fact leaves the state, so the capsule and report only show what is still true.

### Is the engine open source?
No — the binary is proprietary (EULA). The surface (docs, skill, installer, plugin) is MIT. Commercial embedding licenses available.

### How does crash recovery work?
State is written to disk at three points: an explicit `openstate_checkpoint`, OpenCode closing, and the engine's input ending. There is no timed background flush, so a hard kill loses what happened since the last write; what was written survives. The full list of failure modes is in [TRUST.md](TRUST.md).

### What's the binary size?
Under 3 MB on every platform (2.0 to 3.0 MB; it includes the TLS client for license checks). Built stripped, with LTO, `panic=abort` and `opt-level=z`.

---

## Compatibility

### Which editors?
**OpenCode** uses its native plugin, with automatic capture and capsule injection. **Claude Code, Codex, Cursor and other standard MCP clients** use the bundled MCP server (`mcp/openstate-mcp.mjs` under the chosen install directory; registration in the README). From any caller, `openstate_sessions` and `openstate_assess` recover supported OpenCode, Claude and legacy Codex histories for the project. Current paginated/compressed Codex history returns `unsupported_history`; MCP support does not imply support for every host's native history format.

### Which OS?
Linux x86_64 (glibc 2.17 or newer) and macOS Intel are runtime-verified per release; Apple Silicon and Windows x86_64 bundles are published but runtime-unverified (no in-house hardware yet) — via per-platform release bundles. Other platforms are refused by the installer with a clear message.

### OpenCode version?
Requires OpenCode with plugin API support.

---

## Licensing & Commercial

### Can I use it in my company?
Yes. A purchased license covers personal, commercial and internal use. Separate commercial licenses cover **embedding or redistributing** the engine.

### Can I embed the engine in my product?
Yes — commercial licensing available. Contact `michaelallenkuykendall@gmail.com`.

### Can I fork and modify?
Surface (docs, skill, installer): Yes, MIT.  
Engine binary: No — proprietary, no source access.

### Is it free?
**No.** OpenState is sold through Stripe ([pricing](https://michael-a-kuykendall.github.io/openstate/pricing.html)); Keygen issues the license key after checkout. The documentation, skill, installer and plugin bundle remain MIT-licensed.

---

## Troubleshooting

### "Engine unavailable"
Run `openstate_doctor` — checks PID, uptime, fact counts, journal health.

### Capsule shows "validation stale"
Run your test command (`cargo test`, `npm test`, etc.). The capsule tracks generations.

### "Engine unavailable" after install
Restart OpenCode. The plugin starts the engine when OpenCode loads it.

### Install fails on Windows
The installer is a bash script: run it from Git Bash (installs the Windows bundle) or from WSL (installs the Linux bundle for OpenCode running inside WSL).

### How do I reset?
```bash
openstate_reset
# Irreversible — clears all facts + assess journal
```

---

## Contributing

### Can I contribute code?
**Maintainer-only PRs.** Apply via email: `michaelallenkuykendall@gmail.com`.  
Non-maintainers: issues and testing welcome.

### DCO required?
Yes — all commits must be signed off (`git commit -s`).

### Security issues?
See [SECURITY.md](../SECURITY.md) — private disclosure via GitHub Security Advisories or `michaelallenkuykendall@gmail.com`.
