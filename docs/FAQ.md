# openstate — Frequently Asked Questions

---

## General

### What is openstate?
An **OpenCode extension**: a local-first session-state engine that gives coding agents in OpenCode a continuously maintained, provenance-backed model of project state. It turns the event stream (messages, tool calls, file edits, todos, git) into live, retractable facts with full provenance. Support for additional coding environments is planned.

### Who is this for?
Coding agents in OpenCode — and the developers who want their AI to have perfect context across sessions, crashes, and compactions. Other editors/environments are on the roadmap.

### Is it open source?
**Engine binary**: Proprietary (commercial EULA) — protects the core invention.  
**Surface**: MIT licensed — docs, skill, installer, plugin bundle.  
**Commercial licensing**: Available for embedding — contact `michaelallenkuykendall@gmail.com`.

### Why not fully open source?
The fact-derivation engine (the "how") is the differentiated IP. The surface (what you install, the skill, the docs) is MIT. This lets us ship a real product today while protecting the invention for future commercialization.

---

## Installation

### How do I install?
```bash
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash
```

### What does it install?
Per-repo, into `.opencode/`:
- `bin/openstate-engine` (the state engine) and `bin/ast-grep` (structural search backend)
- `plugins/openstate/index.js` (plugin) and `plugins/openstate/tui.js` (sidebar status line and toasts)
- `skills/openstate/SKILL.md` (AI usage skill)
- `structural-tools-profile.json` (structural tools mode) and `package.json` (TUI dependency)

### Does it need Rust/Node to install?
**No.** The installer downloads a prebuilt binary + plugin bundle. No compiler or Node toolchain required on the target machine.

### Per-repo or global?
**Per-repo only.** Nothing is written outside `.opencode/` in the repo where you run the installer. No global pollution.

### How do I verify?
```bash
./install.sh --check
```

---

## Usage

### What tools does the AI get?
36 tools automatically registered: the 14 state tools below, plus 22 structural tools (AST and text search, bounded reads, references, declarations, and preview/apply edits, renames, inserts, moves, deletes and new files; symbol tools in 18 languages).

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
- `openstate_restart` — restart sidecar
- `openstate_toast` — completion toasts on/off

The skill tells the AI when to use each.

### What's the "session start ritual"?
1. `openstate_capsule` — the resume contract (light; `openstate_state` and `openstate_report` are for full detail)
2. Announce to user: "openstate loaded · objective: X · validation stale · branch: main"
3. `openstate_report` only if something looks broken or stuck

### What is a capsule?
A 1,000–5,000 token structured JSON contract injected at session start. Contains:
- **Resume cursor**: current task, active files, last action, blocker, next action
- **Validation**: test status, edits since green, stale/failed/current
- **Change frontier**: modified/added/deleted files, uncommitted status

---

## Privacy & Data

### Where does my data live?
`.openstate/state.jsonl` in your repo. **Never leaves your machine.** No telemetry, no cloud, no external calls except GitHub Releases for binary download.

### Can I inspect the state?
Yes. It's JSON Lines — query with DuckDB, `jq`, or the built-in tools:
```bash
duckdb -c "SELECT * FROM read_json_auto('.openstate/state.jsonl')"
openstate_state
openstate_why <fact_id>
```

### What about secrets?
The engine never reads secret files. It tracks git state, file edits, and tool calls — not file contents. Your secrets stay in your files.

---

## Engine & Architecture

### How does it work?
1. **Observer Plugin** (TypeScript) captures OpenCode events
2. **Rust Engine** derives facts, maintains provenance, handles retraction
3. **Capsule** injected at session start

### What's "Saturation Fabric"?
The internal derivation engine — continuous, incremental, with automatic retraction on contradictory evidence. The public name is **"continuously maintained, retractable project-state model."**

### Is the engine open source?
No — the binary is proprietary (EULA). The surface (docs, skill, installer, plugin) is MIT. Commercial embedding licenses available.

### How does crash recovery work?
- **Explicit checkpoint** (human/AI decision)
- **Dispose flush** (app close)
- **stdin-EOF last resort** (catastrophic kill)

No automatic/idle flushing — only human/AI-confirmed state persists.

### What's the binary size?
728KB (Linux x86_64). Hardened: strip + LTO + panic=abort + opt-level=z.

---

## Compatibility

### Which editors?
Currently: **OpenCode** (plugin + skill).  
Future: VS Code, Cursor, Claude Code, Zed — any editor with a plugin API.

### Which OS?
Linux x86_64 (glibc 2.17 or newer), macOS (Intel and Apple Silicon), Windows x86_64 — via per-platform release bundles. Other platforms are refused by the installer with a clear message.

### OpenCode version?
Requires OpenCode with plugin API support. Tested on current stable.

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
**No.** OpenState is sold through Stripe ([pricing](https://michael-a-kuykendall.github.io/openstate/pricing.html)); Keygen issues the license key, shown once after checkout. The documentation, skill, installer and plugin bundle remain MIT-licensed.

---

## Troubleshooting

### "Engine unavailable"
Run `openstate_doctor` — checks PID, uptime, fact counts, journal health.

### Capsule shows "validation stale"
Run your test command (`cargo test`, `npm test`, etc.). The capsule tracks generations.

### "Engine unavailable" after install
Restart OpenCode. The plugin spawns the engine on first tool call.

### Install fails on Windows
Ensure you're in a native shell (PowerShell/WSL), not Git Bash. The installer detects platform.

### How do I reset?
```bash
openstate_reset
# Irreversible — clears all facts + assess journal
```

---

## Contributing

### Can I contribute code?
**Maintainer-only PRs.** Apply via email: `michaelallenkuykendall@gmail.com`.  
Non-maintainers: issues, discussions, testing welcome.

### DCO required?
Yes — all commits must be signed off (`git commit -s`).

### Security issues?
See [SECURITY.md](../SECURITY.md) — private disclosure via GitHub Security Advisories or `security@openstate.dev`.
