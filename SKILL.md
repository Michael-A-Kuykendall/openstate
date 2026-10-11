---
name: openstate
description: Use openstate for persistent session memory, project state tracking (objectives, decisions, blockers), provenance queries ("why did we decide X"), and generating resume capsules for context handoff between sessions. Trigger when starting work in this repo, at session end, or when the user asks about project state or past decisions.
---

# openstate

A persistent decision log for this repo (`.openstate/state.jsonl`) — records what is *true, done, failed, blocked, and why*, never file contents. Every read is a deterministic compilation of live facts, never an AI-generated summary.

**Code Mode requirement (call this first):** the `openstate_*` tools are exposed ONLY inside the Code Mode runtime (the `execute` tool) — they are never directly callable, and a direct call fails with 'No tool named X is currently available'. Inside Code Mode, find each tool with `search({ query: ... })` and call it by its catalog path (e.g. `tools.openstate_assess(...)`). Load this skill first, in a running OpenCode session (session ID must already exist).

---

## Tool choice — use openstate first

OpenState tools are the sanctioned surface for this repo. They are bounded (~8 KiB / 24 lines per response, every response carries a `cost` field so the price is visible) and they are what the read/`cat`/`grep` restrictions are built around.

- **Search first, scoped**: `openstate_ast_search` with `scope_path` set to a file or directory — whole-repo queries are the top transcript-bleed cause. `query_kind=text` for prose/markdown, `query_kind=identifier`/`function` for code.
- **Navigate, do not read**: `openstate_symbol_overview`, `openstate_find_declaration`, `openstate_find_implementations`, `openstate_find_referencing_symbols`, `openstate_diagnostics` answer most questions without dumping file contents.
- **Read only when search cannot answer**, and then only the file/range you need — never whole directories, never the whole store.
- **Edit only through preview → apply pairs**: `openstate_edit_text_preview`/`openstate_edit_text_apply` for prose/config, `openstate_edit_symbol_*` for code. One preview, one apply, no re-use of a consumed identity.
- **Price your calls**: the `cost` field on every response is serialized bytes + lines. If a call returns `~6000 B`, the next call should be scoped tighter.
- **Response envelope**: responses are a prose header line (e.g. `✓ tool · …`) plus a JSON payload; preview/apply responses are bare JSON. Check `ok`/`status` before reading `identity`; when parsing, parse after the first newline.
- **Identity naming**: the `identity` a preview returns and the `preview_id` its apply accepts are the same value.
- **Paging**: truncated responses carry a `continuation` cursor; reads that support it (e.g. `read_symbol`) accept the cursor via the `cursor` arg — pass `next_cursor` back unchanged until it is `null`. Verified 2026-10-04: a 35,311-byte symbol read as 6 pages (5×6,192 B + 4,350 B), cursor format `<digest>.<src-digest>.<byte-offset>`.

---

## THE RULE — read this before calling anything

**`openstate_state`, `openstate_capsule`, `openstate_report`, and `openstate_why` compile the ENTIRE current store — every session ever recorded to it, not one session.** The one exception: in the capsule and report, user directives and in-progress work from OTHER sessions are left out, so another session's unfinished task never becomes yours. Decisions, failures and completed work from every session always show. This is the single fact that determines which procedure below you need.

---

## Which procedure do you need?

**A — Continue this session** (default: no specific prior session was named)
1. Read the capsule already in your context (the system part marked `[OPENSTATE-CAPSULE]`, added at the start of the session and after each compaction). Call `openstate_capsule` only if it is missing or you need a fresher one. Avoid `openstate_state`/`openstate_report` unless you need the full fact detail — both compile the whole store and are the single biggest transcript cost.
2. Announce in one line: objective, in_progress count, validation status, git branch.
3. If something looks broken/stuck (per the capsule), run `openstate_report`.

**B — Review or reassess specific named session(s)** (user says "assess session X", "the last N sessions", "what happened before") — do this INSTEAD of A, not in addition:
1. `openstate_reset` — clears the store so the next reads reflect ONLY what you replay. It clears the assess journal too, so replaying re-absorbs full history. It is recoverable only for sessions this host can replay: OpenCode sessions still in this repo's history. Facts from `claude:` sessions rebuild only through the Claude Code MCP server's `openstate_assess`; check `openstate_report_timeline` for the stored sessions before resetting a mixed store.
2. `openstate_assess <session_id>` for each named session, or ONE selector call — `newest-N`, `oldest-N`, `range:A-B`, or a title substring — when you want a span. A selector replays every matched session newest-first; an unresolvable selector refuses with `unknown_selector` rather than absorbing nothing.
3. `openstate_report` / `openstate_capsule` — now reflect only the replayed sessions.
4. `openstate_checkpoint` to persist.

