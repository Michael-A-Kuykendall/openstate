---
layout: default
title: openstate
description: OpenState keeps a running record of what is true in a project (decisions, finished and failed work, what is blocked), updates it as later events replace it, and gives it to the coding agent at the start of every session and after every compaction.
---

<div align="center">
  <img src="../assets/openstate-logo.jpg" alt="openstate logo" width="280" />
</div>

# openstate

> **OpenState gives coding agents two equal capabilities: structural code search, read and edit with guarded preview-to-apply writes, and a persistent, provenance-backed record of what is true in a project — decisions, finished and failed work, what is blocked — kept local and available across sessions through OpenCode and MCP.**

[![License: commercial engine, MIT surface](https://img.shields.io/badge/license-commercial%20engine%2C%20MIT%20surface-blue)](LICENSE)
[![OpenCode](https://img.shields.io/badge/OpenCode-compatible-blue)](https://opencode.ai)

[![💝 Sponsor](https://img.shields.io/badge/💝_Sponsor-ea4aaa?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/Michael-A-Kuykendall)

**openstate is commercial software.** You buy a license through Stripe on the [pricing page](https://michael-a-kuykendall.github.io/openstate/pricing.html); Keygen issues the key. The engine runs locally, needs no account, and sends nothing anywhere.

---

## Three problems it addresses

| Problem | What OpenState records | Where the agent sees it |
|---|---|---|
| The agent re-runs a command that already failed in an earlier session. | Each failed command. | `failed_attempts` in the capsule; `openstate_report`; `openstate_report_timeline` shows which session it failed in. |
| After a compaction or a restart, the agent re-reads files to work out what it was doing. | The objective, recent decisions, the files being worked on, uncommitted changes, and whether a test has passed since the last edit. | The capsule, injected automatically in native OpenCode or read on demand through MCP. |
| The agent retries an approach that was already rejected. | Decisions: messages that give a reason ("because ..."), recorded with that reason. | `decisions` in the capsule; `openstate_why` shows where a decision came from. |

## Who it is for

Developers using coding agents who need structural code search, guarded edits and persistent project state. Native OpenCode supplies automatic event capture and capsule injection; standard MCP clients use the same 36 tools and supported stored-session recovery on demand.

## Who it is not for

- **A knowledge base or documentation search.** It records what happens in sessions, not your documents.
- **Semantic or vector search over code.** Use the structural tools or your editor.
- **A hosted or team service.** Everything stays on one machine, in one repository.
- **A transcript store.** It keeps the current state, not the conversation.

---

## Reading, searching and editing code

OpenState's 22 structural code tools are a core capability. Built on ast-grep, they let the agent work in definitions instead of whole files: search for a name, read just that function or type, and change it through a preview that is checked before anything is written. In one measured case, reading a complete function from a 63 KB file returned 97% less data than reading the file. Measured in the maintainer's session history, completion cost fell where the tools were adopted: in the openstate project, tokens per completed work item fell from about 16M to 10.6M (34%) and per commit from 16.0M to 11.05M (31%) between August and September 2026 while completions rose, and a repo that adopted the tools via Claude Code fell from 14.3M to 0.9M tokens per commit while non-adopting repos were flat or worse except one that improved in a lighter work phase. These are observed co-movements in the maintainer's repos, not a controlled study; see [Structural tools](STRUCTURAL-TOOLS.md) for the tools, the guarantees of the write path, the 18 supported languages and the known weaknesses.

---

## The Numbers

Measured on the maintainer's own projects, August to October 2026:

| Metric | Value |
|--------|-------|
| OpenState tool uses in OpenCode | 35,579 |
| Sessions that used it | 243 |
| Projects | 20 |
| Records held in project stores now | 82,586 |
| Median resume capsule | about 500 tokens |

---

## How It Works (Black-Box Level)

### 1. Observer Plugin (TypeScript)
Captures the live event stream from OpenCode.

### 2. Structural Code Tools

The shared ast-grep core searches and reads definitions and applies guarded preview-to-apply edits through either transport.

### 3. Local Rust State Engine
Turns those events into project facts and replaces a fact when a later event supersedes it.

### 4. Resume Capsule
The resume contract, injected automatically in native OpenCode at session start and after compaction, or read on demand through MCP.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash
```

- Prebuilt engine binary, under 3 MB
- Checksum verified, smoke-tested before install
- Installs once for all repositories by default (`--repo` targets the current repository's `.opencode/`)
- Restart OpenCode → 36 AI tools (14 state + 22 structural) + TUI sidebar + skill

---

## State tools (14)

| Tool | Purpose |
|------|---------|
| `openstate_state` | Full project state |
| `openstate_why` | Provenance chain |
| `openstate_checkpoint` | Force-flush state |
| `openstate_capsule` | Resume contract |
| `openstate_export` | Full state dump |
| `openstate_reset` | Deliberate full wipe |
| `openstate_assess` | Absorb prior session |
| `openstate_report` | Black-box "what's broken" |
| `openstate_report_timeline` | Chronological session map |
| `openstate_close` | Retract false positives |
| `openstate_sessions` | List prior sessions |
| `openstate_doctor` | Engine health check |
| `openstate_restart` | Restart engine sidecar |
| `openstate_toast` | Completion toasts on/off |

---

## Philosophy

- **Paid license** — sold through Stripe, issued by Keygen
- **Engine binary proprietary** — protects the invention
- **Surface MIT** — docs, skill, installer, plugin
- **Commercial licensing available** — `michaelallenkuykendall@gmail.com`
- **State, not story** — current truth, not transcript

---

## Quick Links

- [GitHub Repo](https://github.com/Michael-A-Kuykendall/openstate)
- [GitHub Sponsors](https://github.com/sponsors/Michael-A-Kuykendall)
- [Security Policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)
- [License](LICENSE) / [Public License](PUBLIC-LICENSE)
- [Code of Conduct](CODE_OF_CONDUCT.md)

