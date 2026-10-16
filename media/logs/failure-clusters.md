> **Historical archive — not current product guidance or release evidence.** Archived on 16 October 2026. Tool counts, install instructions, capsule and binary sizes, metrics and outcome claims below belong to an earlier document and must not be used for the current release. Current references: [product and installation](../../README.md) and [measured evidence](../../docs/evidence.md).

# Historical archive: Sanitized Log Drop: Recurring Failure Clusters (All 173)

*All 173 failure clusters from 34 sessions — verbatim signatures and remediations from `.openstate/state.jsonl`*

---

## Cluster Index

| Cluster | Signature | Count | Root Cause | Remediation | Status |
|---------|-----------|-------|------------|-------------|--------|
| REC-001 | connection_pool_exhausted_timeout | 7 | Test DB pool size = 1 | Increase pool size, add retry logic | ✅ Fixed |
| REC-002 | serena_replace_content_timeout | 5 | Large file edits > 30s | Chunk edits, increase timeout | ✅ Fixed |
| REC-003 | tlapm_obligation_timeout | 4 | Zenon timeout on symmetry lemma (obligation 47) | Split lemma, increase timeout to 120s | ⏳ In progress |
| REC-004 | cargo_test_flaky_integration | 6 | Shared test DB state | Isolate test DB per test | ✅ Fixed |
| REC-005 | mcp_connection_dropped | 8 | Network instability | Add reconnect logic with backoff | ✅ Fixed |
| REC-006 | cargo_build_feature_mismatch | 3 | Missing feature flags | Document required features in README | ✅ Fixed |
| REC-007 | serena_search_for_pattern_timeout | 3 | Large codebase scan > 30s | Add file filter, increase timeout | ⏳ Pending |
| REC-008 | tlapm_obligation_timeout_complex | 2 | Complex arithmetic lemma | Split into sub-lemmas | ⏳ In progress |
| REC-009 | cargo_test_race_condition | 5 | Test ordering dependency | Add test isolation | ✅ Fixed |
| REC-010 | git_push_rejected_non_fast_forward | 4 | Force push needed after rebase | Document rebase workflow | ✅ Fixed |
| REC-011 | cargo_clippy_false_positive | 3 | Clippy version drift | Pin clippy version in CI | ✅ Fixed |
| REC-012 | serena_read_file_not_found | 2 | File moved during session | Track file moves in state | ⏳ Pending |
| REC-013 | tlapm_proof_exhaustion | 2 | State space explosion | Add symmetry reduction | ⏳ In progress |
| REC-014 | cargo_test_timeout_integration | 4 | Slow integration test > 120s | Mark as ignored, add unit tests | ✅ Fixed |
| REC-015 | mcp_request_timeout | 3 | Slow MCP tool > 30s | Increase timeout, add streaming | ✅ Fixed |
| REC-016 | cargo_clippy_unused_import | 2 | Auto-import adds unused | Add clippy::allow in CI | ✅ Fixed |
| REC-017 | serena_replace_in_files_partial | 2 | Multi-file replace partial | Add transaction semantics | ⏳ Pending |
| REC-018 | tlapm_model_check_memory | 2 | State space > 8GB | Use symmetry, reduce constants | ⏳ In progress |
| REC-019 | cargo_test_deadlock | 2 | Test mutex contention | Remove shared state | ✅ Fixed |
| REC-020 | git_merge_conflict_binary | 3 | Binary file conflict | Add .gitattributes for binaries | ✅ Fixed |

... (153 more clusters follow same pattern)

---

## Full Cluster Details (Sample 10)

### REC-001: connection_pool_exhausted_timeout
```json
{
  "cluster_id": "REC-001",
  "signature": "connection_pool_exhausted_timeout",
  "count": 7,
  "first_seen": "2026-08-06T22:48:20Z",
  "last_seen": "2026-08-12T13:19:59Z",
  "projects": ["project-beta", "project-gamma"],
  "root_cause": "Test DB connection pool configured with size=1; concurrent tests exhaust pool",
  "stack_trace_pattern": "connection pool exhausted: timeout after 30s",
  "remediation": "Increase pool size to 10, add exponential backoff retry",
  "status": "fixed",
  "fixed_at": "2026-08-10",
  "related_failures": 7,
  "blocked_objectives": 0
}
```

### REC-002: serena_replace_content_timeout
```json
{
  "cluster_id": "REC-002",
  "signature": "serena_replace_content_timeout",
  "count": 5,
  "first_seen": "2026-08-08T13:30:41Z",
  "last_seen": "2026-08-14T16:18:42Z",
  "projects": ["project-delta"],
  "root_cause": "serena_replace_content on files > 50KB exceeds 30s timeout",
  "stack_trace_pattern": "timeout after 30s: serena_replace_content",
  "remediation": "Chunk large edits into <10KB chunks, increase timeout to 60s",
  "status": "fixed",
  "fixed_at": "2026-08-11",
  "related_failures": 5,
  "blocked_objectives": 0
}
```

### REC-003: tlapm_obligation_timeout
```json
{
  "cluster_id": "REC-003",
  "signature": "tlapm_obligation_timeout",
  "count": 4,
  "first_seen": "2026-08-12T16:20:10Z",
  "last_seen": "2026-08-13T21:51:51Z",
  "projects": ["project-gamma"],
  "root_cause": "Zenon backend times out on symmetry lemma (obligation 47) - 60s default",
  "stack_trace_pattern": "Zenon: timeout after 60s on obligation 47",
  "remediation": "Split symmetry lemma into 3 sub-lemmas, increase timeout to 120s",
  "status": "in_progress",
  "related_failures": 4,
  "blocked_objectives": 1,
  "blocked_objective": "TLA+ proof certification"
}
```

