---
layout: default
title: Structural tools
description: How OpenState's code tools read, search and edit a repository by definition instead of by whole file, and what that has been measured to save so far.
---

# Structural tools: read, search and edit code by definition

OpenState ships 22 code tools beside its state tools. They let a coding agent find a definition, read just that definition, and change it through a preview it can check before anything is written. They are built on [ast-grep](https://ast-grep.github.io/), which the installer bundles, so the agent needs no setup and you need no editor running.

They come with every install: native OpenCode exposes them through Code Mode; standard MCP clients call the bundled server directly. Both transports expose 36 operations: 22 structural tools and 14 state/lifecycle tools. Session recovery uses shared source adapters, independent of the calling host. Automatic event capture and capsule injection are native OpenCode capabilities; MCP reads and assessments are on demand. Supported OpenCode, Claude and legacy Codex histories can be replayed; current paginated/compressed Codex history returns `unsupported_history`.

## Why an agent needs them

A coding agent with only a file reader and a text editor works in whole files. To change one function it reads the file, often more than once as line numbers move, and then rewrites text it matched by eye. Most of what it read was never needed, and a wrong match can damage code silently.

The structural tools work in units of code instead:

- **Read one definition, not one file.** `openstate_read_symbol` returns one complete function, type or method, and nothing else in the file.
- **Search returns locations, not file dumps.** `openstate_ast_search` finds definitions, identifiers or literal text and returns each match with its file and line, so the agent can read exactly what it needs next.
- **Every write is previewed first.** Each edit has a preview step that returns what will change and an identity; the apply step writes only that change, once, and refuses if the file changed in a way that would make the preview wrong.

## What it has saved so far

Early results from the maintainer's projects, with the completion-cost measurement (method in release evidence):

- In one measured case, reading a complete function from a 63 KB file returned 97% less data than reading the file.
- In the maintainer's sessions, a definition read returned about 1.3 KB, against an average of about 8.6 KB for an ordinary file read.

These are bytes returned per read, not a measured saving on your token bill: the size of a definition against the size of its file varies with the code, and a careful agent can also read a range of lines. Edits are not cheaper in calls (see the weaknesses below); their value is safety.

## The tools

### Find and read

| Tool | What it returns |
|---|---|
| `openstate_ast_search` | Matches for a definition, an identifier, or literal text (`query_kind=text`), each with file and line. The starting point for every read and edit. |
| `openstate_read_symbol` | One complete definition (function, method, type) from one file. |
| `openstate_read_text_region` | A bounded region around a unique piece of text, for prose, configuration and formats without symbol support. Cuts an oversized window down to fit and lists every match when the text is not unique. |
| `openstate_symbol_overview` | The symbols in a file or directory: name, kind, visibility and location. |
| `openstate_find_declaration` | Where a name is declared. |
| `openstate_find_referencing_symbols` | Declarations and references of a name across the repository. |
| `openstate_find_implementations` | Rust `impl` blocks for a type or trait. |
| `openstate_diagnostics` | The repository's Rust `cargo check` result for one file. |

### Change, each as a preview and an apply

| Pair | What it changes |
|---|---|
| `openstate_edit_symbol_preview` / `_apply` | Replaces a whole definition, or renames it. |
| `openstate_insert_symbol_preview` / `_apply` | Inserts a new definition before or after an existing one. |
| `openstate_delete_symbol_preview` / `_apply` | Deletes a definition by its syntax-tree boundary. |
| `openstate_move_symbol_preview` / `_apply` | Moves a definition to another place or file. |
| `openstate_rename_symbol_preview` / `_apply` | Renames an identifier across its matches. |
| `openstate_edit_text_preview` / `_apply` | Replaces a unique piece of text in any text file. |
| `openstate_create_file_preview` / `_apply` | Creates a file that does not exist yet. |

## How the agent uses them

1. **Find.** `openstate_ast_search` for the name or text.
2. **Read.** `openstate_read_symbol` for a definition, or `openstate_read_text_region` for prose and configuration.
3. **Preview.** The matching `_preview` tool. It returns the planned change and an identity.
4. **Apply.** The matching `_apply` tool with that identity as `preview_id`.

The skill and the MCP server's instructions tell the agent this order. They do not take the agent's own read and edit tools away. In OpenCode you can: installing with `OPENSTATE_STRUCTURAL_TOOLS=enforce` denies the built-in read, grep and edit tools, so every read and edit goes through the structural tools, and `OPENSTATE_STRUCTURAL_TOOLS=shadow` only records which tools the agent picks. `OPENSTATE_STRUCTURAL_TOOLS=off` restores the previous configuration.

## What the write path guarantees

- **Nothing is written by a preview.** Only an apply writes, and only the change its preview showed.
- **Each preview applies once.** A second apply of the same identity is refused as `already_consumed`.
- **A stale preview is refused, not forced.** If the file changed so that the previewed change no longer fits, the apply is refused as `stale_files`. If the file changed elsewhere and the anchor text is still unique, a text edit applies and says it was rebased.
- **An ambiguous target is refused.** When text matches more than once, the refusal lists every match so the agent can choose one.
- **A replacement must be one definition.** A symbol replacement that does not parse as a single definition of the right kind is refused before anything is written, with the reason.
- **TypeScript and JavaScript exports stay intact.** Replacing an exported function keeps its `export` keyword, and deleting one removes the keyword with it.

## Languages

Symbol tools (read, overview, declaration, references, edit, insert, delete, move) work in 18 languages: Rust, Python, TypeScript (including TSX), JavaScript, Go, C, C++, Java, C#, Bash, Haskell, Kotlin, Lua, PHP, Ruby, Scala, Solidity and Swift. Text search, text regions and text edits work in any text file. `openstate_find_implementations` and `openstate_diagnostics` are Rust only.

## Known weaknesses

- **A small edit costs more calls.** Search, preview and apply are three calls where a direct editor uses one. For a one-line change inside a long function, a text edit is cheaper than replacing the whole definition.
- **Searches are the heaviest read.** A search with many matches can return several kilobytes; narrow it with a language, a path or an exact name.
- **Matching is by syntax, not by type.** References and renames match names in the syntax tree; they do not resolve types the way a compiler or language server does.
- **Completion cost fell with adoption (measured).** The figures above are bytes per read in the maintainer's sessions. Measured in the maintainer's OpenCode history (2026-06 to 2026-09), tokens per completed work item in the openstate repo fell from about 16M to 10.6M (34%) and per commit from 16.0M to 11.05M (31%) between August and September 2026 while completions rose; an adopting repo fell from 14.3M to 0.9M tokens per commit via the Claude Code MCP, while repos with no adoption were flat or worse except one that improved in a lighter work phase. Method and per-repo/month tables are in `docs/evidence/…` on the private side; these are observed co-movements in the maintainer's projects, not a controlled study.
