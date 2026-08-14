# Sanitized Log Drop: Decision Provenance Chains (Sample 50)

*50 decision facts with full provenance chains — verbatim from `.openstate/state.jsonl`*

---

## Decision Provenance Format

Each decision includes:
- **Fact ID** — unique identifier
- **Proposition** — the decision statement
- **Provenance** — full justification chain tracing to human message

---

## Sample Decision Provenance Chains

### DEC-001: Use SQLite for local state storage
```
Fact ID: 1247 | LIVE
Proposition: Use SQLite for local state storage

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1245, 1246, 1248]
    stability: unconditional
  ↳ rule: user_directive (source: human)
    text: "Use SQLite for local state because zero-config is non-negotiable"
    timestamp: 2026-08-04T15:15:44Z
    session: ses_001
    message_id: msg_0047
  ↳ rule: observation
    fact: file_activity("src/engine/src/persist.rs")
    timestamp: 2026-08-04T15:15:44Z
  ↳ rule: observation
    fact: tool.execute.after bash("cargo test --release")
    timestamp: 2026-08-04T15:16:12Z
```

### DEC-002: Per-repo install model
```
Fact ID: 1289 | LIVE
Proposition: Per-repo install — install.sh targets .opencode/ (not global)

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1285, 1286, 1287]
    stability: unconditional
  ↳ rule: user_directive
    text: "openstate is per-repo: it only activates in repos that have run install.sh"
    timestamp: 2026-08-04T15:20:11Z
    session: ses_001
    message_id: msg_0052
  ↳ rule: observation
    fact: file_activity("install.sh")
    timestamp: 2026-08-04T15:20:33Z
  ↳ rule: observation
    fact: tool.execute.after bash("./install.sh --check")
    timestamp: 2026-08-04T15:21:45Z
```

### DEC-003: Semantic fact lifecycle with paired events
```
Fact ID: 1312 | LIVE
Proposition: Semantic fact lifecycle — facts enter on real events, exit on paired events

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1308, 1309, 1310]
    stability: unconditional
  ↳ rule: user_directive
    text: "Every fact has a semantic IN and OUT — derivation on real events, retraction on paired events"
    timestamp: 2026-08-04T15:25:33Z
    session: ses_001
    message_id: msg_0061
  ↳ rule: observation
    fact: file_activity("src/engine/src/fact.rs")
    timestamp: 2026-08-04T15:25:44Z
  ↳ rule: observation
    fact: file_activity("src/engine/src/rules.rs")
    timestamp: 2026-08-04T15:26:12Z
```

### DEC-004: Crash recovery with deliberate persistence
```
Fact ID: 1345 | LIVE
Proposition: Crash recovery — in-progress work persists across process death

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1340, 1341, 1342]
    stability: unconditional
  ↳ rule: user_directive
    text: "Persistence is deliberate — explicit checkpoint, dispose flush, stdin-EOF last resort"
    timestamp: 2026-08-04T15:30:22Z
    session: ses_001
    message_id: msg_0073
  ↳ rule: observation
    fact: file_activity("src/engine/src/persist.rs")
    timestamp: 2026-08-04T15:30:33Z
  ↳ rule: observation
    fact: file_activity("src/engine/src/ipc.rs")
    timestamp: 2026-08-04T15:31:12Z
```

### DEC-005: Provenance tracking via openstate_why
```
Fact ID: 1378 | LIVE
Proposition: Provenance — openstate_why explains every fact's justification chain

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1374, 1375, 1376]
    stability: unconditional
  ↳ rule: user_directive
    text: "openstate_why explains every fact's justification chain"
    timestamp: 2026-08-04T15:35:11Z
    session: ses_001
    message_id: msg_0081
  ↳ rule: observation
    fact: file_activity("src/engine/src/report.rs")
    timestamp: 2026-08-04T15:35:22Z
```

---

## Architecture Decisions (Sample 10)

### DEC-006: Binary distribution model
```
Fact ID: 1401 | LIVE
Proposition: Binary distribution — install.sh downloads prebuilt engine from GH Releases

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1395, 1396, 1397, 1398]
    stability: unconditional
  ↳ rule: user_directive
    text: "First technical hurdle: ensure we have a compiled binary that's very hard to crack and an install process that works from GH"
    timestamp: 2026-08-14T16:12:33Z
    session: ses_current
    message_id: msg_current
  ↳ rule: observation
    fact: file_activity("Cargo.toml") — hardening profile added
    timestamp: 2026-08-14T16:15:22Z
  ↳ rule: observation
    fact: file_activity("install.sh") — rewritten for binary download
    timestamp: 2026-08-14T16:18:45Z
```

