---
layout: default
title: openstate
description: OpenState keeps a running record of what is true in a project (decisions, finished and failed work, what is blocked), updates it as later events replace it, and gives it to the coding agent at the start of every session and after every compaction.
---

<div align="center">
  <img src="../assets/openstate-logo.jpg" alt="openstate logo" width="280" />
</div>

# openstate

> **OpenState keeps a running record of what is true in a project (decisions, finished and failed work, what is blocked), updates it as later events replace it, and gives it to the coding agent at the start of every session and after every compaction.**

[![License: commercial engine, MIT surface](https://img.shields.io/badge/license-commercial%20engine%2C%20MIT%20surface-blue)](LICENSE)
[![OpenCode](https://img.shields.io/badge/OpenCode-compatible-blue)](https://opencode.ai)

[![💝 Sponsor](https://img.shields.io/badge/💝_Sponsor-ea4aaa?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/Michael-A-Kuykendall)

**openstate is commercial software.** You buy a license through Stripe on the [pricing page](https://michael-a-kuykendall.github.io/openstate/pricing.html); Keygen issues the key. The engine runs locally, needs no account, and sends nothing anywhere.

---

## Three problems it addresses

| Problem | What OpenState records | Where the agent sees it |
|---|---|---|
| The agent re-runs a command that already failed in an earlier session. | Each failed command. | `failed_attempts` in the capsule; `openstate_report`; `openstate_report_timeline` shows which session it failed in. |
| After a compaction or a restart, the agent re-reads files to work out what it was doing. | The objective, recent decisions, the files being worked on, uncommitted changes, and whether a test has passed since the last edit. | The capsule, added to the context at the start of the session and after each compaction. |
| The agent retries an approach that was already rejected. | Decisions: messages that give a reason ("because ..."), recorded with that reason. | `decisions` in the capsule; `openstate_why` shows where a decision came from. |

## Who it is for

Developers running long coding-agent sessions in OpenCode who want each new session, and each session after a compaction, to start from what was decided, done, failed and blocked. Claude Code, Muse, Kiro and GitHub Copilot work too, through the bundled MCP server.

## Who it is not for

- **A knowledge base or documentation search.** It records what happens in sessions, not your documents.
- **Semantic or vector search over code.** Use the structural tools or your editor.
- **A hosted or team service.** Everything stays on one machine, in one repository.
- **A transcript store.** It keeps the current state, not the conversation.

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

### 2. Local Rust State Engine
Turns those events into project facts and replaces a fact when a later event supersedes it.

### 3. Resume Capsule
The resume contract, added to the agent's context at the start of every session and after each compaction.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash
```

- Prebuilt engine binary, under 1 MB
- Checksum verified, smoke-tested before install
- Installs into the repository's `.opencode/` (or once for all repositories with `--global`)
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

