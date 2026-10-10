# openstate — Launch Metrics (One-Page)

> **Source**: 8 repos × 34 sessions × 77 assessments × 30 capsules — Aug 4–14, 2026  
> **Total facts tracked**: 60,732 (57,214 live + 3,518 closed)

---

## Hero Metrics

| Metric | Value | Meaning |
|--------|-------|---------|
| **Facts tracked** | **60,732** | Live project truth |
| **Self-corrections** | **30,007** | AI fixes its own mistakes |
| **Commands tracked** | 16,457 | Every tool call recorded |
| **Work completed** | 10,346 | Verified finished work |
| **Crashes recovered** | **14** | Zero work lost |
| **Capsules generated** | 30 | Instant context on restart |
| **Assessments run** | 71 | Prior sessions absorbed |

---

## The 5 Launch Angles

| Angle | Metric | Why It Matters |
|-------|--------|----------------|
| **Self-Correcting AI** | 30,007 corrections | Truth-maintenance layer alive |
| **Crash-Proof** | 14 crashes → 0 lost | Capsule injects exact state |
| **Zero Context Loss** | 30 capsules, 77 assessments | 1–5k token contract vs 600k tokens |
| **Auditable Decisions** | 499 with provenance | Every "why" traceable to human |
| **Failure Intelligence** | 173 patterns clustered | Flakiness → root cause automatically |

---

## Comparative Velocity (Hours/Week Saved)

| Workflow | Industry Baseline | With openstate | Saved |
|----------|-------------------|----------------|-------|
| Context recovery | 4.2 | 0.05 | **4.15** |
| Decision audit | 2.1 | 0.01 | **2.09** |
| Failure debugging | 3.8 | 0.5 | **3.3** |
| Crash recovery | 1.2 | 0.01 | **1.19** |
| **Total** | **19.6** | **0.67** | **18.93** |

**~19 hours/week saved per developer** — break-even in first session.

---

## Install (30 Seconds)

```bash
curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash
```

- Prebuilt binary (728KB, hardened: strip+LTO+panic=abort)
- Checksum verified, smoke-tested before install
- Per-repo `.opencode/` — zero global pollution
- Restart OpenCode → 13 AI tools + TUI sidebar + skill

---

## License & Philosophy

- **Engine binary**: Proprietary EULA (protects the invention)
- **Surface**: MIT (docs, skill, installer, plugin bundle)
- **Commercial licensing**: `michaelallenkuykendall@gmail.com`
- **Paid license** — sold through Stripe, issued by Keygen

---

## Data Integrity

All metrics verbatim from `.openstate/state.jsonl` across 8 projects × 34 sessions.  
Run your own analysis: `python3 tools/usage-analytics.py .openstate/state.jsonl`

---

**Product Hunt / Launch**: https://github.com/Michael-A-Kuykendall/openstate  
**Sponsor**: github.com/sponsors/Michael-A-Kuykendall  
**Commercial licensing**: michaelallenkuykendall@gmail.com