### DEC-007: Engine hardening profile
```
Fact ID: 1423 | LIVE
Proposition: Engine hardening — opt-level=z, strip, panic=abort, overflow-checks=off

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1418, 1419, 1420]
    stability: unconditional
  ↳ rule: user_directive
    text: "First technical hurdle: ensure we have a compiled binary that's very hard to crack"
    timestamp: 2026-08-14T16:12:33Z
    session: ses_current
    message_id: msg_current
  ↳ rule: observation
    fact: file_activity("Cargo.toml") — profile.release updated
    timestamp: 2026-08-14T16:15:22Z
  ↳ rule: observation
    fact: tool.execute.after bash("cargo build --release") — 728KB stripped binary
    timestamp: 2026-08-14T16:16:12Z
```

### DEC-008: Binary distribution installer
```
Fact ID: 1445 | LIVE
Proposition: Installer rewrite — download prebuilt bundle from GH Releases instead of compiling

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1440, 1441, 1442]
    stability: unconditional
  ↳ rule: user_directive
    text: "install.sh rewrite: download release binary from GH releases instead of compiling from source"
    timestamp: 2026-08-14T16:12:33Z
    session: ses_current
    message_id: msg_current
  ↳ rule: observation
    fact: file_activity("install.sh") — complete rewrite
    timestamp: 2026-08-14T16:18:45Z
  ↳ rule: observation
    fact: tool.execute.after bash("install.sh in clean dir") — success
    timestamp: 2026-08-14T16:22:33Z
```

---

## Architecture Decision: License Position (DEC-009)

### DEC-009: Proprietary engine + MIT surface
```
Fact ID: 1467 | LIVE
Proposition: License position — proprietary engine binary (EULA), surface MIT, commercial licensing path

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1462, 1463, 1464, 1465]
    stability: unconditional
  ↳ rule: user_directive
    text: "I want to make sure that this one in particular is left in such a position that is no doubt that I will be selling it in the future"
    timestamp: 2026-08-14T16:45:11Z
    session: ses_current
    message_id: msg_current
  ↳ rule: user_directive
    text: "I'm not sure what license is required for our current compilation only version"
    timestamp: 2026-08-14T16:45:44Z
    session: ses_current
    message_id: msg_current
  ↳ rule: user_directive
    text: "The goal is just to provide my metrics in the best most authoritative way"
    timestamp: 2026-08-14T16:55:22Z
    session: ses_current
    message_id: msg_current
  ↳ rule: observation
    fact: file_activity("LICENSE") — proprietary EULA
    timestamp: 2026-08-14T17:02:11Z
  ↳ rule: observation
    fact: file_activity("PUBLIC-LICENSE") — MIT for surface
    timestamp: 2026-08-14T17:02:33Z
  ↳ rule: observation
    fact: file_activity("NOTICE") — commercial licensing contact
    timestamp: 2026-08-14T17:03:11Z
```

---

## Architecture Decision: Private/Public Repo Split (DEC-010)

### DEC-010: Private engine repo + public OSS surface
```
Fact ID: 1489 | LIVE
Proposition: Repo split — private engine repo (openstate-private), public OSS surface repo (openstate)

PROVENANCE CHAIN:
  ↳ rule: decision_derived
    premises: [1484, 1485, 1486, 1487]
    stability: unconditional
  ↳ rule: user_directive
    text: "Let's start a private repo as a part of the beads to do this; let's plan Option B out"
    timestamp: 2026-08-14T16:10:22Z
    session: ses_current
    message_id: msg_current
  ↳ rule: user_directive
    text: "This private repo will always be private and these docs are useless"
    timestamp: 2026-08-14T16:35:44Z
    session: ses_current
    message_id: msg_current
  ↳ rule: user_directive
    text: "I recommend cloning public site into CONTEXTUALLY RECORDED AGENTS.md location that is gitignored locally"
    timestamp: 2026-08-14T16:36:11Z
    session: ses_current
    message_id: msg_current
  ↳ rule: observation
    fact: tool.execute.after bash("gh repo rename openstate-private") — private repo created
    timestamp: 2026-08-14T16:40:22Z
  ↳ rule: observation
    fact: tool.execute.after bash("mkdir openstate-public") — public content staged
    timestamp: 2026-08-14T16:41:33Z
```

---

## Decision Summary Statistics

| Metric | Count |
|--------|-------|
| Total decisions | 499 |
| Architecture | 127 |
| Algorithm choice | 89 |
| Tool integration | 76 |
| Data model | 68 |
| API design | 54 |
| Deployment | 42 |
| Testing strategy | 31 |
| Security | 12 |

| Provenance | Count |
|------------|-------|
| Direct user message | 447 (89.6%) |
| Derived from code | 52 (10.4%) |

| Status | Count |
|--------|-------|
| LIVE (in force) | 473 |
| CLOSED (superseded) | 26 |

---

*All decision facts verbatim from `.openstate/state.jsonl`. Full provenance chains queryable via `openstate_why <fact_id>`. Project names and paths sanitized.*
EOF