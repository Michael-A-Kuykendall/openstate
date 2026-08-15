---
name: openstate
description: Use openstate for persistent session memory, project state tracking (objectives, decisions, blockers), provenance queries ("why did we decide X"), and generating resume capsules for context handoff between sessions. Trigger when starting work in this repo, at session end, or when the user asks about project state or past decisions.
---

# openstate

openstate is a persistent session-state engine for this repo. It records tool calls, file edits, decisions, and project state so the AI can resume coherently across models, compactions, crashes, and sessions. State lives in `.openstate/state.jsonl` (per-project); the engine runs as a sidecar spawned by the plugin in `.opencode/plugins/`.

openstate is a **decision log, not an edit log** — it records what is *true, done, failed, blocked, and why*, never exact file contents. It is deterministic: every read is a compilation of live facts, never AI-generated summary.

---

## ⚠️ CRITICAL: Load this skill BEFORE using any openstate tools

**This skill MUST be loaded first.** You CANNOT use `openstate_state`, `openstate_assess`, or any other openstate tool until:

1. **An OpenCode session has started** — the session ID is assigned by OpenCode at startup. You can see it via `openstate_sessions` or it appears in session metadata. There is NO session before OpenCode spawns you.
2. **This skill is loaded via the `skill openstate` tool** — loading the skill is what makes the openstate tool family available in your tool surface. If the tools aren't in your tool list, the skill is NOT loaded.

**Common mistake:** Trying to call `openstate_assess` or `openstate_state` in a brand-new session before loading this skill. The tools will fail or produce empty/confused results because there is no session context yet. The OpenCode session ID is generated when OpenCode starts; the openstate tools then track facts *for that session ID*. If you skip loading the skill, you're working without the battery.

**Fix:** Run `skill openstate` FIRST (this loads the tool family), THEN follow the Session Start ritual below.

---

## Session Start — the mandatory 3-step ritual

**Prerequisites:** (a) this skill is loaded via `skill openstate`, and (b) an OpenCode session is running (session ID exists). If either is missing, the ritual below will fail.

Do ALL of these steps immediately when a session starts, before touching user code:

1. `openstate_state` — recover the objective, decisions, in-progress work, blockers.
2. `openstate_capsule` — get the compact resume contract (frontier views lead it).
3. Announce to the user in **one line** that the battery loaded, summarizing the capsule (objective, in_progress count, validation status, git branch). Example:

   > openstate loaded · objective: build X · validation stale (2 edits since green) · branch: main

If anything looks broken/stuck, ALSO call `openstate_report` before diving in — it is the black-box "what is broken right now" readout.

**Never skip the announcement.** It is the user's only visual confirmation the battery is active.

---

## Available Tools (13)

| Tool | Purpose |
|------|---------|
| `openstate_state` | Full project state: objective, decisions (with reasoning), completed/in-progress work, failed attempts, blockers, next actions |
| `openstate_capsule` | **Resume contract** — compact JSON for a new session. Leads with the three frontier views (below) |
| `openstate_report` | **Black-box readout** — what is broken/stuck/unresolved right now, plus the frontier views on top. The first thing a fresh AI runs after assess |
| `openstate_report_timeline` | **Chronological mode** — facts grouped by source_session, sorted by timestamp. Use for "what happened in what order across sessions" |
| `openstate_why <fact_id>` | Provenance chain: which rules produced a fact, what premises support it, and whether it reaches the original user message (`↳ source:`) |
| `openstate_checkpoint` | Force-flush state to disk immediately (atomic write). The ONLY mid-session flush — persistence is deliberate |
| `openstate_close <fact_id \| session_id> <reason>` | Mark a false positive / resolved item live=false with an audit reason. Cascades to dependents. Idempotent |
| `openstate_assess <session_id?>` | Replay a session's full event history into the battery. Omit id = current session; pass id = recover a PRIOR session. Idempotent (journaled) |
| `openstate_sessions` | List recent opencode session ids + titles to pick one for assess |
| `openstate_doctor` | **Health check + AUTO-FIX**: restores the engine binary's execute permission (lost +x breaks the sidecar) and removes stale `.openstate` lock files (PID-liveness checked — a live engine's lock is never touched), then reports PID/uptime, live vs total facts, state path, journal health, last checkpoint. Run FIRST on "engine unavailable" |
| `openstate_restart` | Checkpoint + kill + respawn the engine sidecar. Engine recovery WITHOUT an OpenCode restart |
| `openstate_toast <enabled>` | Toggle the completion toasts ON/OFF (persisted per-project in `.openstate/toasts.json`, default ON). Toasts are transient; the sidebar ticker shows live status either way. |
| `openstate_export` | Dump the full state store as a timestamped JSON file (on-demand only) |
| `openstate_reset` | **Irreversible** full wipe of facts AND the assess journal. Only for starting over / privacy scrub / confused-state recovery |

> **Note:** These tools only appear in your tool list after you run `skill openstate`. If you don't see them, the skill is not loaded — load it first.

---

## The three frontier views (openstate-frontier) — the resume answer