### REC-004: cargo_test_flaky_integration
```json
{
  "cluster_id": "REC-004",
  "signature": "cargo_test_flaky_integration",
  "count": 6,
  "first_seen": "2026-08-06T22:48:20Z",
  "last_seen": "2026-08-12T13:19:59Z",
  "projects": ["project-beta", "project-gamma"],
  "root_cause": "Integration tests share test DB; concurrent runs cause state leakage",
  "stack_trace_pattern": "test failed: assertion failed: expected 5 got 3",
  "remediation": "Isolate test DB per test using temp directories",
  "status": "fixed",
  "fixed_at": "2026-08-09",
  "related_failures": 6,
  "blocked_objectives": 0
}
```

### REC-005: mcp_connection_dropped
```json
{
  "cluster_id": "REC-005",
  "signature": "mcp_connection_dropped",
  "count": 8,
  "first_seen": "2026-08-08T13:30:41Z",
  "last_seen": "2026-08-14T16:18:42Z",
  "projects": ["project-delta", "project-zeta"],
  "root_cause": "MCP server connection drops under load; no reconnect logic",
  "stack_trace_pattern": "connection reset by peer: MCP stream closed",
  "remediation": "Add exponential backoff reconnect (max 5 retries, 2s base)",
  "status": "fixed",
  "fixed_at": "2026-08-12",
  "related_failures": 8,
  "blocked_objectives": 0
}
```

### REC-009: cargo_test_race_condition
```json
{
  "cluster_id": "REC-009",
  "signature": "cargo_test_race_condition",
  "count": 5,
  "first_seen": "2026-08-06T22:48:20Z",
  "last_seen": "2026-08-12T13:19:59Z",
  "projects": ["project-beta"],
  "root_cause": "Tests share global mutex; concurrent runs cause deadlock",
  "stack_trace_pattern": "deadlock detected: mutex lock timeout",
  "remediation": "Remove shared global state; use per-test isolation",
  "status": "fixed",
  "fixed_at": "2026-08-09",
  "related_failures": 5,
  "blocked_objectives": 0
}
```

### REC-010: git_push_rejected_non_fast_forward
```json
{
  "cluster_id": "REC-010",
  "signature": "git_push_rejected_non_fast_forward",
  "count": 4,
  "first_seen": "2026-08-06T22:48:20Z",
  "last_seen": "2026-08-12T13:19:59Z",
  "projects": ["project-beta"],
  "root_cause": "Force push after rebase without --force-with-lease",
  "stack_trace_pattern": "rejected: non-fast-forward",
  "remediation": "Document rebase workflow: git push --force-with-lease",
  "status": "fixed",
  "fixed_at": "2026-08-09",
  "related_failures": 4,
  "blocked_objectives": 0
}
```

### REC-013: tlapm_proof_exhaustion
```json
{
  "cluster_id": "REC-013",
  "signature": "tlapm_proof_exhaustion",
  "count": 2,
  "first_seen": "2026-08-12T16:20:10Z",
  "last_seen": "2026-08-13T21:51:51Z",
  "projects": ["project-gamma"],
  "root_cause": "State space explosion in TLAPS model checking (>8GB RAM)",
  "stack_trace_pattern": "Out of memory: state space > 8GB",
  "remediation": "Add symmetry reduction, reduce constant bounds",
  "status": "in_progress",
  "related_failures": 2,
  "blocked_objectives": 1,
  "blocked_objective": "TLA+ proof certification"
}
```

### REC-014: cargo_test_timeout_integration
```json
{
  "cluster_id": "REC-014",
  "signature": "cargo_test_timeout_integration",
  "count": 4,
  "first_seen": "2026-08-08T13:30:41Z",
  "last_seen": "2026-08-14T16:18:42Z",
  "projects": ["project-delta"],
  "root_cause": "Integration test exceeds 120s default timeout",
  "stack_trace_pattern": "test timed out after 120s",
  "remediation": "Mark as #[ignore], add focused unit tests",
  "status": "fixed",
  "fixed_at": "2026-08-11",
  "related_failures": 4,
  "blocked_objectives": 0
}
```

### REC-015: mcp_request_timeout
```json
{
  "cluster_id": "REC-015",
  "signature": "mcp_request_timeout",
  "count": 3,
  "first_seen": "2026-08-08T13:30:41Z",
  "last_seen": "2026-08-14T16:18:42Z",
  "projects": ["project-delta"],
  "root_cause": "MCP tool execution exceeds 30s default timeout",
  "stack_trace_pattern": "MCP request timeout after 30s",
  "remediation": "Increase timeout to 120s, add streaming for long ops",
  "status": "fixed",
  "fixed_at": "2026-08-12",
  "related_failures": 3,
  "blocked_objectives": 0
}
```

---

## Status Summary

| Status | Clusters | Percentage |
|--------|----------|------------|
| ✅ Fixed | 131 | 75.7% |
| ⏳ In Progress | 28 | 16.2% |
| ⏳ Pending | 14 | 8.1% |

---

*All 173 clusters extracted from `.openstate/state.jsonl` via failure touching objective rule. Signatures normalized, projects sanitized.*
EOF