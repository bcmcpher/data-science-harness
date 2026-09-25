---
name: raw-to-bids
description: >
  Convert raw imaging data (DICOMs) into a BIDS-valid layout with full DataLad provenance, via
  nipoppy's containerized converter. Trigger on "convert to BIDS", "bidsify", "dcm2bids",
  "heudiconv", "raw DICOMs to BIDS", "organize raw data", "curate the raw imaging". This is the
  Stage-2 (Curate) ingest step — getting raw data *into* the dataset before annotate/process.
plane: workflow
stamped: [S, A, T, P, E]
delegates_to: [nipoppy]
---

# Skill: raw-to-bids

Get raw imaging data into a standardized, **self-contained BIDS** layout so everything downstream
(annotate, process, analyze) has a canonical structure to work from — and do it **provenanced**:
nipoppy runs the containerized converter (dcm2bids / HeuDiConv / BIDScoin → Portability/Ephemerality)
and you wrap it in `datalad run` yourself so inputs, command, and outputs are recorded. You
delegate to the **nipoppy** doer, which constructs/validates the `bidsify` command; you run it
with provenance. You never construct the converter command yourself.

> Design note: like `process/run-pipeline`, the nipoppy command is executed *through* `datalad run`
> — a bare nipoppy bidsify run is never the final step. The converter container is pinned by nipoppy's
> `config.json` + Boutiques, so datalad's own `container-run` image-capture is not needed here.

## When to use
- A nipoppy dataset (`config.json` + `manifest.tsv`) has raw DICOMs staged (post-reorg) and needs
  BIDS conversion.
- Do NOT use to run a processing pipeline (`process/run-pipeline`), to add descriptive metadata to
  an already-BIDS dataset (`curate/annotate`), or to initialize a project (`project/new-project`).

## Steps
1. **Confirm readiness** — determine the converter (its pipeline name and version, as configured)
   and any participant and session scope from the user. Raw data must be staged where
   nipoppy expects it (post-reorg); if it is not, direct the user to nipoppy `reorg` first.
2. **Validate + construct (nipoppy doer)** — delegate:
   > "Validate this nipoppy dataset (config.json, manifest.tsv, Linux+Apptainer, converter version
   > matches a pulled image). Construct the bidsify command for converter <X> at version <V>,
   > scoped to participants <P> and sessions <S> if given. Preview it with a simulated run, and
   > return the exact command plus the inputs it reads (sourcedata/post-reorg) and outputs it
   > writes (`bids/`)."

   Always name the converter and its version. Never ask for a live run; the preview is the doer's
   only execution.
   If it returns `result: failed` (state/platform gap), relay the fix and stop.
3. **Ensure a clean tree** — `datalad run` requires a clean tree; check `datalad status`. If
   dirty, route to `analyze/checkpoint` first.
4. **Run with provenance** — run the returned command yourself:
   ```bash
   datalad run -m "$(printf 'bidsify <converter> on <scope>\n\nDSH-Op: raw-to-bids\nDSH-Stage: curate\nDSH-Binding: nipoppy/<pipeline>@<version>')" -i <inputs from step 2> -o <outputs from step 2, e.g. bids/> "<the nipoppy bidsify command>"
   ```
   Copy `binding` from the nipoppy doer's step-2 result into `DSH-Binding`. On failure, relay the
   error and the nipoppy log path; nothing was committed. Stop.
5. **Update curation status and record it, in one step** — after success, delegate the update:
   > nipoppy doer: "Update the curation status in `tabular/curation_status.tsv` after bidsify."

   Then save it yourself, naming the converter and scope:
   ```bash
   datalad save -m "$(printf 'track-curation: post-bidsify <converter> on <scope>\n\nDSH-Op: raw-to-bids\nDSH-Stage: curate')" tabular/curation_status.tsv
   ```
6. **Report** — the converter/scope, the provenance commit, the `bids/` output, and the next step:
   `curate/annotate` to enrich metadata, or `process/run-pipeline` to process the BIDS data.
   Suggest `govern/qc-review` (bids-validator) to confirm BIDS validity.

## Constraints
- Always execute the converter under `datalad run` yourself — never let a dataset-mutating
  nipoppy bidsify run bare. Provenance is the point.
- Require a meaningful `-m` message naming the converter and scope; never a placeholder.
- Declare inputs/outputs from the nipoppy doer's report — do not invent paths.
- Do not hand-edit `manifest.tsv` or restructure the raw data yourself — nipoppy owns the layout.
- Keep `project.yaml` schema-valid; record activity in the commit's `DSH-*` lines, never in
  `project.yaml` `log`.
