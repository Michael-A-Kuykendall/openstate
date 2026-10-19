# Starting again after a kill

Processes die. Power fails, laptops shut, the OOM killer picks a victim, a
session ends mid-edit. The work that survives is the work that reached the
disk before the end. OpenState draws that line in the open: confirmed state
is written down, unconfirmed state is not, and the next session reads what
was written, nothing else.

---

## What reaching the disk means

A checkpoint writes the current state out. A clean shutdown flushes first and
then stops. When the end is abrupt, the engine takes the last path left: the
closing input stream trips an emergency write. Each path ends with the bytes
on the disk, so a fresh session starts from something real rather than from a
guess about what the dead session meant.

---

## What comes back

The next session opens with a resume note: the current task, the files in
motion, the last check and whether it passed, what changed and what is still
open. The agent reads it instead of re-reading the transcript, and continues
from the noted place instead of reconstructing it from memory.

---

## Measured steadiness

A separate legacy corpus of 21,372 OpenState tool calls holds 19 calls whose
tool status is error: 0.09%. That is an invocation-level status count, not a
claim about refusals returned inside successful results.

The tools run locally, without telemetry.

---

## Recovery without drama

Recovery here is not magic. It is the ordinary consequence of writing state
down while it is known and reading it back at the start. Sources and method:
[measured evidence](../../docs/evidence.md).