Both `openstate_report` and `openstate_capsule` lead with three deterministic views that answer the five resume questions — **where am I, what was being changed, what remains unresolved, has the code been validated, what should I do first**. They are compiled from live facts, never AI-generated:

```json
{
  "resume_cursor": {
    "current_task": "highest-priority user directive (else newest objective)",
    "active_files": ["top edited files"],
    "last_meaningful_action": "cargo test failed",
    "blocking_reason": "highest-priority blocker, if any",
    "next_action": "highest live next action, if any"
  },
  "validation": {
    "command": "cargo test",
    "result": "passed",
    "current_generation": 47,
    "validated_generation": 44,
    "status": "stale",
    "edits_since_validation": 3
  },
  "change_frontier": {
    "modified": ["src/rules.rs"],
    "added": [],
    "deleted": [],
    "uncommitted": true
  }
}
```

### How to ACT on each view

- **`validation.status` is the "code or verify first?" answer.** Decide your FIRST move from it:
  - `current` → a test/check/build passed after the most recent edit. Safe to continue coding.
  - `stale` → edits happened since the last green run. **Run the validation command before continuing** — the last green does not cover the new code.
  - `failed` → the last check failed. Diagnose the failure FIRST; `openstate_report` shows the failing attempt + stderr signature.
  - `never` → no check has been recorded. Run the project's test command to establish a baseline.
  - The generation counter bumps on every `file.edited` AND `file.watcher.updated` — so external edits, manual changes, and work by another agent all invalidate green. A check counts as green ONLY when the exit code was explicit; an implicit 0 from missing metadata never counts as a pass.
- **`change_frontier.uncommitted`** is refreshed from `git status --porcelain` right before each capsule/report is generated — never stale. Use `modified`/`added`/`deleted` to know exactly which files to read first and what to commit.
- **`resume_cursor.current_task`** is the highest-scored live user directive (or newest objective) — this is what the user actually wants. Read it before `openstate_state` so you orient on intent, not just facts.

---

## The recovery loop (after a restart or in a fresh session)

**Before this loop:** load this skill via `skill openstate` so the tool family is available. The tools below do NOT exist until the skill is loaded.

