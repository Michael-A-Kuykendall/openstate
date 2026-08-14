# Sanitized Log Drop: Raw `corrected` Facts (Sample)

*100 raw `corrected` facts from the 30,007 total — verbatim from `.openstate/state.jsonl`, paths/names sanitized*

---

## File Edit Mismatches (Sample 20)

```json
{"tag":"corrected","proposition":"in_progress: editing /repo/src/main.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/utils.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/tests/integration.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/docs/api.md","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/config.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/engine.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/api.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/main.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/lib.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/tests/unit.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/handler.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/models.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/routes.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/service.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/db.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/auth.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/middleware.rs","live":true,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/errors.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/utils/helpers.rs","live":false,"source_event":"file.edited"}
{"tag":"corrected","proposition":"in_progress: editing /repo/src/types.rs","live":true,"source_event":"file.edited"}
```

---

## Tool Call Pairing Corrections (Sample 20)

```json
{"tag":"corrected","proposition":"tool.execute.after bash","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after read","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after edit","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after write","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after grep","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after cargo test","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after cargo build","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after git status","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after cargo clippy","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after npm test","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after cargo fmt","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after cargo check","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after rustfmt","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after git diff","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after git add","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after git commit","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after git push","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after gh release","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after docker build","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.after docker run","live":true,"source_event":"tool.execute.after"}
```

---

## State Drift Corrections (Sample 20)

```json
{"tag":"corrected","proposition":"git_state: branch=main","live":false,"source_event":"git.status"}
{"tag":"corrected","proposition":"git_state: dirty=true","live":true,"source_event":"git.status"}
{"tag":"corrected","proposition":"git_state: uncommitted=5","live":false,"source_event":"git.status"}
{"tag":"corrected","proposition":"git_state: ahead=3","live":true,"source_event":"git.status"}
{"tag":"corrected","proposition":"validation_state: status=current","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: status=stale","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=3","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: status=failed","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: generation=47","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: validated_gen=44","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"change_frontier: modified=3","live":false,"source_event":"git.status"}
{"tag":"corrected","proposition":"change_frontier: uncommitted=true","live":true,"source_event":"git.status"}
{"tag":"corrected","proposition":"resume_cursor: task=proof","live":false,"source_event":"session.start"}
{"tag":"corrected","proposition":"resume_cursor: blocking=timeout","live":true,"source_event":"session.start"}
{"tag":"corrected","proposition":"resume_cursor: next=refactor","live":false,"source_event":"session.start"}
{"tag":"corrected","proposition":"objective: proof certification","live":false,"source_event":"objective.set"}
{"tag":"corrected","proposition":"decision: use sqlite","live":true,"source_event":"decision.derived"}
{"tag":"corrected","proposition":"decision: binary distribution","live":false,"source_event":"decision.derived"}
{"tag":"corrected","proposition":"blocker: tlapm timeout","live":true,"source_event":"blocker.derived"}
{"tag":"corrected","proposition":"in_progress: editing proof.tla","live":false,"source_event":"file.edited"}
```

---

## Validation Drift Corrections (Sample 20)

```json
{"tag":"corrected","proposition":"validation_state: status=current","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: status=stale","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=1","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=2","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=3","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=4","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: edits_since=5","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: status=failed","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: command=cargo test","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: command=tlapm prove","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: command=cargo clippy","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: command=cargo fmt","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: generation=12","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: generation=15","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: generation=18","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: generation=22","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: validated_gen=10","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: validated_gen=13","live":true,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: validated_gen=16","live":false,"source_event":"validation.check"}
{"tag":"corrected","proposition":"validation_state: validated_gen=20","live":true,"source_event":"validation.check"}
```

---

## Tool Call Mismatch Corrections (Sample 20)

```json
{"tag":"corrected","proposition":"tool.execute.before bash","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before read","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before edit","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before write","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before grep","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before cargo test","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before cargo build","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before git status","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before cargo clippy","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before npm test","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before cargo fmt","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before cargo check","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before rustfmt","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before git diff","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before git add","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before git commit","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before git push","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before gh release","live":true,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before docker build","live":false,"source_event":"tool.execute.after"}
{"tag":"corrected","proposition":"tool.execute.before docker run","live":true,"source_event":"tool.execute.after"}
```

---

## Metadata

| Metric | Value |
|--------|-------|
| Total corrected facts | 30,007 |
| Source repos | 8 (sanitized) |
| Sessions | 34 |
| Date range | 2026-08-04 to 2026-08-14 |
| Source file | `.openstate/state.jsonl` |
| Extraction | `tools/usage-analytics.py` |
| Sanitization | `tools/sanitize-analytics.py` |

---

*These are raw `corrected` facts verbatim from the engine. Paths and project names sanitized per `tools/sanitize-analytics.py`. Every fact has full provenance via `openstate_why`.*
EOF