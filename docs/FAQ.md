# openstate — Frequently Asked Questions

---

## General

### What is openstate?
An **OpenCode extension**: a local-first session-state engine that gives coding agents in OpenCode a continuously maintained, provenance-backed model of project state. It turns the event stream (messages, tool calls, file edits, todos, git) into live, retractable facts with full provenance. Support for additional coding environments is planned.

### Who is this for?
Developers running long coding-agent sessions in OpenCode who want each new session, and each session after a compaction, to start from a record of what was decided, done, failed and blocked. Other editors/environments are on the roadmap.

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
Per-repo, into `.opencode/`:
- `bin/openstate-engine` (the state engine) and `bin/ast-grep` (structural search backend)
- `plugins/openstate/index.js` (plugin) and `plugins/openstate/tui.js` (sidebar status line and toasts)
- `skills/openstate/SKILL.md` (AI usage skill)
- `structural-tools-profile.json` (structural tools mode) and `package.json` (TUI dependency)

### Does it need Rust/Node to install?
No Rust: the installer downloads a prebuilt binary and plugin bundle. It does need Node.js, which it uses to update `.opencode/package.json` and other JSON config.

### Per-repo or global?
Per repository by default: the installer writes `.opencode/` and one marked block in `AGENTS.md`, and state goes to `.openstate/`. `--global` installs once under your OpenCode config directory instead.

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
1. Read the capsule OpenState already put in the context (the resume contract; `openstate_state` and `openstate_report` are for full detail)
2. Announce to user: "openstate loaded · objective: X · validation stale · branch: main"
3. `openstate_report` only if something looks broken or stuck

### What is a capsule?
A structured JSON contract injected at session start, a few hundred tokens (median about 500, at most about 1,600 across 21 real project stores). Contains:
- **Resume cursor**: current task, active files, last action, blocker, next action
- **Validation**: test status, edits since green, stale/failed/current
- **Change frontier**: modified/added/deleted files, uncommitted status

---

## Privacy & Data

### Where does my data live?
`.openstate/state.jsonl` in your repo. **Never leaves your machine.** No telemetry, no cloud, no external calls except GitHub Releases for binary download.

### Can I inspect the state?
Yes, through the tools: `openstate_state`, `openstate_report`, `openstate_why <fact_id>`, and `openstate_export` for a full dump. The file format itself is internal and may change between versions.

### What about secrets?
The engine sees what the agent sees: your messages, the commands it runs with their exit codes and the first 4,000 characters of tool output, file paths, and git status. What it keeps stays in `.openstate/` in your repository and is never sent anywhere. Treat `.openstate/` like shell history: keep it out of version control.

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
State is written to disk at three points: an explicit `openstate_checkpoint`, OpenCode closing, and the engine's input ending. There is no timed background flush, so a hard kill loses what happened since the last write; what was written survives.

### What's the binary size?
Under 1 MB on every platform. Built stripped, with LTO, `panic=abort` and `opt-level=z`.

---

## Compatibility

### Which editors?
Currently: **OpenCode** (plugin + skill).  
Planned: Claude Code, Kiro and GitHub Copilot in VS Code (see the roadmap).

### Which OS?
Linux x86_64 (glibc 2.17 or newer), macOS (Intel and Apple Silicon), Windows x86_64 — via per-platform release bundles. Other platforms are refused by the installer with a clear message.

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
**No.** OpenState is sold through Stripe ([pricing](https://michael-a-kuykendall.github.io/openstate/pricing.html)); Keygen issues the license key, shown once after checkout. The documentation, skill, installer and plugin bundle remain MIT-licensed.

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