1. **`openstate_sessions`** — list prior sessions (if you need history the current session can't see).
2. **`openstate_assess <prior_session_id>`** — replay that session's message text and tool calls into the battery. Omit the id to assess the current session. Idempotent: every part is journaled in `.openstate/imported-parts.jsonl`, so re-running absorbs nothing new. Guarded: a session from a DIFFERENT project is refused unless you pass `confirm=true`; a stale journal on an empty store is refused until `openstate_reset`.
3. **`openstate_report`** — read what is broken/stuck/unresolved right now (the frontier views + black-box sections).
4. **`openstate_close`** the noise — bulk-close a whole session's low-value facts with `session_id`, or close individual false positives with `fact_id`. This stops the battery from re-flagging resolved stalls.
5. **`openstate_why`** on any decision you need to reconstruct — the chain reaches the original user message.
6. **`openstate_checkpoint`** — persist the recovered + cleaned state.

That loop gives you the "why" and the "what is true". For exact edit reconstruction (whitespace, diffs), pair with external snapshots (`git stash` / `serena_read_file`) — that is an external workflow, not an openstate feature.

---

## Best practices — when to call what

**During work**, checkpoint whenever:
- the user marks something done,
- a decision is locked in,
- a blocker is identified,
- you're about to end the session or hand off.

**Cleanup**: when a recorded fact turns out to be a false positive or a resolved stall, call `openstate_close` so it stops coloring the battery. Prefer per-fact close for a single false-positive `code_issue`; use `session_id` to bulk-close whole-session noise (e.g. an entire trial session that produced nothing useful).

**Why questions**: "why did we do X" / "how did we decide Y" → `openstate_why <fact_id>`. The chain shows rules + premises, and `↳ source:` surfaces the original user message that seeded the fact.

**Timeline questions**: "what happened in what order" / "what did the prior session actually do" → `openstate_report_timeline` (session→facts map, timestamp-sorted). AI-native: sort/process it yourself; don't expect prose.

**Export**: when the user wants a dump of all learned state → `openstate_export`. It is ON-DEMAND only — there is no auto-export on idle or event count.

---

## Tool-failure & anti-pattern audit (the "why is my process slow" check)

When asked to audit tool failures / bespoke-Python usage, do it ENTIRELY through openstate:

1. `openstate_assess` the current session AND the prior session(s).
2. `openstate_report` → read `failed_attempts` + `recurring_failures`. These ARE the
   tool-failure list. `recurring_failures.signature` groups them by root cause so you
   don't re-infer.
3. `openstate_state` (or `report_timeline`) → scan the `tool.execute.after` /
   `command_result` propositions for inline `python3 -c` and `rg`/`sed` calls used to
   READ files — those are the bespoke-parsing anti-pattern.
4. Report the failures + the pattern; assign blame to app vs model honestly.
5. `openstate_checkpoint` to persist.

**Do NOT** open `.openstate/state.jsonl` or the opencode tool-output files directly, and
**do NOT** run bash/python to grep them. The tools above already compile this data.

---

## Interpreting the black-box signals — do NOT misread the battery

- A `recurring_failure` like "oldString not found" is the feature **working** — it aggregated repeated failures by root cause so you can see *the pattern that stalls reconstruction*. It is not a bug report.
- `openstate_report` shows **state + failure patterns**, not a transcript. Read it for "what is broken/stuck/unresolved," not "what exactly happened."
- `openstate_why <fact_id>` gives the provenance chain for *decisions* — reconstruct the *why*, not the *how*.
- **Git diff reference**: during assessment, `git.diff` events capture `git diff --stat` (files changed, lines ±, commit hashes) — NOT the full diff. Use the commit hashes to serve full diffs on demand.
- **Selective narrative capture**: Decision/Objective facts store full message text (capped 500 chars) ONLY when reasoning markers are present ("because", "since", "so that", "in order to", "due to"). No blanket storage — assistant chatter without reasoning is skipped.
- **User directives are never filtered** by the low-signal guard — only assistant chatter is. `user_priorities` in the capsule surfaces what the user actually asked for, highest score first.

---

## Feedback surfaces — sidebar ticker + completion toasts

Two complementary, human-visible surfaces report openstate activity (both driven by `message.part.updated` ToolPart transitions — this is the ONLY correct event path; the old `session.next.tool.*` names never fire):

- **Right sidebar** (`● openstate / battery ready`): live status. While an `openstate_*` command runs, "battery ready" swaps to `<command>: …` and the green dot animates (pulses glyph + color). It settles back after each command. Always on — this is the silent, always-available surface.
- **Completion toast**: a transient TUI notification confirming what finished — e.g. `✓ doctor · engine OK · 7796 facts` (takes the tool's own first output line, ~6s, coalesced into ONE toast for back-to-back bursts). This is the glanceable "what just happened" surface.

**To turn toasts off:** call `openstate_toast` with `enabled: false` (an AI-driven toggle — just ask your agent "turn off the openstate toasts"). Persisted per-project in `.openstate/toasts.json`; default ON. The sidebar ticker keeps working regardless. The user does NOT need a command-palette toggle — it is a tool the agent calls on request.

If toasts seem missing: (a) check `.openstate/toasts.json` doesn't say `{"enabled": false}`, (b) confirm the TUI plugin is registered in `.opencode/tui.json`. Tool *return text* is visible only when the user enables generic tool output in the TUI — it feeds the model regardless.

---

## Engine unavailable / recovery

1. Run `openstate_doctor` FIRST — it AUTO-FIXES the two common local failure modes (engine binary lost its `+x`; stale `.openstate` lock files from dead engines), then reports whether the engine is down, starved (busy draining its pipe), or healthy but idle.
2. If the engine is **down**: run `openstate_restart` — it checkpoints state, kills the sidecar, and respawns fresh. **No OpenCode restart needed.** After doctor cleared stale locks, the restart respawns the engine onto the **primary** `state.jsonl` — a stale lock otherwise silently degrades the engine to a pid-suffixed copy (`state.jsonl.<pid>`), drifting your battery away from the primary state.
3. If the engine is **truly gone** (restart doesn't help): restart OpenCode to respawn the sidecar, or re-run `./install.sh` — it stops any prior engine process before deploying, so a reinstall never leaves a stale engine holding the state lock.
4. Checkpoint retries automatically on transient stalls — a single "unavailable" is usually self-healing. Do not panic; do not reset on a transient error.
5. **Known drift**: if repo paths changed mounts (e.g. `/mnt/c/...` → `/home/...`), old `in_progress` "editing X" facts may never get their paired close event — close them per-fact with `openstate_close <fact_id>` so they stop coloring the report.

---

## Session end / compaction / persistence rules

- State is **NOT** auto-flushed by idle or compaction — persistence is deliberate.
- `openstate_checkpoint` is the only mid-session flush. Call it when the user confirms the current state is correct (work done, decision locked, blocker recorded).
- On app close, openstate flushes automatically (dispose). If OpenCode crashes, the engine's stdin closing triggers a last-resort flush — so in-flight work survives even a hard kill.
- Compaction is EXPLICIT-ONLY (via the engine's `compact` command) and is never triggered by `session.idle` — compaction renumbers fact IDs, which would break previously-returned `openstate_why` IDs.

---

## Reset — the only irreversible action

Only call `openstate_reset` when the user EXPLICITLY wants to:
- start over from scratch,
- scrub state before sharing the machine,
- recover from a confused/corrupt store.

**Confirm intent before calling.** If it was accidental, don't panic: reset also clears the assess journal, so an immediate `openstate_assess` re-absorbs the session's history from scratch — it is recoverable, not permanent loss. After any reset → assess → checkpoint to re-establish the battery.

---

## State file

State lives in `.openstate/state.jsonl` — per-project, never shared across repos. The engine is a sidecar process started by the openstate plugin in `.opencode/plugins/`. Query the raw file directly only as a last resort — the tools above are the supported surface.
