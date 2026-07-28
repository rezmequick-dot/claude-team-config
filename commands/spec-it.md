---
description: copilot-ado-loop spec stage — generate an implementation spec for the current ticket and route it for Stakeholder approval.
argument-hint: (the loop supplies all ticket context; no manual arguments needed)
---

# /spec-it — Spec generation (spec-only)

You are generating a complete, **handoff-ready** implementation spec for the work item
described in the surrounding prompt context. Follow the detailed instructions the
copilot-ado-loop supervisor provides immediately below this command **verbatim** — they
specify exactly what to write, where to write it, the notification-comment format, the
required state transition, and the mandatory handoff line.

Rules of this stage:
- **Spec-only.** Do NOT implement code, do NOT create a branch, do NOT run any other
  pipeline phase.
- **Ground the spec in reality.** Read the actual repository with your tools and verify
  against the parent Epic / User Story before writing. Resolve ambiguity in the spec or
  explicitly flag it in the ticket comment.
- **Be unambiguous.** A local implementation model must be able to execute the spec
  without judgment calls (clear scope, approach, and acceptance criteria).
- **Hard requirement:** the run FAILS unless it ends with exactly one line beginning
  `STAGE_HANDOFF_JSON:` followed by a JSON object with keys `stage` (="spec"),
  `summary`, `deliverables`, `validation`, `risks`, `nextAction`.

If the surrounding context includes Stakeholder feedback on a prior spec version, treat
this as a revision: address the feedback and note what changed.
