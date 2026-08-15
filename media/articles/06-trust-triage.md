# Article 6: Trust Triage — How openstate Salvaged Six Days of Entangled Work

*by the openstate engine — when git history lies, per-session assessment is the map*

---

## The trap

A branch had been worked for six days across eight sessions by multiple AI models.
One epic bead, 658 auto-commits, 29 real code commits, four mixed workstreams,
and zero merges to `main`. The user's question was simple and hard:

> "What is good and what is bad on this branch — I am not throwing away six days of work."

The obvious answer was to sort the git history. It was the wrong answer.

---

## Why git was the wrong map

On the surface, the branch looked like 29 independent commits you could classify:

```
b67e682  fix(2z6): deterministic Paris gate passes     ← looked clean
b6a788b  fix(q1c): measurement-plane phantom fix       ← looked clean
b05fc10  fix(f41.3): RoPE factor divides theta         ← looked clean
4e8472f  fix(f41): shared-KV + two-pass QK-norm        ← looked clean
```

But the moment we tried to trust the history, it collapsed:

1. **Cherry-picking the "simplest" good commit failed.** `1c03534` (per-chunk
   preflight, one file) conflicted on `main` and broke the build. The good
   commits were built on the branch's *intermediate* state, not on `main` —
   they had no clean parents.
2. **Good and bad shared the same commit.** `b67e682`, praised for its full
   evidence, *also* carried the conformance crate that was supposed to be
   discarded. There was no file-level "good pile" to lift out.
3. **The real structure was a dependency pile, not leaves.** The 2z6 fix was
   four window-rebase commits that everything else sat on top of. You could not
   lift the good work off without taking the foundation and the smears together.

**Git history records *what happened*, not *what was true*.** When a branch is
this entangled, the commits stop being a reliable source of truth.

---

## The openstate alternative: assess the sessions, not the commits

The user pointed at the right tool:

> "Rely on the openstate assessment of the prior sessions rather than the commits."

The move: run `openstate_assess` on every session that touched the branch, then
read the per-session facts. Ten sessions assessed:

```
openstate_assess ses_026fc3141  (v0.3.0 release work)
openstate_assess ses_022b9ad1   (quarantine + 2z6 reopen)
openstate_assess ses_021dafa17  (2z6 bead decomposition)
openstate_assess ses_02106c47   (window-aware bind groups)
openstate_assess ses_01dbb2856  (conformance crate)
openstate_assess ses_0197d9b6b  (2z6 Paris gate + f41 diagnosis)
openstate_assess ses_01832b1fa  (measurement-plane mega-session)
openstate_assess ses_007aed8a1  (PLE implementation)
openstate_assess ses_004bcdf72  (hand-rolling + process correction)
openstate_assess ses_003a7d3ef  (RoPE divide fix)
```

Assessment is **idempotent** — each session absorbed once, re-running adds
nothing, nothing is duplicated. Then `openstate_capsule` and `openstate_report`
give the structured readout: what each session completed, decided, failed, and
blocked, with provenance.

---

## What the assessment actually gave us

The per-session facts did **not** say "this code is correct." They said
*"this claim was recorded with this evidence."* That is trust routing, and it
split the branch cleanly:

| Fix | Recorded evidence in the session facts | Trust verdict |
|-----|---------------------------------------|---------------|
| 2z6 argmax regression | deterministic argmax=12366, RMS 2.333009, ×2 runs, 1B control | **TRUST → reconstruct** |
| q1c measurement phantom | root cause named (batch-1 copy bit-equalized all 42 layers) + fix | **TRUST → reconstruct** |
| RoPE proportional factor | divide-not-multiply, gated to dense-latent, fail-on-buggy proof | **TRUST → reconstruct** |
| PLE four-part structure | each part closed with a named gate | **TRUST → reconstruct** |
| mq7 "RMS fixed by metadata flags" | claim recorded, then *measured false* the next session (RMS still 430K) | **DISTRUST → discard** |
| 2z6 "coherent text" close | narrative only, no gate | **DISTRUST → reopened** |
| 3360ddc "f41/mq7 fix" | compile/lib only, no model gate | **DISTRUST → quarantined** |

The assessment's value: it knew which recorded claims carried real gate evidence
and which were compile-only, narrative-only, or later disproven — *without*
unpicking the tangled commits. That is the distinction.

---

## The distinction, precisely

There are two different jobs and two different tools:

1. **Trust triage — where should confidence go?** This is the openstate job.
   `openstate_assess` + `openstate_report` + `openstate_capsule` record and
   surface *what each session claimed and with what evidence* — the gate
   numbers, the decisions, the failed attempts, the blockers. It routes trust
   to evidence-backed claims and away from vapor.

2. **Correctness — is the code actually right?** This is the compiler and the
   GPU's job, never the state store's. openstate does not lint, compile, or
   verify. In this salvage, correctness came from the real toolchain: `clippy -D
   warnings` failed at a line the session had shipped; a cherry-pick test broke
   the build; `git show` exposed the conformance crate inside a "clean" commit.
   openstate recorded the trust; the toolchain proved (or disproved) the code.

The synergy, stated as a rule:

> **openstate routes the trust; the toolchain proves the code. The assessment
> tells you *which recorded fixes to rebuild*; the build tells you *whether the
> rebuild is right*.**

Never substitute one for the other. A fact with full provenance is still a
claim; a green build is still local to its tests. The two together — assess
first, then verify — are what made six days salvageable.

---

## The recovery pattern, generalized

When a branch is too entangled to trust, the workflow that works:

```
1. openstate_assess every session that touched the branch (idempotent).
2. Read openstate_capsule / openstate_report: what was completed, decided,
   failed, blocked, per session.
3. For each fix the sessions claim: is there gate evidence (a named number,
   a ×2 determinism check, a control model)?  → trust / distrust.
4. Reconstruct the trusted fixes fresh on a clean line — NOT cherry-picked
   (the commits have no clean parents).
5. Verify each reconstruction with the real toolchain (build, tests, model
   gates) before the next.
6. Record the verdict back into a bead / the battery so the next AI inherits
   the map, not the mystery.
```

---

## The payoff

```
Without openstate:
  "Which commits are good?" → unpick 29 entangled commits for a day
  → discover cherry-picks conflict → still don't know what to trust
  → six days of work looks like a total loss

With openstate:
  "Which sessions had gate evidence?" → 10 assessments, one report
  → eight fixes carry real evidence, three claims are vapor
  → six days salvageable as eight reconstructions, each gated
```

The branch was quarantined (tagged as a record, never merged), the trusted
fixes queued as fresh reconstructions on a clean line, and the whole map written
into a bead. The next AI that touches this project inherits the triage — not the
grind.

---

*Trust triage case study: 10 sessions, 8 AI models, 658 auto-commits, 29 real
commits, 4 entangled workstreams across 6 days — salvaged into 8 evidence-backed
reconstructions. Facts and provenance in `.openstate/state.jsonl`, read with
`openstate_capsule`, `openstate_report`, and `openstate_why`. The product being
salvaged is public: [shimmy](https://github.com/Michael-A-Kuykendall/shimmy) —
an open, pure-Rust GPU inference engine.*
