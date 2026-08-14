# openstate — Roadmap

> A continuously maintained, retractable project-state model for coding
> agents. Every fact has a semantic **in** (the event that starts it) and a
> semantic **out** (the paired event that proves it no longer holds).

**Status legend:** ✅ done · 🔶 in progress · ⬜ planned · 💡 proposal

---

## Done

- ✅ **Per-repo install** — `install.sh` targets `.opencode/` (not global), so
  openstate only activates in repos that opt in.
- ✅ **Semantic fact lifecycle** — facts enter on a real extension event and
  exit only when a *paired* event proves them invalid (callID pairing for
  `editing X`, latest-wins upserts for file/git state). Broken-off facts
  (crash mid-edit) survive so work resumes. `fact.rs` declares a `DisposalKind`
  for every tag — adding a tag fails to compile until you classify it.
- ✅ **Crash recovery** — in-progress work persists across process death:
  persistence is **deliberate** — explicit `checkpoint`, a guaranteed
  dispose-flush on app close, and a stdin-EOF last resort. Nothing flushes
  automatically (no idle/timer), so only human/AI-confirmed state is remembered.
- ✅ **Provenance** — `openstate_why` explains every fact's justification chain.
- ✅ **Compact/prune** — dead records are collected at session boundaries and
  on demand; the store stays bounded.
- ✅ **TUI status strip** — `● openstate / battery ready · backing up` rendered
  in the session sidebar via the `sidebar_content` slot.
- ✅ **6 AI tools** — `state`, `why`, `checkpoint`, `capsule`, `export`,
  `reset` (deliberate full wipe / start over).

## 🔶 In Progress

- (none currently)

## ⬜ Planned

### ⬜ Import old chats → unresolved-work report

**Goal:** surface work that was *started but never resolved* across a repo's
past AI sessions, without contaminating the confirmed fact store.

**Problem it solves:** a fresh session starts knowing nothing. Older sessions
left dangling threads ("I was refactoring X", "we need to fix Y", "TODO: bump
dependency", a failed command that was never retried). The AI has to rediscover
all of it. This feature harvests those threads and hands the AI a triage list.

**Core design — two stores, never mixed:**

| Store | Contents | Trust |
|-------|----------|-------|
| Confirmed (`state.jsonl`) | Facts proven by live extension events, semantically paired | High |
| Suspect (report file, e.g. `suspects-<date>.json`) | Items harvested from old chats, each tagged with source session + confidence signal | Explicitly **unconfirmed** — may or may not have been done |

Suspect items are **never** merged into the confirmed store automatically. The
AI reads the report and triages: promote real ones to `NextAction`/`Blocker`,
discard stale ones, ask about ambiguous ones.

**Unresolved detection** (the same disposal-pair lens, applied to transcripts —
find the things whose *out* event never fired in the recorded session):

- in-progress claims with no completion ("editing X", "working on Y", "started
  on Z") and no recorded finish
- TODO items never marked done
- commands that failed (exit ≠ 0) with no later success for the same task
- tentative commitments: "I need to…", "we should…", "next I'll…"
- blockers raised with no unblock event

**Flow:**

1. `openstate_import_chats <repo>` scans the repo's past sessions, runs the
   message heuristics, writes `suspects-<date>.json`.
2. The AI reads the report and triages into confirmed facts (via existing
   tools) or discards.
3. Nothing touches `state.jsonl` until a human/AI explicitly confirms.

**Source sessions — important distinction:**

- **chat-chronicle** (copilot / cursor / kiro / claude-code) reads flat JSONL —
  easy to scan from files.
- **opencode sessions** are **not** covered by chat-chronicle yet. opencode
  stores its own sessions in a database that requires a **SQL connection** and
  an **explicit export process** (it is not flat-file JSONL). The importer must
  therefore support two ingestion paths: flat-file scan for chat-chronicle
  sources, and a SQL/export-based ingestion for opencode's own history.

**Open questions:**

1. Unresolved signal — implicit pair-detector only, or also an explicit
   "remember this" intent flag captured by a tool?
2. Run timing — explicit tool only, or auto-scan at session start (one-line
   summary: "3 unresolved items from past sessions")?
3. Promotion path — plain confirmed fact, or a tagged
   `recovered-from-history` fact so provenance back to the source chat is kept?

---

## 💡 Proposals (not yet scoped)

- 💡 **Timer-driven flush** — explicitly rejected for now: it would re-introduce
  an automatic flush that isn't tied to a human/AI decision, risking
  auto-persisting unconfirmed state. The deliberate model (checkpoint /
  dispose / EOF) covers the real crash cases; a catastrophic machine kill
  loses only un-confirmed in-memory state, which is the intended tradeoff.
- 💡 **`/openstate` user commands** — surface `checkpoint` / `reset` as
  user-invokable slash commands in addition to the AI tools.
- 💡 **Analytics over `state.jsonl`** — DuckDB queries already work; a small
  `query` subcommand or doc could make "what did we do last week" one-liners.

---

## Governance

- **Lead Maintainer:** Michael A. Kuykendall
- Contributions are welcome via Pull Requests (maintainer-approved only, see CONTRIBUTING.md)
- The roadmap is set by the lead maintainer to preserve project vision
- All changes must align with openstate's core philosophy: per-repo install, semantic fact lifecycle, crash recovery, provenance, invisible infrastructure