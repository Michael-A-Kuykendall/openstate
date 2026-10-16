<div align="center">
  <img src="assets/openstate-logo.jpg" alt="openstate logo" width="220" />
</div>

# openstate

> **OpenState gives coding agents two equal capabilities: structural code search, read and edit with guarded preview-to-apply writes, and a persistent, provenance-backed record of what is true in a project — decisions, finished and failed work, what is blocked — kept local and available across sessions through OpenCode and MCP.**

[![License: commercial engine, MIT surface](https://img.shields.io/badge/license-commercial%20engine%2C%20MIT%20surface-blue)](LICENSE)
[![OpenCode](https://img.shields.io/badge/OpenCode-compatible-blue)](https://opencode.ai)

[![💝 Sponsor this project](https://img.shields.io/badge/💝_Sponsor_this_project-ea4aaa?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/Michael-A-Kuykendall)

**openstate is commercial software.** You buy a license through Stripe on the [pricing page](https://michael-a-kuykendall.github.io/openstate/pricing.html); Keygen issues the key. The engine runs locally, needs no account, and sends nothing anywhere.

---

## Table of Contents

- [What Is openstate?](#what-is-openstate)
  - [Three problems it addresses](#three-problems-it-addresses)
  - [Who it is for](#who-it-is-for)
- [Reading, searching and editing code](#reading-searching-and-editing-code)
- [🔧 Architecture](#architecture)
- [📦 Install](#install)
- [How it compares](#how-it-compares)
- [Other hosts: the MCP server](#other-hosts-the-mcp-server)
- [🚀 Quick Start](#quick-start)
- [🛠 AI Tools](#ai-tools)
- [📖 Documentation Hub](#documentation-hub)
- [🏛️ License & Philosophy](#license--philosophy)
- [🌍 Community & Support](#community--support)

---

## What Is openstate?

OpenState gives coding agents two equal capabilities: structural code search, read and edit with guarded preview-to-apply writes, and a persistent, provenance-backed record of what is true in a project — decisions, finished and failed work, what is blocked — kept local and available across sessions through OpenCode and MCP.

It is native in **OpenCode** and reaches other coding agents through the bundled MCP server: Claude Code, Muse, Kiro, GitHub Copilot, and any other MCP host such as Codex or Cursor. Native OpenCode captures events and injects capsules automatically. Any standard MCP caller can assess supported OpenCode, Claude and legacy Codex histories for the project; current paginated/compressed Codex history returns `unsupported_history`. The calling host does not select the transcript source.

### Three problems it addresses

| Problem | What OpenState records | Where the agent sees it |
|---|---|---|
| The agent re-runs a command that already failed in an earlier session. | Each failed command. | `failed_attempts` in the capsule; `openstate_report`; `openstate_report_timeline` shows which session it failed in. |
| After a compaction or a restart, the agent re-reads files to work out what it was doing. | The objective, recent decisions, the files being worked on, uncommitted changes, and whether a test has passed since the last edit. | The capsule, injected automatically in native OpenCode or read on demand through MCP. |
| The agent retries an approach that was already rejected. | Decisions: messages that give a reason ("because ..."), recorded with that reason. | `decisions` in the capsule; `openstate_why` shows where a decision came from. |

### Who it is for

Developers using coding agents who need structural code search, guarded edits and persistent project state. Native OpenCode supplies automatic event capture and capsule injection; standard MCP clients use the same 36 tools and supported stored-session recovery on demand.

### Who it is not for

- **A knowledge base or documentation search.** It records what happens in sessions, not your documents.
- **Semantic or vector search over code.** Use the structural tools or your editor.
- **A hosted or team service.** Everything stays on one machine, in one repository.
- **A transcript store.** It keeps the current state, not the conversation.


**🔧 The engine is proprietary** (distributed under a commercial EULA). The surface components — documentation, skill, installer, plugin bundle — are MIT-licensed. Commercial licensing for embedding the engine in other products is available.

---

## Reading, searching and editing code

OpenState's 22 structural code tools are a core capability. Built on ast-grep, they let the agent work in definitions instead of whole files: search for a name, read just that function or type, and change it through a preview that is checked before anything is written. In one measured case, reading a complete function from a 63 KB file returned 97% less data than reading the file. Measured in the maintainer's session history, completion cost fell where the tools were adopted: in the openstate project, tokens per completed work item fell from about 16M to 10.6M (34%) and per commit from 16.0M to 11.05M (31%) between August and September 2026 while completions rose, and a repo that adopted the tools via Claude Code fell from 14.3M to 0.9M tokens per commit while non-adopting repos were flat or worse except one that improved in a lighter work phase. These are observed co-movements in the maintainer's repos, not a controlled study; see [Structural tools](docs/STRUCTURAL-TOOLS.md) for the tools, the guarantees of the write path, the 18 supported languages and the known weaknesses.

---

## Architecture

### 1. OpenCode Observer Plugin (TypeScript)

Captures events: `message.updated`, `tool.execute.before/after`, `file.edited`, `todo.updated`, `session.idle`, `session.compacted`, etc.

### 2. Structural Code Tools

The shared ast-grep core searches and reads definitions and applies guarded preview-to-apply edits through either transport.

### 3. Local Rust State Engine

Turns those events into project facts (objectives, decisions, completed and failed commands, blockers) and replaces or closes a fact when a later event supersedes it. `openstate_why` shows where any fact came from.

### 4. Resume Capsule

A structured continuation contract injected automatically in native OpenCode on new sessions and compaction — a few hundred tokens (median about 500, at most about 1,600 across 21 real project stores), carrying the state needed to resume work. It rides on every model request of the session and stays the same text until the next compaction, so a prompt cache keeps it; `OPENSTATE_CAPSULE=off` turns it off.

---

## Install

```bash
# 1. One-liner (curl|bash — downloads prebuilt bundle, installs globally)
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash

# 2. Target a specific repo
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | OPENSTATE_CONFIG_DIR=/path/to/repo/.opencode bash

# 3. Clone once, install anywhere
git clone --depth 1 https://github.com/Michael-A-Kuykendall/openstate.git /tmp/os
/tmp/os/install.sh
OPENSTATE_CONFIG_DIR=/path/to/other/.opencode /tmp/os/install.sh
```

Downloads the prebuilt engine binary + plugin bundle from GitHub Releases, verifies sha256, smoke-tests the engine, and installs the complete bundle once for the current user by default (**global**). No compiler is needed; the installer does need Node.js 18+ to update the JSON config files. By default openstate is **global**: one install is shared by every repository; use `--repo` (or `OPENSTATE_CONFIG_DIR`) to scope it to a single repository's `.opencode/`. Restart OpenCode, done.

Verify an existing install: `./install.sh --check`

Remove it with `./install.sh --uninstall` (keeps `.openstate/` state) or `./install.sh --purge` (deletes it too). What survives a crash: [docs/TRUST.md](docs/TRUST.md).

State lives per-project in `.openstate/state.jsonl`. Read it through the tools (`openstate_state`, `openstate_export`), not the file: its format is internal and may change.

---

## How it compares

| Approach | What is kept | Who writes it | When the agent sees it | Goes stale? |
|---|---|---|---|---|
| Compaction summary | A prose summary of the conversation so far | The model, when the context fills up | In the same session, after compaction; a new session starts without it | It is rewritten at each compaction; details the model left out are gone |
| A notes file (`AGENTS.md`, a memory markdown file) | Whatever someone wrote there | You, or the agent when told to | Every session, in full | Yes, unless someone keeps editing it |
| Agent memory tools (Serena memories, built-in memory) | Notes the model chose to save | The model, when it decides to | When the agent reads them | Yes; nothing removes a note that stopped being true |
| Transcript search and event logs | Everything that was said and run | The host, automatically | When the agent searches | No, but it is history, not current state; the agent has to work out what still holds |
| Telling the model to remember | Nothing outside the context | — | Until the context is compacted or the session ends | — |
| **OpenState** | Decisions, failed and completed commands, blockers, the objective, test status since the last edit, changed files | The engine, from the session's events, with no model in the loop | OpenCode: in the capsule at the start of every session and after each compaction. Other hosts: when the agent calls `openstate_capsule` | No: a fact is replaced or closed when a later event supersedes it |

### Known weaknesses

- **It records only what passes through the host's events**: messages, commands with their exit codes, file edits and git status. It does not see the model's reasoning, file contents, or work you do in your own terminal.
- **Decisions are recognised by wording.** A message that gives a reason ("because", "since", "so that", "in order to", "due to") becomes a decision; a decision stated without one is recorded as a directive or objective, and a casual "because" can be recorded as a decision. `openstate_close` removes false ones.
- **A failure needs an exit code.** A command whose tool reports no exit code is recorded as completed, not failed (it never counts as a passing test, though). Read-only commands such as `cat`, `ls` or `grep` are not recorded at all.
- **On hosts other than OpenCode the capsule is on demand**: the agent has to call `openstate_capsule` (the MCP server's instructions tell it to).
- **One machine, one repository.** There is no sync between machines or people.
- **No measurement yet shows fewer repeated failures.** What OpenState guarantees is the record and its delivery to the agent; whether that changes your agent's behavior is for you to judge in your own sessions. (Token *cost per completed work item* is measured and fell with adoption: see the Structural tools bullet above.)
- **The engine is closed source** (the plugin, installer, skill and documentation are MIT).
- **Install integrity, not authenticity.** The installer checks each download against the sha256 published with the same GitHub release; releases are not yet signed. Read `install.sh` before you pipe it into bash.

---

## Other hosts: the MCP server

The same bundle carries an MCP server, `mcp/openstate-mcp.mjs`, for every host that is not OpenCode. Install globally as above or use `install.sh --repo` for `.opencode/mcp/openstate-mcp.mjs` in one project, then register the installed file with your host. It needs Node.js 18 or newer.

| Host | File in the repository | Entry |
|---|---|---|
| Claude Code, Muse | `.mcp.json` | `{"mcpServers": {"openstate": {"command": "node", "args": ["/path/to/repo/.opencode/mcp/openstate-mcp.mjs"]}}}` |
| Kiro | `.kiro/settings/mcp.json` | `{"mcpServers": {"openstate": {"command": "node", "args": ["/path/to/repo/.opencode/mcp/openstate-mcp.mjs"]}}}` |
| GitHub Copilot in VS Code | `.vscode/mcp.json` | `{"servers": {"openstate": {"type": "stdio", "command": "node", "args": ["${workspaceFolder}/.opencode/mcp/openstate-mcp.mjs"]}}}` |

Use the absolute path to the installed file (after `--global`, `~/.config/opencode/mcp/openstate-mcp.mjs`). The server offers the same 36 operations as native OpenCode: 14 state/lifecycle and 22 structural tools. For one-shot MCP, `openstate_restart` checkpoints and reports next-call cold start; `openstate_toast` persists the preference, while OpenCode supplies its UI renderer. Each tool takes the project root as `repo_dir`. Use `openstate_sessions`, then `openstate_assess` with an exact source-qualified ID, checkpoint, and read capsule/report or a source-filtered timeline. Repeating assessment skips previously absorbed records. Client allowlists may hide tools; check the effective configuration and reconnect after updating it. These hosts give OpenState no way to put the capsule into the context by itself, so the server's instructions tell the agent to call `openstate_capsule` at the start of a session and after a compaction.

---

## Quick Start

```bash
# In any repo
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash

# Restart OpenCode
 # You now have 36 AI tools (14 state + 22 structural) + TUI sidebar (status line + completion toasts) + skill
 ```

---

## Human-visible feedback

Two surfaces report openstate activity (both driven by OpenCode's `message.part.updated` ToolPart events — the one signal path that actually fires for custom-tool lifecycle):

- **Always-on sidebar status** (`● openstate / battery ready`) — live status. While an `openstate_*` command runs, "battery ready" swaps to `<command>: …` and the green dot animates, then settles back. Always on.
- **Completion toasts** — a transient TUI notification confirming what finished (e.g. `✓ doctor · engine OK · 7796 facts`), coalesced into one toast for back-to-back bursts. On by default.

**Turning toasts off:** an AI-driven toggle — ask the agent "turn off the openstate toasts", which calls `openstate_toast` with `enabled: false`. Persisted per-project in `.openstate/toasts.json`. The sidebar status line keeps working regardless.

> Note on tool output in the transcript: a tool's returned text feeds the model and appears in the chat only when the user enables "Show generic tool output" in the TUI (an opt-in OpenCode setting). The sidebar + toasts above are the guaranteed human-visible surfaces.

---

## AI Tools

The AI gets 36 tools automatically via the OpenCode plugin: 14 state tools and 22 structural tools. The state tools:

| Tool | Purpose |
|------|---------|
| `openstate_state` | Full project state: objective, decisions, in-progress, blockers, next actions |
| `openstate_why` | Provenance chain for any fact |
| `openstate_checkpoint` | Force-flush state to disk |
| `openstate_capsule` | Resume contract (frontier views + validation + change frontier) |
| `openstate_export` | Full state dump as JSON |
| `openstate_reset` | Deliberate full wipe (start over / privacy scrub) |
| `openstate_assess` | Absorb current or prior session into the battery |
| `openstate_report` | Black-box "what's broken/stuck" readout |
| `openstate_report_timeline` | Chronological session→facts map |
| `openstate_close` | Retract false positives / resolved items |
| `openstate_sessions` | List prior sessions for assessment |
| `openstate_doctor` | Engine health check |
| `openstate_restart` | Restart engine sidecar |
| `openstate_toast` | Toggle the completion toasts ON/OFF (per-project; default ON) |

Plus 22 structural tools (AST and text search, bounded reads, references, declarations, and preview/apply edits, renames, inserts, moves, deletes and new files; symbol tools in 18 languages). The `.opencode/skills/openstate/SKILL.md` skill tells the AI when to use them.

---

## Documentation Hub

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | This file |
| [ROADMAP.md](ROADMAP.md) | Vision, milestones, non-goals |
| [CHANGELOG.md](CHANGELOG.md) | Keep-a-Changelog history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Maintainer-only PR model + DCO |
| [DCO.md](DCO.md) | Developer Certificate of Origin |
| [GOVERNANCE.md](GOVERNANCE.md) | Lead maintainer authority |
| [SECURITY.md](SECURITY.md) | Vulnerability disclosure |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [LICENSE](LICENSE) | Proprietary engine + MIT surface |
| [PUBLIC-LICENSE](PUBLIC-LICENSE) | MIT for surface components |
| [NOTICE](NOTICE) | Attribution & commercial licensing |
| [SPONSORS.md](SPONSORS.md) | Sponsor tiers & recognition |
| [SKILL.md](SKILL.md) | AI usage skill |
| [docs/FAQ.md](docs/FAQ.md) | Frequently asked questions |
| [docs/TRUST.md](docs/TRUST.md) | What survives a crash, failure modes, uninstall and purge |
| [docs/VERSIONING.md](docs/VERSIONING.md) | What counts as a breaking change; state compatibility |

---

## License & Philosophy

**Engine binary (openstate-engine):** Proprietary, distributed under a commercial EULA.  
**Surface components (docs, skill, installer, plugin bundle):** MIT License — see [PUBLIC-LICENSE](PUBLIC-LICENSE).  
**Commercial licensing** for embedding the engine in other products: contact `michaelallenkuykendall@gmail.com`.

### Philosophy

- **Global by default** — `install.sh` installs once under your OpenCode config root and every repository inherits it; `--repo` limits it to the current repository's `.opencode/`.
- **Deliberate persistence** — state is written on `openstate_checkpoint`, when OpenCode closes, and when the engine's input ends. What a checkpoint wrote survives the engine being killed.
- **Provenance** — `openstate_why` shows where any fact came from.

---

## Community & Support

- **GitHub Issues** — questions, bugs, feature requests
- **Security** — see [SECURITY.md](SECURITY.md) for private disclosure
- **Sponsors** — [GitHub Sponsors](https://github.com/sponsors/Michael-A-Kuykendall) / [SPONSORS.md](SPONSORS.md)

### Sponsorship

🚀 **If openstate helps you, [sponsoring](https://github.com/sponsors/Michael-A-Kuykendall) supports its development.** Sponsorship is separate from buying a license.

- **$5/month**: Coffee tier ☕ - Eternal gratitude + sponsor badge
- **$25/month**: Bug prioritizer 🐛 - Priority support + name in [SPONSORS.md](SPONSORS.md)
- **$100/month**: Corporate backer 🏢 - Logo placement + monthly office hours
- **$500/month**: Infrastructure partner 🚀 - Direct support + roadmap input

[**🎯 Become a Sponsor**](https://github.com/sponsors/Michael-A-Kuykendall)

### Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold its standards.

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — **maintainer-only PRs**, DCO sign-off required. Non-maintainers contribute via issues.

### Governance

See [GOVERNANCE.md](GOVERNANCE.md) — lead maintainer authority, roadmap ownership.

### Security

See [SECURITY.md](SECURITY.md) — private disclosure via GitHub Security Advisories or `michaelallenkuykendall@gmail.com`.

---

## License

Engine binary: Proprietary EULA (see [LICENSE](LICENSE))  
Surface components: MIT (see [PUBLIC-LICENSE](PUBLIC-LICENSE))  
Commercial licensing: `michaelallenkuykendall@gmail.com`