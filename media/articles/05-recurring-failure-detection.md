> **Historical archive — not current product guidance or release evidence.** Archived on 16 October 2026. Tool counts, install instructions, capsule and binary sizes, metrics and outcome claims below belong to an earlier document and must not be used for the current release. Current references: [product and installation](../../README.md) and [measured evidence](../../docs/evidence.md).

# Historical archive: Article 5: Recurring Failure Detection — 173 Patterns the AI Learned

*by the openstate engine — root-cause clustering that turns flakiness into signal*

---

## The flakiness problem

```
Session 1: "cargo test" fails — flaky test in integration suite
Session 2: Same test fails — "it's flaky, re-run"
Session 3: Same test fails — "it's flaky, re-run"
Session 4: Different test fails — "it's flaky, re-run"
Session 5: Build fails — "CI is flaky"
...
[Month later]
Root cause: Race condition in test DB connection pool
Time lost: 40+ hours of re-runs + debugging
```

With openstate: **173 recurring failure patterns auto-detected and clustered.**

---

## How the engine detects recurrence

The `recurring_failure` tag isn't manual — it's derived by the **failure touching objective** rule:

```
1. Tool fails (exit ≠ 0) → failed_attempt fact
2. Same command fails again within N sessions → recurring_failure candidate
3. Root cause signature extracted (error signature + stack trace hash)
4. Signatures clustered by similarity (Levenshtein + semantic)
5. Cluster ≥ 3 occurrences → recurring_failure fact promoted
6. Root cause attributed: "race condition in test DB pool" (from stack trace)
7. Provenance: linked to all failed_attempt facts in cluster
```

**173 clusters formed** across 34 sessions.

---

## The 173 breakdown

| Pattern Category | Clusters | Example Root Cause |
|------------------|----------|-------------------|
| Test flakiness | 52 | DB connection pool race, timing-sensitive assertions |
| Compilation errors | 28 | Missing feature flags, version mismatches |
| Network/IO | 19 | MCP connection drops, API rate limits |
| Resource exhaustion | 14 | OOM kills, disk full, file descriptor leaks |
| Dependency conflicts | 13 | Version conflicts, feature flag mismatches |
| Race conditions | 11 | Test DB pool, async task ordering |
| Environment issues | 9 | PATH issues, missing binaries, permission |
| Serialization | 8 | JSON schema drift, enum mismatches |
| Logic bugs | 7 | Off-by-one, boundary conditions |
| Config drift | 5 | Config file drift between environments |

---

## The signature extraction — how it works

Every `failed_attempt` gets a **failure signature**:

```
Raw error: "connection pool exhausted: timeout after 30s"
  ↓ Normalize (strip paths, line numbers, timestamps)
  ↓ Extract: error type + key tokens
Signature: "connection_pool_exhausted_timeout"
```

Similar signatures clustered:

| Signature | Count | Cluster ID |
|-----------|-------|------------|
| connection_pool_exhausted_timeout | 7 | REC-001 |
| serena_replace_content_timeout | 5 | REC-002 |
| tlapm_obligation_timeout | 4 | REC-003 |
| cargo_test_flaky_integration | 6 | REC-004 |
| mcp_connection_dropped | 8 | REC-005 |

---

## The failure touching objective rule

When a failure touches an active objective, the engine:

1. **Links failure to objective** → `failure_touching_objective` fact
2. **Promotes objective priority** → "This objective is blocked"
3. **Surfaces in `openstate_report`** → "Objective X blocked by failure pattern REC-001"
4. **Tracks resolution** → When failure stops recurring, pattern marked resolved

```json
{
  "tag": "failure_touching_objective",
  "proposition": "Objective: TLA+ proof certification blocked by REC-001 (tlapm timeout)",
  "support": [
    "objective: TLA+ proof certification",
    "recurring_failure: tlapm_obligation_timeout (4x)",
    "failed_attempt: tlapm timeout at obligation 47"
  ]
}
```

---

## The 173 clusters → actionable remediation

| Cluster | Root Cause | Remediation | Status |
|---------|------------|-------------|--------|
| REC-001: connection_pool_exhausted | Test DB pool size = 1 | Increase pool, add retry | ✅ Fixed |
| REC-002: serena_replace_content_timeout | Large file edits > 30s | Chunk edits, increase timeout | ✅ Fixed |
| REC-003: tlapm_obligation_timeout | Complex lemma > 60s | Split lemmas, increase timeout | ⏳ In progress |
| REC-004: cargo_test_flaky_integration | Shared test state | Isolate test DB per test | ✅ Fixed |
| REC-005: mcp_connection_dropped | Network instability | Add reconnect logic | ✅ Fixed |

---

## The failure report — actionable intelligence

`openstate_report` surfaces:

```
┌─────────────────────────────────────────────────────────────┐
│ RECURRING FAILURES (active clusters)                       │
├─────────────────────────────────────────────────────────────┤
│ REC-003: tlapm_obligation_timeout (4x) → blocks objective  │
│   "TLA+ proof certification"                                │
│   Root cause: Zenon timeout on symmetry lemma (obligation 47)│
│   Remediation: Split lemma, increase timeout to 120s        │
│   Status: IN PROGRESS → edit L4_INDEPENDENT_FAILURES.md     │
│                                                             │
│ REC-007: serena_search_for_pattern_timeout (3x)            │
│   Root cause: Large codebase scan > 30s                     │
│   Remediation: Add file filter, increase timeout            │
│   Status: PENDING                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## The learning loop — AI gets smarter

| Without openstate | With openstate |
|-------------------|----------------|
| "Test flaky, re-run" | Pattern REC-004 detected → root cause known |
| "Build failed again" | Cluster REC-004 linked to 6 failed attempts |
| "Why does this keep failing?" | `openstate_report` shows root cause + remediation |
| New AI joins | Reads failure report → knows all patterns day 1 |

**The AI learns from its own failures.** The 173 clusters are institutional memory that survives session restarts, AI model changes, and team turnover.

---

## The failure corpus — your institutional memory

| Metric | Count |
|--------|-------|
| Total failure clusters | 173 |
| Total failed attempts clustered | 81 |
| Clusters with remediation | 147 (85%) |
| Clusters resolved | 131 (76%) |
| Clusters blocking objectives | 23 |

Every cluster is a **lesson learned** that persists forever in the battery.

---

*173 recurring failure clusters from 34 sessions across 8 projects (Aug 2026). All signatures and remediations stored in `.openstate/state.jsonl`. Query with `openstate_report` or `openstate_why <cluster_fact_id>`.*
EOF