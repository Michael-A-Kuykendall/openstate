# openstate — GitHub Pages Content Blueprint
# Drop into docs/ or gh-pages. Use the existing logo + generated charts.
# Theme suggestion: dark, high-contrast, single accent color (#2E86AB or similar).

## 1. Hero
- Logo (assets/openstate-logo.jpg) centered, large
- One-liner: **A continuously maintained, retractable project-state model for coding agents in OpenCode.**
- Sub: Local • Private • Licensed • OpenCode extension
- Big metric pills (row of 4–6):
  - 60,732 facts
  - 30,007 self-corrections
  - 14 crashes → 0 work lost
  - 30 capsules
  - <30 s context recovery
- Primary CTA: `curl -fsSL https://raw.githubusercontent.com/Michael-A-Kuykendall/openstate/main/install.sh | bash`
- Secondary: View on GitHub / Sponsor

## 2. The Problem (short, visceral)
Standard AI coding session:
600k tokens → compact / end → summarize → hope the important parts survived.

Symptoms everyone knows:
- Re-running commands that already failed
- Re-reading the same files
- Re-trying rejected approaches
- Losing mid-edit state on crash
- New session starts with a smoothie of guesswork

## 3. The Solution
Events (messages, tool calls, file edits, todos, git, …) flow continuously into a local engine.
The engine maintains **current project truth** — not a transcript.
Next session receives a 1,000–5,000-token **resume capsule** (structured continuation contract) instead of a lossy summary.

Key properties (black-box level):
- Continuously derived facts with automatic retraction
- Full provenance (`openstate_why`)
- Deliberate, crash-safe persistence
- Per-repo, zero-config, local-only

## 4. Proof (the numbers)
Embed the five charts + the core metrics table from media/README.md.
Highlight:
- Self-correction as truth-convergence velocity
- Zero work lost across 14 real hard crashes
- Token savings (~20M tokens across the measured sessions)
- Time savings estimates (methodology stated beside every figure)

Link to the full media kit and sanitized logs.

## 5. How it works (obfuscated, high-level)
Three layers:
1. OpenCode Observer Plugin — captures the live event stream
2. Local Rust State Engine — turns observations into live, retractable project facts with provenance
3. Resume Capsule — structured continuation contract injected automatically

36 AI tools the agent can call directly: 14 state tools (list the table from README) and 22 structural tools.
No human dashboard required. The battery is for the AI; humans ask the AI.

## 6. Install (30 seconds)
Exact one-liner + verification command.
Emphasize: per-repo only, no global install, prebuilt binary, checksum verified, smoke-tested.

## 7. Philosophy
- Paid license, sold through Stripe and issued by Keygen
- Engine binary proprietary (protects the invention); surface MIT
- Commercial embedding licenses available — https://github.com/sponsors/Michael-A-Kuykendall
- Automatic or it does not exist
- State, not story
- Fail-closed, degrade-graceful

## 8. Roadmap teaser + Community
Link to ROADMAP.md, Discussions, Issues, Sponsors tiers.
Clear call for early adopters / feedback.

## 9. Footer
License summary, contact for commercial licensing, GitHub Sponsors badge.