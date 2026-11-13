# Evidence behind the numbers

This page says where the numbers on this site come from: the sources, the method, the windows and denominators, and what the numbers do not show. Every figure here was produced on the maintainer's own machines with private analysis tooling. The scripts are not published. None of the data leaves those machines.

## Method and sources

- **Source:** the raw session and tool-call tables of the maintainer's own OpenCode database (`opencode.db`), read only, plus the Claude Code transcript store and MCP-host logs on the same machines. No telemetry and no third-party data.
- **Scripts (private, not published):** `tools/outcome-stats.mjs` (commits, beads closed and tokens per
  repo per month), `tools/scan-claude-tools.mjs` (Claude Code and MCP-host
  tool calls), and `tools/dogfood/extract_opencode.py` (read-only V2 usage index).
  Windows and denominators are printed with every table.
- **Windows:** the tool-flip comparison is June to September 2026; the adoption comparison is August versus September 2026, the months either side of the structural-tool rollout. Across the measured repos: 906 sessions, 38,346 M tokens, 3,596 commits and 1,956 beads closed.

## Completion cost per completed work item

The core observation: completion cost per unit of work fell where the tools were
adopted.

- In the adopting repo, tokens per completed bead fell from about 16M to 10.6M (34%) and per commit from 16.0M to 11.05M (31%) between August and September 2026 while completions rose (131 to 170 beads, 131 to 163 commits).
- A repo adopting the tools via Claude Code fell from 14.3M to 0.9M tokens per commit.
- Non-adopting controls in the same window were flat or worse; the one
  non-adopting repo whose per-commit cost fell did so during a much lighter work
  phase and is held as confounded, not a toolchain effect.

This is an observed co-movement in the maintainer's repos, not a controlled
study.

## Per-read payload

Structural reads return small, targeted results:

- A structural definition read returned about 1.3 KB, against about 8.6 KB for an average file read.
- In one measured case, a complete function read from a 63 KB file returned 97% less data than reading the file.
- These are bytes per read, not a token or money saving.

## Structural usage in the frozen V2 window

From 4 August through 10 October 2026 UTC, the OpenCode V2 history contains 35,579 OpenState tool uses: 30,782 structural and 4,797 state/lifecycle uses, across 243 sessions including subagents and 20 project directories. A direct call counts once; a Code Mode program counts once for each OpenState tool it uses, even when it loops. The cutoff is exclusive of 11 October 2026 UTC.

| Structural category | Uses |
|---|---:|
| AST searches | 10,420 |
| Text edit previews | 8,102 |
| Text edit applies | 6,694 |
| Bounded text-region reads | 2,467 |

These four categories are a subset of the structural total. Text preview/apply counts do not include every symbol-edit variant. This V2 window has a different denominator and counting method from the legacy reliability corpus below; the totals are not added together.

## Resilience and reachability

- The separate legacy OpenCode session/part corpus, 16 June through 23 September 2026, contains 21,372 OpenState tool calls including state tools, with 19 calls whose tool status is error: 0.09%. This invocation-level status measure is not a structural-only success rate and does not classify every structured refusal returned inside a successful tool result.
- OpenCode uses its native plugin. Other standard MCP clients use the bundled MCP server; the Claude/MCP-host logs measured for this report include over a thousand OpenState MCP operations across Muse sessions. Calling host and transcript source are separate: the same project can recover supported stored sessions through either transport.

## What the numbers do not claim

- Session-level token totals did not fall; they rose with longer sessions.
- No reduction in repeated failures or re-reads is measured at the session level.
- No money-saving claim, and no pricing model is assumed.
- The August-to-September improvement coincides with a production-heavy work mix
  in the same repo, so it is an observed correlation, not causation.
