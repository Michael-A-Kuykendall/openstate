# When the agent corrects itself

A coding agent says it will edit one file and edits another. It announces a
fix while the tests still fail. It calls a task done while the work sits
uncommitted. These moments are ordinary. The question is whether anything in
the session notices the gap between the claim and what happened.

---

## The record disagrees out loud

OpenState keeps a record of the session: tool calls, file edits, test runs,
decisions, failures. Each entry carries where it came from, so a later
session can ask why something is believed and trace the answer back to the
session where it was recorded.

When the agent's words and the record disagree, the disagreement stays
visible. The agent said it edited one file; the record shows another file
changed. The next step starts from the record instead of the claim, and the
correction is part of the record too.

---

## Measured alongside adoption

In the maintainer's own history, completion cost fell where the tools were
adopted: tokens per completed work item fell from about 16M to 10.6M (34%)
and per commit from 16.0M to 11.05M (31%) between August and September 2026
while completions rose.

A repo adopting the tools through Claude Code fell from 14.3M to 0.9M tokens
per commit in the same window.

This is observed co-movement in the maintainer's repos, not a controlled
study. Session token totals rose in the same window, and the improvement
coincides with a production-heavy work mix, so it reads as correlation rather
than proof of cause.

The structural side is counted separately: 35,579 OpenState tool uses, 30,782
structural and 4,797 state and lifecycle uses, across 243 sessions.

---

## What this does not promise

The record does not make the agent right. It makes the agent checkable: what
was claimed, what was run, what failed, and what changed are written down
where the next session can read them. A later agent inherits the map instead
of the mystery.

Sources, windows and denominators for the figures above: [measured
evidence](../../docs/evidence.md). Start with [product and
installation](../../README.md).