Skipping step 1 in procedure B means step 3 summarizes accumulated history, not the sessions you were asked about — this is the most common failure mode.

Outside of A/B — call `openstate_reset` only when the user explicitly wants to start over, scrub state, or recover from a corrupt store. Confirm intent first in that case.

---

## Tools

### State and lifecycle

| Tool | Reads/writes | Purpose |
|------|------|---------|
| `openstate_state` | whole store | Current objective, decisions, work, failures, blockers, and next actions |
| `openstate_capsule` | whole store | Compact resume contract with frontier views |
| `openstate_report` | whole store | Broken, stuck, or unresolved items plus frontier views |
| `openstate_report_timeline` | whole store | Facts grouped by source session in timestamp order |
| `openstate_why <fact_id>` | whole store | Rule chain for a derived fact; for a base fact, that it is base and which session recorded it |
| `openstate_assess <session_id?>` | writes | Idempotently replay a session into the store |
| `openstate_sessions` | read-only | List sessions available for assessment |
| `openstate_checkpoint` | writes | Atomically flush state to disk |
| `openstate_close` | writes | Close one fact or a session; use `dry_run` first for cascades |
| `openstate_reset` | writes | Deliberately wipe facts and the assessment journal |
| `openstate_doctor` | writes | Auto-fix engine permissions and stale locks, then report health |
| `openstate_restart` | — | Checkpoint and restart the engine sidecar |
| `openstate_export` | read-only | Export the store and capsule to a timestamped JSON file |
| `openstate_toast` | writes | Enable or disable completion toasts |

### Structural navigation and editing

The same 22 structural tools are exposed by the OpenCode plugin and MCP server. Code edits use `openstate_ast_search` first, then preview, then apply. `query_kind=text` provides literal text search for prose and document files, including Markdown, and returns exact spans; text writes still use an exact unique anchor. AST search, symbol navigation, and every symbol preview accept optional `target_directory`; text and create previews accept it too. It is an operation root, not a permission grant: it must be inside the current repository/workspace or an explicitly configured `OPENSTATE_ALLOWED_DIRECTORIES` root, and `scope_path` plus `dest_scope_path` remain relative to it. Applies use only the returned `preview_id` and revalidate the stored root. Omit `target_directory` for normal in-repository work.

Symbol tools take `language` (default `rust`): rust, python, typescript, tsx, javascript, go, c, cpp, java, bash, csharp, kotlin, lua, php, ruby, scala, solidity, swift. `openstate_diagnostics` (cargo) and `openstate_find_implementations` (impl blocks) are Rust only.

| Tool | Purpose |
|------|---------|
| `openstate_diagnostics` | Bounded repository-declared Rust cargo check; returns `success`, `error`, `timeout`, or `unavailable`. `success` = per-file result; `workspace_exit_code` is the whole-workspace cargo exit (the `note` qualifies when they differ) |
| `openstate_ast_search` | Find a definition, identifier, or literal text before editing |
| `openstate_find_referencing_symbols` | Find lexical declarations and references; not type-resolved |
| `openstate_symbol_overview` | List symbols with identity, range, kind, and visibility |
| `openstate_find_declaration` | Find a declaration by name |
| `openstate_find_implementations` | Find Rust impl blocks lexically |
| `openstate_read_symbol` | Return one complete bounded AST definition/body from an exact file, identity-keyed; pages with `cursor` |
| `openstate_read_text_region` | Return a bounded real region around one unique literal anchor (prose/config) |
| `openstate_edit_symbol_preview` | Preview a token rename or whole-definition replacement |
| `openstate_edit_symbol_apply` | Apply the symbol edit preview |
| `openstate_edit_text_preview` | Preview a unique anchor replacement in Markdown, JSONC, TOML, or config; accepts optional `target_directory` beneath configured approved roots |
| `openstate_edit_text_apply` | Apply the text edit preview |
| `openstate_create_file_preview` | Preview creating a new repository-relative file that does not yet exist; accepts optional `target_directory` beneath configured approved roots |
| `openstate_create_file_apply` | Create the file from the preview identity |
| `openstate_move_symbol_preview` | Preview moving a function/type to a destination anchor |
| `openstate_move_symbol_apply` | Apply the move preview |
| `openstate_delete_symbol_preview` | Preview deleting one function/type |
| `openstate_delete_symbol_apply` | Apply the delete preview |
| `openstate_rename_symbol_preview` | Preview renaming identifier tokens |
| `openstate_rename_symbol_apply` | Apply the rename preview |
| `openstate_insert_symbol_preview` | Preview inserting a function snippet before/after an anchor (`target_name` = the anchor function name) |
| `openstate_insert_symbol_apply` | Apply the insertion preview |

