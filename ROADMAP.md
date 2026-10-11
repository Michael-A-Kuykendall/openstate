# openstate — Roadmap

**Status legend:** ✅ done · ⬜ planned · 💡 proposal

---

## ✅ 0.1.0

What ships is listed in [CHANGELOG.md](CHANGELOG.md): the OpenCode extension (14 state tools, 22 structural tools, resume capsule, sidebar status and toasts), installed per repository or globally, on Linux x86_64, macOS (Intel and Apple Silicon) and Windows x86_64.

## ⬜ Planned

- ⬜ **Other coding environments** — Claude Code, Kiro and GitHub Copilot in VS Code, through the MCP server and session hooks.
- ⬜ **`--purge`** — uninstall that also deletes the `.openstate/` state (today uninstall keeps it, and `--purge` refuses).

## 💡 Proposals (not yet scoped)

- 💡 **`/openstate` user commands** — `checkpoint` and `reset` as slash commands in addition to the AI tools.
- 💡 **Timed background flush** — rejected for now: state is written only at deliberate points (checkpoint, OpenCode closing, the engine's input ending).

---

## Governance

- **Lead Maintainer:** Michael A. Kuykendall
- Contributions are welcome via Pull Requests (maintainer-approved only, see CONTRIBUTING.md)
- The roadmap is set by the lead maintainer
