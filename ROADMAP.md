# openstate — Roadmap

**Status legend:** ✅ done · ⬜ planned · 💡 proposal

---

## ✅ 0.1.0

What ships is listed in [CHANGELOG.md](CHANGELOG.md): the OpenCode extension (14 state tools, 22 structural tools, resume capsule, sidebar status and toasts) and the MCP server for other hosts, installed per repository or globally, on Linux x86_64, macOS (Intel and Apple Silicon) and Windows x86_64.

## ⬜ Planned

- ⬜ **Session hooks for other hosts** — Claude Code, Kiro and GitHub Copilot in VS Code already work through the bundled MCP server; hooks would put the capsule into their context automatically, as OpenCode does.

## 💡 Proposals (not yet scoped)

- 💡 **`/openstate` user commands** — `checkpoint` and `reset` as slash commands in addition to the AI tools.
- 💡 **Timed background flush** — rejected for now: state is written only at deliberate points (checkpoint, OpenCode closing, the engine's input ending).

---

## Governance

- **Lead Maintainer:** Michael A. Kuykendall
- Contributions are welcome via Pull Requests (maintainer-approved only, see CONTRIBUTING.md)
- The roadmap is set by the lead maintainer
