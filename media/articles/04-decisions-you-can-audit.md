# Decisions with a trail

Six months after a choice is made, someone asks why. The person who chose is
gone, the chat log is gone, the commit message says "update". The code
remains, and the reason does not. So the choice gets revisited from nothing,
or quietly reversed, and the lesson is paid for twice.

---

## The reason stays with the choice

OpenState records decisions beside the work: what was chosen, what was
rejected, why, and what evidence supported it. A later session asks why and
gets the recorded reason with a pointer to the session where it was made.

The trail matters most when the decision looks wrong in hindsight. Then the
record shows whether the choice was mistaken or the situation changed, and
the next choice starts from that distinction.

---

## Asking is cheap

Checking a reason is a small read. A structural definition read returned
about 1.3 KB, against about 8.6 KB for an average file read.

In one measured case, reading a complete function from a 63 KB file returned
97% less data than reading the file.

---

## What the trail cannot do

A recorded reason is still a claim about the past. It tells the next session
what was believed and why, not whether it is still right. Sources and method:
[measured evidence](../../docs/evidence.md).