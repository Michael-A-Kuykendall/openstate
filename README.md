<div align="center">
  <img src="assets/openstate-logo.jpg" alt="openstate logo" width="220" />
</div>

# openstate

> **A continuously maintained, retractable project-state model for coding agents in OpenCode.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](PUBLIC-LICENSE)
[![Security](https://img.shields.io/badge/Security-Audited-green)](SECURITY.md)
[![Rust](https://img.shields.io/badge/rust-stable-brightgreen.svg)](https://rustup.rs/)
[![OpenCode](https://img.shields.io/badge/OpenCode-compatible-blue)](https://opencode.ai)

[![💝 Sponsor this project](https://img.shields.io/badge/💝_Sponsor_this_project-ea4aaa?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/Michael-A-Kuykendall)

**openstate is commercial software.** You buy a license through Stripe on the [pricing page](https://michael-a-kuykendall.github.io/openstate/pricing.html); Keygen issues the key. The engine runs locally, needs no account, and sends nothing anywhere.

### 💝 Support openstate's Growth

🚀 **If openstate helps you, [sponsoring](https://github.com/sponsors/Michael-A-Kuykendall) supports its development.** Sponsorship is separate from buying a license.

- **$5/month**: Coffee tier ☕ - Eternal gratitude + sponsor badge
- **$25/month**: Bug prioritizer 🐛 - Priority support + name in [SPONSORS.md](SPONSORS.md)
- **$100/month**: Corporate backer 🏢 - Logo placement + monthly office hours
- **$500/month**: Infrastructure partner 🚀 - Direct support + roadmap input

[**🎯 Become a Sponsor**](https://github.com/sponsors/Michael-A-Kuykendall) | See our amazing [sponsors](SPONSORS.md) 🙏

---

## Table of Contents

- [What Is openstate?](#what-is-openstate)
- [🔧 Architecture](#architecture)
- [📦 Install](#install)
- [🚀 Quick Start (30 seconds)](#quick-start-30-seconds)
- [🛠 AI Tools](#ai-tools)
- [📖 Documentation Hub](#documentation-hub)
- [🏛️ License & Philosophy](#license--philosophy)
- [🌍 Community & Support](#community--support)

---

## What Is openstate?

openstate is an **OpenCode extension** — a single-binary local state engine that gives coding agents in OpenCode a continuously maintained, provenance-backed model of project state. Point your OpenCode session at openstate and it just works — locally, privately, and free. Other coding environments are on the roadmap.

**🔧 The engine is proprietary** (distributed under a commercial EULA). The surface components — documentation, skill, installer, plugin bundle — are MIT-licensed. Commercial licensing for embedding the engine in other products is available.

---

## Architecture

### 1. OpenCode Observer Plugin (TypeScript)

Captures events: `message.updated`, `tool.execute.before/after`, `file.edited`, `todo.updated`, `session.idle`, `session.compacted`, etc.

### 2. Local Rust State Engine

Converts observations into live project facts with continuous derivation, automatic retraction on contradictory evidence, and full provenance chains.

### 3. Resume Capsule

A structured continuation contract injected automatically on new sessions and compaction — 1,000–5,000 tokens carrying the exact state needed to resume work.

---

## Install

```bash
# 1. One-liner (curl|bash — downloads prebuilt bundle, installs into CWD)
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash

# 2. Target a specific repo
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | OPENSTATE_CONFIG_DIR=/path/to/repo/.opencode bash

# 3. gh CLI (works for private repos)
gh api repos/Michael-A-Kuykendall/openstate/contents/install.sh --jq .content | base64 -d | bash

# 4. Clone once, install anywhere
git clone --depth 1 https://github.com/Michael-A-Kuykendall/openstate.git /tmp/os
/tmp/os/install.sh
OPENSTATE_CONFIG_DIR=/path/to/other/.opencode /tmp/os/install.sh
```

Downloads the prebuilt engine binary + plugin bundle from GitHub Releases, verifies sha256, smoke-tests the engine, and installs the complete bundle into **this repo's** `.opencode/` directory. No compiler or Node toolchain required at install time. openstate is **per-repo**: it only activates in repos that run `install.sh`. Restart OpenCode, done.

Verify an existing install: `./install.sh --check`

State lives per-project in `.openstate/state.jsonl`. Query it directly with DuckDB: `SELECT * FROM read_json_auto('.openstate/state.jsonl')`.

---

## Quick Start (30 seconds)

```bash
# In any repo
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash

# Restart OpenCode
 # You now have 14 AI tools + TUI sidebar (status line + completion toasts) + skill
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

The AI gets 14 tools automatically via the OpenCode plugin:

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

The `.opencode/skills/openstate/SKILL.md` skill tells the AI when to use them.

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
| [docs/STATE-FORMAT.md](docs/STATE-FORMAT.md) | State format reference |
| [docs/FAQ.md](docs/FAQ.md) | Frequently asked questions |

---

## License & Philosophy

**Engine binary (openstate-engine):** Proprietary, distributed under a commercial EULA.  
**Surface components (docs, skill, installer, plugin bundle):** MIT License — see [PUBLIC-LICENSE](PUBLIC-LICENSE).  
**Commercial licensing** for embedding the engine in other products: contact `michaelallenkuykendall@gmail.com`.

### Philosophy

- **Per-repo install** — `install.sh` targets `.opencode/` (not global), so openstate only activates in repos that opt in.
- **Semantic fact lifecycle** — facts enter on a real extension event and exit only when a *paired* event proves them invalid.
- **Crash recovery** — in-progress work persists across process death: persistence is **deliberate** (explicit `checkpoint`, guaranteed dispose-flush on app close, stdin-EOF last resort).
- **Provenance** — `openstate_why` explains every fact's justification chain.
- **Compact/prune** — dead records are collected at session boundaries and on demand; the store stays bounded.
- **Invisible infrastructure** — minimal surface area, zero-config, drop-in.

---

## Community & Support

- **GitHub Discussions** — questions, ideas, feedback
- **GitHub Issues** — bugs, feature requests (non-maintainers welcome)
- **Security** — see [SECURITY.md](SECURITY.md) for private disclosure
- **Sponsors** — [GitHub Sponsors](https://github.com/sponsors/Michael-A-Kuykendall) / [SPONSORS.md](SPONSORS.md)

### Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you agree to uphold its standards.

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — **maintainer-only PRs**, DCO sign-off required. Non-maintainers contribute via issues and discussions.

### Governance

See [GOVERNANCE.md](GOVERNANCE.md) — lead maintainer authority, roadmap ownership.

### Security

See [SECURITY.md](SECURITY.md) — private disclosure via GitHub Security Advisories or `security@openstate.dev`.

---

## Sponsors

These amazing people make openstate possible 🙏

*Want to see your name/logo here?* [Become a sponsor](https://github.com/sponsors/Michael-A-Kuykendall)!

---

## License

Engine binary: Proprietary EULA (see [LICENSE](LICENSE))  
Surface components: MIT (see [PUBLIC-LICENSE](PUBLIC-LICENSE))  
Commercial licensing: `michaelallenkuykendall@gmail.com`