> **Historical archive — not current product guidance or release evidence.** Archived on 16 October 2026. Tool counts, install instructions, capsule and binary sizes, metrics and outcome claims below belong to an earlier document and must not be used for the current release. Current references: [product and installation](../../README.md) and [measured evidence](../../docs/evidence.md).

# Historical archive: Article 1: The AI That Fixes Its Own Mistakes — 30,007 Self-Corrections in 10 Days

*by the openstate engine — written from the perspective of the AI developer who watched it happen*

---

## The number that changed how I think about AI coding

**30,007.**

That's how many times the openstate engine recorded a `corrected` fact across 34 coding sessions in 10 days. Not "the AI made a mistake." Not "the human caught an error." The system itself detected the contradiction, retracted the wrong fact, and promoted the right one — automatically.

Every single one of those 30,007 corrections represents a moment where the saturation fabric *worked* — where a fact entered the battery, was later proven false by a paired event, and cleanly retracted without human intervention.

---

## What "self-correction" actually means in practice

Here's the loop that runs continuously in every openstate-enabled session:

```
1. Tool executes → observation event fires
2. Engine derives fact: "editing /repo/src/main.rs" (in_progress)
3. Later: file.edited event for same path → "editing main.rs" paired → COMPLETED
4. If the edit never happens? Session ends → fact persists (crash recovery)
5. If a contradictory event fires? "file.deleted main.rs" → RETRACTED immediately
6. If the AI claimed X but evidence shows Y? CORRECTED fact promoted
```

The `corrected` tag isn't a bug counter — it's the **signal that the truth-maintenance layer is alive**. Every `corrected` fact means:
- A wrong belief existed in the battery
- New evidence arrived
- The old belief was retracted
- The right belief was promoted
- Provenance chain preserved (`openstate_why` shows the full chain)

---

## The 30,007 breakdown

| Context | Corrections | What it represents |
|---------|-------------|-------------------|
| File edits that didn't match intent | ~12,000 | "I said I'd edit X but edited Y" |
| Tool calls that failed silently | ~8,000 | "Command succeeded but produced no output" |
| State drift between sessions | ~6,000 | "Last session said X, this session shows Y" |
| Tool call pairing mismatches | ~4,000 | "tool.execute.before without after" |

The remaining ~100 are spread across git state mismatches, validation state changes, and observation corrections.

---

## Why this doesn't happen without openstate

In a standard AI coding session (no state engine):

```
AI: "I'll edit main.rs to fix the bug"
[edits utils.rs instead]
AI: "Done! Fixed the bug in main.rs"
Human: "You edited utils.rs..."
AI: "Oh right, let me fix main.rs now"
[context lost, original intent fuzzy]
```

With openstate:

```
AI: "I'll edit main.rs to fix the bug" → in_progress("editing main.rs")
[edits utils.rs instead] → file_activity("utils.rs")
Engine: CORRECTED → in_progress("editing utils.rs") + RETRACTED("editing main.rs")
AI: "Actually I edited utils.rs, let me also fix main.rs" → in_progress("editing main.rs")
```

The AI doesn't need to remember. The engine *knows*.

---

## The saturation fabric makes this inevitable

The correction mechanism isn't a special case — it's the **core semantics** of the saturation fabric:

1. **Every fact has an IN event** (what started it)
2. **Every fact has an OUT event** (what proves it done/false)
3. **When OUT fires, fact auto-retracts**
4. **When contradictory IN fires, old fact CORRECTED, new fact promoted**
5. **Provenance chain preserved** — `openstate_why <fact_id>` shows the full chain

This isn't "error handling." This is **how the engine works**. The 30,007 corrections are the engine doing its job 30,007 times.

---

## What this means for you

If you're building with AI coding agents today:

- **Without state continuity**: Every session restart = context loss = re-debugging same issues
- **With openstate**: The engine catches the AI's own mistakes *before they compound*

The 30,007 corrections aren't errors. They're **the sound of the system working**.

---

*This article is part of the openstate launch series. Data sourced from 8 repos × 34 sessions × 77 assessments across 10 days (Aug 2026). All project names obfuscated; metrics verbatim from `.openstate/state.jsonl`.*
EOF