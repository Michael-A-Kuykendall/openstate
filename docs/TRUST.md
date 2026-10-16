# What happens when things go wrong

What OpenState does with your project state, what survives a crash, and how to remove it. Every behavior below is checked by a test in the release exam.

## Where state lives

One directory per repository: `.openstate/` at the repository root (or wherever a symlink or a pointer file there sends it; a pointer file's first line is the path, relative to the repository if it is not absolute). The engine stores project facts locally and sends no runtime telemetry. Host history discovery may contact the configured OpenCode API through its SDK; this is separate from engine storage. An API configured on another machine is not an offline history source.

## When state is written

State is written when the agent calls `openstate_checkpoint`, when OpenCode closes (it ends its plugins with a termination signal, and the engine saves before it exits), and when the engine's input ends. There is no timed background write. On Windows a forced end cannot be caught, so there state is saved by checkpoints and by a clean close of the plugin. Each write goes to a temporary file that is flushed to disk and then renamed over `state.jsonl`, so the file on disk is always either the previous complete state or the new complete state.

**What survives a hard kill:** everything the last write saved. Work recorded after that write and before the kill is lost. If you want something kept now, ask the agent to checkpoint.

## Failure modes

| What happens | What OpenState does |
|---|---|
| OpenCode exits, or the engine gets SIGTERM, SIGINT or SIGHUP (Linux, macOS) | The engine saves what it has, releases its lock and exits. |
| The engine is killed hard (`kill -9`, power loss) | The last written state loads on the next start; events after it are lost. |
| A write is interrupted halfway | The leftover `state.jsonl.tmp` is ignored; the last complete `state.jsonl` loads, and the next write replaces the temporary file. |
| `state.jsonl` is damaged and cannot be read | The engine moves it to `state.jsonl.corrupt-<time>` unchanged, says so, and starts with empty state. It never writes over the damaged file. If it cannot move the file aside, it refuses to start. |
| Two engines open the same repository | The second one reads the state but runs in memory and refuses to write, with a message naming the first engine's process; the first engine's state is untouched. |
| The state directory is not writable | The engine reports that it cannot create its lock file there and runs in memory; nothing is written. |
| The disk is full | The write fails with "No space left on device"; the previous `state.jsonl` stays intact, no partial temporary file or lock file is left behind, and writing works again once space is freed. |

## Checking it yourself

- **Check the engine separately from the host.** On Linux, trace `openstate-engine` with `strace -f -e trace=network` or use a firewall log while exercising it. Host discovery and configured API traffic belong to the adapter; a trace of OpenCode as a whole does not isolate engine behavior. The plugin and installer are readable JavaScript and bash.
- **Not in git.** `.openstate/` contains a `.gitignore` of `*`; `git status` never lists it.
- **What it stored.** `openstate_export` writes everything to a JSON file you can read.

## Removing it

- `./install.sh --uninstall` removes OpenState from the repository (plugin, skill, engine, ast-grep, MCP server, profile, and its block in `AGENTS.md`) and **keeps** `.openstate/`, so reinstalling picks up where you left off.
- `./install.sh --purge` does the same and also deletes `.openstate/`. When `.openstate` is a symlink or pointer file, it deletes the directory it names, but only if that directory holds `state.jsonl` or is empty.
- `openstate_reset` clears the recorded state without uninstalling.

## Reporting a security problem

See [SECURITY.md](../SECURITY.md): GitHub Security Advisories on this repository, or email michaelallenkuykendall@gmail.com.
