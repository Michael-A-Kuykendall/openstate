# openstate State Format

> **File**: `.openstate/state.jsonl` (per-project, append-only)

---

## Overview

The openstate battery persists facts as JSON Lines. Each line is a complete fact record with its justification chain. The format is stable, queryable with DuckDB, and human-readable.

```bash
# Query with DuckDB
duckdb -c "SELECT * FROM read_json_auto('.openstate/state.jsonl')"

# Count facts by tag
duckdb -c "SELECT fact->>'tag' as tag, count(*) FROM read_json_auto('.openstate/state.jsonl') GROUP BY 1 ORDER BY 2 DESC"
```

---

## Record Schema

```json
{
  "fact": {
    "tag": "string",                    // Fact type (see tags below)
    "proposition": "string",            // Human-readable statement
    "timestamp": "ISO8601",             // When fact was created
    "source_event": "string",           // Originating event type
    "context": {                        // Event-specific metadata
      "source_session": "string",       // Originating session ID
      "call_ids": ["string"],           // Correlated call IDs
      "file": "string",                 // For file_activity
      "edit_count": "string",           // For file_activity
      ...
    }
  },
  "justifications": [
    {
      "rule": "string",                 // Derivation rule name
      "premises": ["fact_id"],          // Supporting fact IDs
      "stability": "unconditional|defeasible"
    }
  ],
  "live": true                          // false = retracted/closed
}
```

---

## Fact Tags

| Tag | Purpose | Key Fields |
|-----|---------|------------|
| `objective` | Current high-level goal | `proposition`: goal statement |
| `decision` | Architectural choice | `proposition`: choice + reasoning |
| `completed` | Finished work | `proposition`: what was done |
| `in_progress` | Active work | `proposition`: "editing X" |
| `failed_attempt` | Dead end / failed try | `proposition`: what failed |
| `blocker` | Current obstacle | `proposition`: what's blocked |
| `next_action` | Recommended next step | `proposition`: recommended action |
| `corrected` | Self-correction | `proposition`: corrected fact |
| `recurring_failure` | Pattern detected | `proposition`: root cause |
| `failed_attempt` | Failed command/tool | `proposition`: command + exit code |
| `command_result` | Tool execution result | `proposition`: command + succeeded/failed |
| `validation_state` | Test/check status | `proposition`: status, generation |
| `git_state` | Repository state | `proposition`: branch, dirty, etc. |
| `file_activity` | File edit tracking | `context.file`, `edit_count` |
| `session_failure` | Session crash | `proposition`: crash details |
| `capsule` | Resume capsule | `proposition`: capsule JSON |
| `corrected` | Self-correction | `proposition`: corrected fact |
| `aborted` | Interrupted work | `proposition`: what was aborted |

---

## Justification Rules

| Rule | Description |
|------|-------------|
| `observation` | Direct observation from event |
| `decision_derived` | Decision promoted from user directive |
| `pairing` | IN/OUT event pairing (callID) |
| `latest_wins` | Latest-wins upsert (file/git state) |
| `retraction` | OUT event retracts IN fact |
| `correction` | Contradictory evidence promotes new fact |
| `recurring_failure` | Failure pattern clustering |
| `objective_promotion` | User directive promoted to objective |
| `decision_derived` | Decision derived from evidence |

---

## Query Examples

```sql
-- All live facts
SELECT * FROM read_json_auto('.openstate/state.jsonl') WHERE live = true;

-- Provenance chain for a fact
WITH RECURSIVE chain AS (
  SELECT fact_id, fact, justifications, 1 as depth
  FROM facts WHERE fact_id = 1234
  UNION ALL
  SELECT f.fact_id, f.fact, f.justifications, c.depth + 1
  FROM facts f
  JOIN chain c ON f.fact_id = ANY(c.justifications->>'premises')
  WHERE c.depth < 10
) SELECT * FROM chain;

-- Self-corrections per session
SELECT context->>'source_session', count(*)
FROM read_json_auto('.openstate/state.jsonl')
WHERE fact->>'tag' = 'corrected'
GROUP BY 1 ORDER BY 2 DESC;

-- Decision provenance
SELECT f.fact->>'proposition', f.justifications
FROM read_json_auto('.openstate/state.jsonl') f
WHERE f.fact->>'tag' = 'decision' AND f.live = true;
```

---

## Querying with openstate Tools

| Tool | Purpose |
|------|---------|
| `openstate_state` | Full project state summary |
| `openstate_capsule` | Resume capsule (frontier views) |
| `openstate_report` | Black-box "what's broken" |
| `openstate_report_timeline` | Chronological session→facts |
| `openstate_why <fact_id>` | Full provenance chain |
| `openstate_assess <session_id>` | Absorb prior session |
| `openstate_why <fact_id>` | Full justification chain |

---

## Schema Evolution

The format is append-only. New fields may be added to `context` or new tags added. Existing records are never modified — corrections create new `corrected` facts that reference the old ones.

Version: 1.0 (Aug 2026)
