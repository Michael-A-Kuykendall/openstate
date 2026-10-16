> **Historical archive — not current product guidance or release evidence.** Archived on 16 October 2026. Tool counts, install instructions, capsule and binary sizes, metrics and outcome claims below belong to an earlier document and must not be used for the current release. Current references: [product and installation](../../README.md) and [measured evidence](../../docs/evidence.md).

# Historical archive: Article 4: Decisions You Can Audit — 499 Choices with Full Provenance

*by the openstate engine — every "why" traceable to the original human message*

---

## The decision traceability problem

```
Human: "Use Redis for caching"
AI: "Done, Redis cache implemented"
[6 months later]
New AI: "Why Redis?"
Original human: *gone*
Codebase: *no comments*
Git history: *squashed merge*
Result: Redis removed, replaced with in-memory → production cache stampede
```

With openstate:
```
Human: "Use Redis for caching because we need distributed invalidation across pods"
[Engine derives Decision fact with full provenance]
[6 months later]
New AI: openstate_why <decision_fact_id>
Engine: "Decision: Use Redis for caching
         Reason: distributed invalidation across pods
         Source: user message at 2026-08-12T14:32:11Z
         Provenance: user_directive → decision_derived → live"
```

---

## 499 decisions, every one traceable

| Metric | Count |
|--------|-------|
| Decisions recorded | 499 |
| With full provenance | 499 (100%) |
| Average provenance depth | 3.2 hops |
| Direct user message links | 447 (89.6%) |

Every decision fact has a **complete justification chain**:

```
Decision: Use SQLite for local state storage
  ↳ Because: need zero-config local persistence
    ↳ Because: user said "zero-config is non-negotiable" (msg_0047)
      ↳ Source: user_directive (user message at 2026-08-04T15:15:44Z)
    ↳ Supported by: file_activity("src/engine/src/persist.rs") at 2026-08-04T15:15:44Z
    ↳ Supported by: tool.execute.after bash("cargo test") at 2026-08-04T15:16:12Z
```

---

## The `openstate_why` query — instant audit

```bash
# CLI
openstate_why 1247

# Output:
FACT 1247: Decision — Use SQLite for local state storage
LIVE: true
PROVENANCE:
  ↳ rule: decision_derived
    premises:
      - fact 1245: user_directive("Use SQLite for local state because zero-config")
      - fact 1246: file_activity("src/engine/src/persist.rs")
      - fact 1247: tool.execute.after bash("cargo test")
    stability: unconditional
  ↳ source: user message at 2026-08-04T15:15:44Z ("Use SQLite for local state because zero-config")
```

**Every decision traces to a human message.** No "we decided" without a source.

---

## The 499 breakdown

| Category | Count | Example |
|----------|-------|---------|
| Architecture | 127 | "Use SQLite for local state" |
| Algorithm choice | 89 | "Saturation fabric for fact propagation" |
| Tool integration | 76 | "OpenCode plugin for event capture" |
| Data model | 68 | "Fact tag enum with DisposalKind" |
| API design | 54 | "13 AI tools with specific signatures" |
| Deployment | 42 | "Per-repo install.sh model" |
| Testing strategy | 31 | "Pipeline tests with session replay" |
| Security | 12 | "Private disclosure via Security Advisories" |

---

## The provenance graph — not a linear log

Decisions don't exist in isolation. They form a **DAG of dependencies**:

```
Decision: Per-repo install model
  ↳ Requires: Decision: Engine binary distribution
    ↳ Requires: Decision: install.sh downloads from GH Releases
      ↳ Supported by: tool.execute.after bash("gh release create...")
      ↳ Supported by: Decision: Engine binary hardening (strip+LTO)
        ↳ Supported by: corrected(30007) → binary size 728KB
```

Every decision knows what it depends on. `openstate_why` traverses the full graph.

---

## The audit API

```bash
# CLI
openstate_why 1247                    # single fact
openstate_why --tag decision          # all decisions
openstate_why --source user           # all user-sourced

# JSON output for tooling
openstate_why 1247 --json
```

```json
{
  "fact_id": 1247,
  "tag": "decision",
  "proposition": "Use SQLite for local state storage",
  "live": true,
  "provenance": [
    {
      "rule": "decision_derived",
      "premises": [1245, 1246, 1247],
      "stability": "unconditional"
    },
    {
      "rule": "user_directive",
      "premises": [],
      "source": "user message at 2026-08-04T15:15:44Z",
      "text": "Use SQLite for local state because zero-config"
    }
  ]
}
```

---

## The audit trail is the product

| Without openstate | With openstate |
|-------------------|----------------|
| "Why did we choose X?" → oral history | `openstate_why 1247` → 2 seconds |
| Decision lost in squashed merge | Full provenance in battery |
| "Who decided this?" → git blame → lost | Direct link to user message |
| Architecture drift undetected | Dependency graph catches conflicts |

---

## The decision ledger is the battery

499 decisions = 499 audit points. Each one:
- **Live** (still in force) or **Closed** (superseded, with reason)
- **Traced to human message** (89.6% direct user message)
- **Supported by evidence** (file edits, tool runs, test results)
- **Connected in dependency graph** (what this enables, what enables this)

The battery isn't just "what happened." It's **"why it happened, and what depends on it."**

---

*499 decisions recorded across 8 projects (Aug 2026). All provenance chains intact in `.openstate/state.jsonl`. Query with `openstate_why <fact_id>` in any openstate-enabled repo.*
EOF