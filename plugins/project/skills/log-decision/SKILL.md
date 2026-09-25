---
name: log-decision
description: >
  Record a design or analysis decision — what was decided, why, and the alternatives considered — as
  a durable entry in the project log. Trigger on "log this decision", "record why we chose", "decision
  log", "note the rationale", "document this choice", "we decided to". Captures the reasoning behind
  choices so the project's history explains itself.
plane: workflow
stamped: [T]
---

# Skill: log-decision

Capture the *why* behind a choice so future-you (or a collaborator, or a reviewer) can reconstruct
the reasoning, not just the result. Decisions are recorded as durable ADR-shaped files under
`docs/decisions/` — provenance for judgment, alongside the provenance for computation. You save
these yourself with `datalad save`, the way you would any other file.

## When to use
- A non-obvious methodological or design choice was made (a model, an exclusion criterion, a tool,
  dropping/keeping a comparison) and its rationale should be preserved.
- Do NOT use to record a computation (`analyze/run-comparison` already provenances that) or to make
  a formal commitment (`govern/preregister` / `govern/obligations`).

## Steps
1. **Capture the decision** — get: the `decision` (what was chosen), the `rationale` (why), the
   `alternatives` considered and why they were not chosen, and the `scope` (which branch/comparison/
   product it affects, if any).
2. **Write the decision record** — `docs/decisions/<YYYY-MM-DD>-<slug>.md`, slug from a short
   kebab-case form of the decision, with sections:
   ```markdown
   # <decision, one line>

   ## Decision
   <what was chosen>

   ## Rationale
   <why>

   ## Alternatives considered
   <each alternative and why it was not chosen>

   ## Scope
   <branch/comparison/product this affects, if any>
   ```
   Keep it self-contained so the reasoning is legible from the file alone.
3. **Save and record in one step**:
   ```bash
   datalad save -m "$(printf 'log-decision: <short decision>\n\nDSH-Op: log-decision\nDSH-Stage: manage')" docs/decisions/<file>
   ```
4. **Report** — confirm the decision record's path and on which branch.

## Constraints
- Record the decision *and* its rationale and alternatives — a decision without its "why" is not
  worth logging; do not reduce it to a bare statement.
- Record honestly: capture the actual reasoning, including trade-offs, not a post-hoc justification.
- Decision records are append-only history — a reversed decision is a *new* file referencing the
  prior one's path, never an edit of it. Save it yourself with `datalad save`; nothing is written to
  `project.yaml` `log`.
