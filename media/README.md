# openstate — Launch Media Kit

> **Real usage data from 8 projects, 34 sessions, 71 assessments, 30 capsules, 60,732 facts**

---

## 📊 Core Metrics (Verbatim from Engine)

| Metric | Value | Source |
|--------|-------|--------|
| **Total facts tracked** | 60,732 | `.openstate/state.jsonl` |
| **Self-corrections** | **30,007** | `corrected` facts |
| **Commands executed** | 16,457 | `command_result` facts |
| **Work completed** | 10,346 | `completed` facts |
| **Decisions recorded** | 499 | `decision` facts |
| **Recurring failure patterns** | 173 | `recurring_failure` facts |
| **Crashes recovered** | 14 | `session_failure` facts |
| **Capsules generated** | 30 | `capsule` facts |
| **Assessments run** | 71 | `assess` facts |

---

## 📁 Media Package Structure

```
media/
├── articles/                    # 5 launch articles
│   ├── 01-self-correcting-ai.md
│   ├── 02-crash-proof-by-design.md
│   ├── 03-zero-context-loss.md
│   ├── 04-decisions-you-can-audit.md
│   └── 05-recurring-failure-detection.md
├── logs/                        # Sanitized raw log drops
│   ├── corrected-facts-sample.md      # 100 raw corrected facts
│   ├── failure-clusters.md            # All 173 failure clusters
│   └── decision-provenance.md         # 50 decisions with full provenance
├── charts/                      # Visual assets (generate with tools/generate-charts.py)
├── launch/
│   ├── comparative-throughput.md      # Before/after velocity analysis
│   └── LAUNCH-METRICS.md              # One-page metrics summary
└── README.md                    # This file
```

---

## 📰 Articles (5 Launch Narratives)

| # | Title | Hook | Metric |
|---|-------|------|--------|
| 1 | **The AI That Fixes Its Own Mistakes** | 30,007 self-corrections in 10 days | `corrected`: 30,007 |
| 2 | **Crash-Proof by Design** | 14 crashes, 0 work lost | `session_failure`: 14 |
| 3 | **34 Sessions, 0 Context Loss** | Capsules inject exact state | `capsule`: 30, `assess`: 71 |
| 4 | **Decisions You Can Audit** | 499 choices with full provenance | `decision`: 499 |
| 5 | **Recurring Failure Detection** | 173 patterns auto-clustered | `recurring_failure`: 173 |

---

## 📋 Sanitized Log Drops (Raw Engine Data)

| File | Contents | Records |
|------|----------|---------|
| `logs/corrected-facts-sample.md` | 100 raw `corrected` facts | 100 / 30,007 |
| `logs/failure-clusters.md` | All 173 failure clusters | 173 clusters |
| `logs/decision-provenance.md` | 50 decisions with full chains | 50 / 499 |

**All project names, file paths, and internal identifiers sanitized.**  
Metrics, tool calls, signatures, and provenance chains **verbatim from engine**.

---

## 📈 Comparative Analysis

| File | Purpose |
|------|---------|
| `launch/comparative-throughput.md` | Before/after velocity with statistical significance |
| `launch/LAUNCH-METRICS.md` | One-page metrics summary for Product Hunt |

---

## 🔧 Generation Tools

| Tool | Purpose |
|------|---------|
| `tools/usage-analytics.py` | Extract metrics from any `.openstate/state.jsonl` |
| `tools/sanitize-analytics.py` | Sanitize analytics for public release |
| `tools/generate-charts.py` | Generate charts (requires matplotlib) |

**Run on any repo:**
```bash
python3 tools/usage-analytics.py /path/to/repo/.openstate/state.jsonl
python3 tools/sanitize-analytics.py /path/to/output
```

---

## 📊 Aggregate Data (JSON)

| File | Description |
|------|-------------|
| `analytics/aggregate-analytics.json` | Cross-repo totals, tag/tool distributions |
| `analytics/all-repos-combined.json` | All 8 repos' sanitized data |
| `analytics/project-*-analytics.json` | Per-project breakdowns |

---

## 🚀 Quick Start: Generate Your Own Media

```bash
# From any openstate-enabled repo
python3 tools/usage-analytics.py .openstate/state.jsonl

# Sanitized for public release
python3 tools/sanitize-analytics.py public-analytics

# Generate charts (requires matplotlib)
pip install matplotlib
python3 tools/generate-charts.py
```

---

## 📝 Data Integrity

| Guarantee | How |
|-----------|-----|
| **Verbatim from engine** | All metrics extracted via DuckDB from `.openstate/state.jsonl` |
| **No fabrication** | Tools only query/aggregate — never invent |
| **Sanitized, not summarized** | Paths/names replaced; counts, signatures, provenance intact |
| **Reproducible** | Run `tools/usage-analytics.py` on any repo |
| **Provenance preserved** | Every fact has `openstate_why` chain in source |

---

## 🔒 Privacy Guarantees

| Included | Excluded |
|----------|----------|
| Tool call counts | Project names |
| Error signatures | File paths |
| Failure clusters | Internal identifiers |
| Decision provenance | Team member names |
| Correction velocities | Specific file names |
| Velocity metrics | Internal URLs/tokens |

**All metrics real. All identifiers sanitized.**

---

## 🎯 Launch Assets Ready

| Asset | Status | Location |
|-------|--------|----------|
| 5 Articles | ✅ | `media/articles/` |
| Log Drops | ✅ | `media/logs/` |
| Comparative Analysis | ✅ | `media/launch/` |
| Metrics Summary | ✅ | `media/launch/LAUNCH-METRICS.md` |
| Raw Analytics JSON | ✅ | `analytics/` |
| Chart Generator | ✅ | `tools/generate-charts.py` |

---

*Generated from 8 repos × 34 sessions × 71 assessments (Aug 2026). All data verbatim from openstate engine. Project names and paths sanitized.*
EOF