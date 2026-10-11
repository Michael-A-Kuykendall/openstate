# Versioning

OpenState follows [Semantic Versioning](https://semver.org/). Before 1.0, a breaking change raises the minor version (0.1 to 0.2); additions and fixes raise the patch version (0.1.0 to 0.1.1). From 1.0 on, a breaking change raises the major version.

## What is the public interface

These are what an agent, a host configuration or a script can rely on:

- **Tool names and their arguments**, for the OpenCode plugin (36 tools) and the MCP server (34 tools).
- **The keys of the capsule and of the report** (`openstate_capsule`, `openstate_report`), including nested keys.
- **The installer's flags** (`--global`, `--check`, `--uninstall`, `--purge`) and where it puts things (`.opencode/`, `.openstate/`).
- **The `.openstate` layouts** it accepts: a directory, a symlink, or a pointer file.

## What counts as breaking

- Removing or renaming a tool, an argument, a capsule key, a report key or an installer flag.
- Changing what an existing key or argument means, or its type.
- Dropping support for a `.openstate` layout or a platform.

Adding a tool, an optional argument, or a new capsule or report key is not breaking.

## State files

The format of `state.jsonl` is internal and can change in any release. The promise is about your data, not the format: **every later release reads state written by 0.1.0 or any later release**, converting it on load if the format changed. A release never discards or sets aside a state file it is able to read (a damaged file is set aside unchanged; see [TRUST.md](TRUST.md)). Going back to an older release after a newer one has written the state is not supported.

## How changes are recorded

Every release has a [CHANGELOG](../CHANGELOG.md) entry with Added, Changed, Fixed and Removed sections, and a **Breaking** section whenever the minor version (before 1.0) or major version (after) was raised for a breaking change, saying what to change on your side.

## How it is enforced

- A test pins every capsule and report key; adding or removing one fails it until the change is made on purpose and recorded here and in the CHANGELOG.
- A state file written by 0.1.0 is checked in, and every later engine must load it with its facts intact.
- A test pins the 36 OpenCode tools by name and count; the MCP server's 34 are checked from the shipped bundle.
