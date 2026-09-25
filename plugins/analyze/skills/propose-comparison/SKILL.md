---
name: propose-comparison
description: >
  Start a new analysis as a lightweight "comparison" on its own DataLad branch and record it in
  the project log. Trigger on "propose a comparison", "add an analysis", "new comparison",
  "let's look at X vs Y", "start an analysis branch". Each comparison is one addable unit that can
  be introduced at any point — the story is built from comparisons, not a rigid pipeline.
plane: workflow
stamped: [A, T, M]
---

# Skill: propose-comparison

Create a comparison: a small, branch-scoped analysis unit realized as a **named DataLad branch**
plus a project-log entry. Comparisons span a rigor spectrum: an **exploratory** quick query (default)
that lives only as a branch/run, or a **confirmatory** one whose spec is frozen and registered
*before* execution via `govern/preregister`. The *record* here is already the spec-centric research
object of STAMPED §3.12.1.

## When to use
- The user wants to run any analysis/plot/comparison against the dataset.
- Do NOT use to initialize a project (`project/new-project`) or to execute an already-proposed
  comparison (`analyze/run-comparison`).

## Steps
1. **Capture the comparison** — get from the user (short, one-liner each):
   - `what` — the comparison in a sentence ("group difference in outcome Y")
   - `why` — the question it answers *(optional but encouraged)*
   - expected `inputs` and `outputs` (best guess; refined at run time)
   - rigor: `exploratory` (default). If the user wants `confirmatory`, create the branch (steps
     2–4) and then route to `govern/preregister` to freeze + register the spec *before* the analysis
     is run — do not execute it as confirmatory until the spec is frozen.
2. **Choose a clear branch name** — `cmp/<short-slug>` (e.g. `cmp/group-diff-y`). The user owns
   naming conventions; suggest one and confirm. Clear, stable names are how comparisons stay
   navigable (the harness does not track branches for you beyond the log).
3. **Create the branch** — run it yourself, DataLad is native like git:
   ```bash
   git checkout -b cmp/<slug>
   ```
4. **Write and save the record** — write the `what`/`why`/`inputs`/`outputs`/rigor to
   `code/cmp-<slug>.md`, then save it in one step:
   ```bash
   datalad save -m "$(printf 'propose cmp/<slug> — <what> (<rigor>)\n\nDSH-Op: propose-comparison\nDSH-Stage: analyze')" code/cmp-<slug>.md
   ```
5. **Report** — the branch name and that the next step is writing the analysis script, then
   `analyze/run-comparison` to execute it with provenance.

## Constraints
- One comparison = one branch. Do not stack unrelated comparisons on the same branch.
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`.
- Do NOT choose the analysis, model, or figures for the user — the harness scaffolds the edges of
  the work (branch, provenance, record), not the scientific question itself. Writing the analysis
  script is the user's job; `run-comparison` wraps whatever they wrote.
- Run the branch operation and the save yourself; DataLad and git are native, not a doer.
