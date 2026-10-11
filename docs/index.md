---
layout: default
title: openstate
description: A continuously maintained, retractable project-state model for coding agents in OpenCode
---

<div align="center">
  <img src="../assets/openstate-logo.jpg" alt="openstate logo" width="280" />
</div>

# openstate

> **A continuously maintained, retractable project-state model for coding agents in OpenCode.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](PUBLIC-LICENSE)
[![Rust](https://img.shields.io/badge/rust-stable-brightgreen.svg)](https://rustup.rs/)
[![OpenCode](https://img.shields.io/badge/OpenCode-compatible-blue)](https://opencode.ai)

[![💝 Sponsor](https://img.shields.io/badge/💝_Sponsor-ea4aaa?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/Michael-A-Kuykendall)

**openstate is commercial software.** You buy a license through Stripe on the [pricing page](https://michael-a-kuykendall.github.io/openstate/pricing.html); Keygen issues the key. The engine runs locally, needs no account, and sends nothing anywhere.

---

## The Problem

Standard AI coding session:
```
600k tokens → compact / end → summarize → hope the important parts survived
```

Symptoms everyone knows:
- Re-running commands that already failed
- Re-reading the same files
- Re-trying rejected approaches
- Losing mid-edit state on crash
- New session starts with a smoothie of guesswork

---

## The Solution

Events (messages, tool calls, file edits, todos, git, …) flow continuously into a local engine.  
The engine maintains **current project truth** — not a transcript.

Next session receives a **resume capsule** of a few hundred tokens (structured continuation contract) instead of a lossy summary.

### Key Properties
- Facts are replaced or closed when a later event supersedes them
- Provenance: `openstate_why` shows where a fact came from
- Deliberate persistence: on checkpoint, on close, and when the engine's input ends
- Per-repo, local-only

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
Turns observations into live, retractable project facts with full provenance.

### 3. Resume Capsule
Structured continuation contract injected automatically: a few hundred tokens (median about 500, at most about 1,600 across 21 real project stores).

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

