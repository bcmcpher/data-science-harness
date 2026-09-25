---
name: status-report
description: >
  Generate a human-readable status/progress report for the project from the ledger — study header,
  products and their release/DOI state, outstanding obligations, contributors, and recent activity.
  Trigger on "status report", "progress report", "where is the project", "generate PROJECT.md",
  "funder report", "project summary", "catch me up in writing". Produces a report from project.yaml;
  it never hand-edits the ledger.
plane: workflow
stamped: [M]
---

# Skill: status-report

Turn the ledger into a readable report. `project.yaml` is the machine-actionable source of truth;
this skill renders a report *from* it, and from the commit history, so people can read the
project's state without parsing YAML. This skill is **read-only**: it writes nothing and commits
nothing, unless the user asks for a copy to keep — edits go to the ledger via the owning skills.

> Distinct from the `coordinator` agent: the coordinator gives a fast interactive "where am I / what's
> next" on load; status-report renders a shareable written report and, only on request, keeps a copy
> of it in the dataset.

## When to use
- The user wants a written summary, a `PROJECT.md`, or a progress/funder report.
- Do NOT use to change project state — this only reads the ledger and renders it. To record a
  decision use `project/log-decision`; to credit people use `project/people`.

## Steps
1. **Read the state** — `project.yaml` for its `project`, `products`, `obligations`, `contributors`,
   and `bash plugins/datalad-cli/scripts/dsh-log.sh --legacy` for recent activity (op, stage,
   timestamp, subject — legacy `log` entries are included automatically).
2. **Render the report** (in chat, or to the requested path) with:
   - **Overview** — study name/description, current stage (from the most recent `dsh-log` op),
     branch.
   - **Products** — each product: kind, status, comparisons, outputs, DOIs, relations.
   - **Obligations** — pending (highlight due/overdue), met, waived.
   - **People** — contributors with CRediT roles + ORCIDs.
   - **Recent activity** — the last several `dsh-log` records.
   Fill only from the ledger and the history; mark anything absent (e.g. "no DOI — unreleased"), do
   not invent.
3. **Report** — the rendered report. Nothing is written or committed by default.
4. **Only if the user asks to keep a copy** — write `reports/status-<YYYY-MM-DD>.md` and save it:
   ```bash
   datalad save -m "$(printf 'status-report: render reports/status-<date>.md\n\nDSH-Op: status-report\nDSH-Stage: manage')" reports/status-<date>.md
   ```

## Constraints
- Generated, not authored: the report is rendered from the ledger and history and should not be
  hand-edited; never write project state *into* the report that is not in the ledger.
- Render only what the ledger and history contain; mark gaps rather than filling them.
- Read-only by default: do not edit `project.yaml` (including `log`, which is legacy and unwritten
  by every skill) to make the report read better, and do not commit unless the user asks for a saved
  copy.
