---
name: run-pipeline
description: >
  Run a nipoppy processing pipeline (fMRIPrep, MRIQC, ...) on a dataset's BIDS data with full
  DataLad provenance, then record completion status. Trigger on "run fmriprep", "run mriqc",
  "process the dataset", "run the pipeline", "run a nipoppy pipeline", "process participants with
  provenance". This is the Stage-8 (Process) entry point — nipoppy commands invoked *with* datalad.
plane: workflow
stamped: [A, T, P, E]
delegates_to: [nipoppy]
---

# Skill: run-pipeline

Execute a nipoppy processing pipeline so the computation is **provenanced**: nipoppy provides the
containerized pipeline invocation (Boutiques + Apptainer → Portability/Ephemerality), and DataLad
wraps it (`datalad run`) so inputs, command, and outputs are recorded (Actionability + Tracking).
The **nipoppy** doer constructs and validates the command; you run it yourself under `datalad run`,
the way you would run git.

> Design note: nipoppy alone does not record provenance and datalad does not know pipeline
> mechanics — so this planner joins them. The nipoppy command is always executed *through*
> `datalad run`; a bare `nipoppy process` is never the final step. (The container image itself is
> pinned by nipoppy's `config.json` + Boutiques descriptor, so datalad's own `container-run`
> image-capture is not needed here — nipoppy owns that layer.)

## When to use
- A nipoppy dataset (`config.json` + `manifest.tsv`) exists with BIDS data ready, and the user
  wants to run a processing pipeline.
- Do NOT use to create/curate the dataset (that is nipoppy `init`/`bidsify` — a future `curate`
  planner) or to run a bespoke analysis script (that is `analyze/run-comparison`).

## Steps
1. **Confirm pipeline + context** — determine the `--pipeline`, `--pipeline-version`, and
   optional `--pipeline-step` / `--participant-id` / `--session-id` from the user. If the pipeline
   or version is unspecified, ask (never guess a version).
2. **Validate + construct (nipoppy doer)** — delegate:
   > "Validate this nipoppy dataset (config.json, manifest.tsv, Linux+Apptainer, pipeline version
   > matches a pulled image) and construct the `nipoppy process --pipeline <X> --pipeline-version
   > <V> [...]` command; run it once with `--simulate` to preview, and return the exact command
   > plus the inputs it reads and outputs it writes."
   Expect a structured result with `command`, `inputs`, `outputs`, `run_via: datalad-run`, and a
   `binding` (e.g. `nipoppy/<pipeline>@<version>`). If it returns `result: failed` (state/platform
   gap), relay the fix and stop.
3. **Ensure a clean tree** — `datalad run` requires a clean tree:
   ```bash
   datalad status
   ```
   If dirty, route to `analyze/checkpoint` first (or have the user confirm), then continue.
4. **Run with provenance** — run the constructed command yourself:
   ```bash
   datalad run -m "$(printf '<pipeline> <version> on <scope>\n\nDSH-Op: run-pipeline\nDSH-Stage: process\nDSH-Binding: <binding from step 2>')" \
     -i <inputs from step 2> \
     -o <outputs from step 2, e.g. derivatives/<pipeline>, proc/logs/<pipeline>> \
     "<the nipoppy process command>"
   ```
   Use exactly one `-m`. On failure, relay the error and the nipoppy log path; nothing was
   committed. Stop.
5. **Record completion (nipoppy doer, then save yourself)** — after a successful run:
   > nipoppy doer: "track-processing for `<pipeline>` to update `tabular/bagel.tsv`."
   Then save what it wrote:
   ```bash
   datalad save -m "$(printf 'track-processing: <pipeline> <version>\n\nDSH-Op: run-pipeline\nDSH-Stage: process\nDSH-Binding: <binding>')" tabular/bagel.tsv
   ```
6. **Report** — the pipeline/version/scope, the provenance commit, output derivatives, updated
   bagel status, and that the run is replayable with `datalad rerun`. Suggest the next step
   (`nipoppy extract` for IDPs, or `analyze/propose-comparison`).

## Constraints
- Always execute the nipoppy command through `datalad run` yourself — never let a dataset-mutating
  `nipoppy process`/`bidsify`/`extract` run bare. Provenance is the whole point.
- Require a meaningful `-m` message that names the pipeline, version, and scope; never a placeholder,
  and never more than one `-m` (DataLad keeps only the last).
- Declare inputs/outputs from the nipoppy doer's report — do not invent paths. Prefer the pipeline's
  own `derivatives/<pipeline>` and `proc/logs/<pipeline>` as `-o`; leave `scratch/` untracked.
- Do not diagnose or "fix" the pipeline's science — if a container errors on its own logic, surface
  the nipoppy log to the user; the harness owns provenance, not the pipeline internals.
- Record activity in the commit's `DSH-*` lines, never in `project.yaml` `log`. Note a failed run to
  the user; do not commit as if it had succeeded.