### Structural errors and limitations

Refusals are stable and actionable: `no_match`, `missing_preview`, `already_consumed`, `stale_files`, `source_session_mismatch`, `repository_mismatch`, `unauthorized_target`, `invalid_path`, `invalid_snippet`, `unsupported_language`, `ambiguous`, `ast_grep_failed`, and `text_search_failed`. For an approved external root, pass `target_directory` and keep `scope_path` relative to it; the root must be configured by `OPENSTATE_ALLOWED_DIRECTORIES`. Re-search and re-preview after `no_match` or `stale_files`; never reuse a consumed preview. STRUCTURAL READING PROTOCOL — LOCATE, THEN READ:
- openstate_ast_search is a LOCATOR. Its text results include the matched source
  line and bounded context so you can choose one unit; it is not a substitute
  for a body read. Do not issue token-by-token searches to reconstruct a file.
- For code: symbol_overview or find_declaration -> read_symbol(file, symbol,
  language). read_symbol returns one complete bounded AST definition/body from
  that exact file, or a structured refusal. It never returns an unrelated file.
  A body larger than the bounded payload is PAGED, not refused: the response
  carries body, byte_length, byte_offset, and next_cursor. Pass that
  next_cursor back unchanged to read the following page until it is null, then
  concatenate the pages. A cursor refused as stale_source means the file changed
  after the page was issued -- re-read from the first page.
- For prose/config/data: ast_search text -> read_text_region(file, anchor).
  read_text_region returns a bounded real region around one unique literal
  anchor; it does not accept byte offsets.
- One locator plus one reader is the normal path. Edit previews are NEVER read
  probes. If those two calls cannot answer the question, stop and report the
  missing reader capability instead of searching more tokens.

SYMBOL SEARCH VS TEXT SEARCH — READ THIS BEFORE QUERYING A NON-CODE FORMAT:
- query_kind=text is a literal, language-agnostic BYTE search. It works on ANY
  file type, including JSON, YAML, TOML, HTML, CSS, and Markdown — the
  text-fallback formats. Use it for configs, docs, and data files.
- query_kind=function, query_kind=identifier, symbol_overview, find_declaration,
  rename/insert/move/delete symbol are SYMBOL operations. They require ast-grep
  node kinds (function/class/enum declarations). JSON and the other
  text-fallback formats DO NOT HAVE those kinds — JSON has only object/array/
  pair nodes. Symbol operations on these formats were NEVER going to work and
  refuse with unsupported_operation, never unsupported_language.
- If you need to edit JSON/YAML/HTML/CSS/Markdown, use edit_text with a unique
  anchor + replacement. That works on every file type.
- Unregistered language NAMES still refuse with unsupported_language.

Structural symbol navigation and editing are lexical and limited to registered languages; `query_kind=text` is language-agnostic literal search for document and prose files. No type resolution or scope-aware rename is performed. Diagnostics never edits files and is bounded to 30 seconds.

Text-edit refusals carry evidence: `ambiguous_anchor` lists every match `offset` with `line`, `line_ending` (`lf`/`crlf`), and bounded `context`; `no_match` returns the nearest candidate — including a line-ending diagnosis when an LF anchor misses inside a CRLF file. `line_endings: "normalize"` matches an LF-written anchor inside a CRLF file without rewriting the file's endings (apply reports `line_endings_applied`). Applies preserve the target's mode bits. Under enforce, `read_guard` denies the builtin `read` tool and read-probe tools (grep/rg/od/xxd/hexdump/strings/git grep, cat/head/tail/less/more/wc) on any existing file path — repo and external alike (openstate-8wy). Cross-repo access goes through OpenCode's approval prompts, not an openstate bypass. Pipes, process inspection, pathless probes, glob, and other openstate navigation tools stay available. The enforce boundary (mirroring AGENTS.md): direct edit/write/grep and shell file-mutation commands (sed/tee/dd/perl/cat/printf/echo/touch/install/awk/ruby) are denied, as are inline and stdin eval one-liners (python3 -c / python3 - / python -c / python - / node -e / node - / bun - / bash -c / sh -c / zsh -c). Build/test verbs that generate project files on purpose (cargo, git, npm, node script.js, python3 script.py, python3 -m, cp, mv, rm) stay allowed.

