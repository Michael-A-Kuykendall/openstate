# Assess first, then verify

A branch ran for days across sessions and models. The history held dozens of
commits on tangled workstreams, and the question was which work to trust.
Sorting the commits did not answer it: good and bad shared commits, clean
commits rested on discarded ground, and cherry-picks broke the build. The
history recorded what happened, not what was true.

---

## Read the sessions, not the commits

The way through was the session record. Each session that touched the branch
had left facts: what it completed, what it decided, what it tried and failed,
what blocked it. Read together, the facts routed trust: some recorded fixes
carried gate evidence from the sessions that made them, while other claims
rested on compilation alone, on narrative alone, or were later measured false.

---

## The rule

The assessment routes trust; the toolchain proves code. The record says which
recorded fixes to rebuild; the build says whether the rebuild is right. One
without the other misleads: provenance without a build is an untested claim,
and a green build without provenance is confidence without a source.

---

## The pattern, kept

Reconstruct the trusted fixes fresh on a clean line, check each with the
real toolchain before the next, and write the verdict back into the record so
the next session inherits the map. When the branch itself cannot be trusted,
it stays quarantined as a record and the branch is left unmerged.

---

## What this does not claim

This is one salvage, told for its method. Sources and method: [measured
evidence](../../docs/evidence.md).