## The three frontier views — the resume answer

`openstate_report` and `openstate_capsule` both lead with these, compiled from live facts:

`current_task` and the first `user_priorities` entry use one ordering: highest score, then latest timestamp, then the most recently recorded directive. Report and capsule compute the cursor the same way and return identical output for an unchanged store.

Fact counts differ on purpose and add up: `openstate_doctor` reports `live_facts` (every fact in the store) and `closed_audit` (close bookkeeping records); `openstate_state` reports `total` = `live_facts` - `closed_audit`; `openstate_report` reports `total_live` (facts it shows) and `scoped_out` (other sessions' directives and in-progress work it leaves out), with `total_live` + `scoped_out` = state `total`.

The capsule is an orientation surface: its non-directive content is capped at 1,500 serialized bytes, retaining the newest selected objective and decision as bounded entries. User directives are never shortened; the report and timeline remain the pulled diagnostic surfaces for complete detail.

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
    "command": "cargo test", "result": "passed",
    "current_generation": 47, "validated_generation": 44,
    "status": "stale", "edits_since_validation": 3
  },
  "change_frontier": {
    "modified": ["src/rules.rs"], "added": [], "deleted": [], "uncommitted": true
  }
}
```

**Act on `validation.status` first** — it answers "code or verify first?":
- `current` → last check passed after the most recent edit. Continue coding.
- `stale` → edits happened since the last green run. Run the validation command before continuing.
- `failed` → diagnose first; `openstate_report`'s failed attempt has the stderr signature.
- `never` → no check recorded. Run the project's test command to establish a baseline.
- The generation counter bumps on every edit (yours, another agent's, or external) — an implicit exit-0 from missing metadata never counts as a pass.

`change_frontier` is refreshed from `git status --porcelain` on every capsule/report — never stale.

---

## Checkpoint discipline

State is never auto-flushed by idle or compaction. Call `openstate_checkpoint` when: the user confirms something is done, a decision is locked in, a blocker is recorded, or you're about to hand off. When OpenCode closes, or exits and ends the engine's input, the engine writes state as a last resort — but don't rely on that; checkpoint explicitly.

---

## Structural-tools enforcement profile

The installer supports an opt-in edit-path profile that prefers the
`openstate_ast_search` / `openstate_rename_symbol_*` / `openstate_insert_symbol_*`
structural tools over direct edits:

- `OPENSTATE_STRUCTURAL_TOOLS=off` (default): no permission changes.
- `OPENSTATE_STRUCTURAL_TOOLS=shadow`: records which tools get selected
  (`structural.tool.selected` facts) without ever blocking anything.
- `OPENSTATE_STRUCTURAL_TOOLS=enforce`: denies direct `edit`, builtin `grep`,
  and the builtin `read` tool (all file paths — repo and external), forcing
  edits and reads through the structural tools. Cross-repo access is handled
  by OpenCode's own approval prompts. glob and build/test commands stay
  allowed.

Config changes REQUIRE an OpenCode restart to take effect — the profile's
`restart_required` flag is set and the installer prints the reminder. To
escape (e.g. ast-grep is unavailable), re-run the installer with
`OPENSTATE_STRUCTURAL_TOOLS=off`; `./install.sh --check` fails on drift
between the mode marker and the actual config.

---

## Engine unavailable

1. `openstate_doctor` first — auto-fixes lost `+x` and stale locks, reports what's actually wrong.
2. Still down → `openstate_restart` (checkpoint + kill + respawn, no OpenCode restart).
3. Still gone → restart OpenCode, or re-run `./install.sh` (it stops any prior engine before deploying).
4. A single "unavailable" on checkpoint usually self-heals via retry — don't reset on a transient error.

---

## Reading signals correctly

- A message with a reasoning marker ("because", "since", "so that", "in order to", "due to") becomes a decision, carrying its reasoning clause (up to 280 characters). Other user messages become directives; the rest become objectives.
