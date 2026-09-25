## Why

`curate/raw-to-bids` converts DICOMs only through nipoppy. Its "When to use" section requires a
nipoppy dataset (`config.json` + `manifest.tsv`) with raw data already staged by `reorg`. A
researcher who has a folder of DICOMs and a YODA dataset from `project/new-project` has no route
to BIDS. The routing fixture `curate-raw` in `bench/tasks/routing-lifecycle.yaml` ("I have a folder
of DICOMs from the scanner. Get them into the standard layout.") describes exactly that user.

HeuDiConv is the ReproNim converter for this case. It works in two passes. The first pass
(`-c none`) reads the DICOM headers and writes a `dicominfo` table of the series found. The second
converts with a heuristic, a Python file that maps each series to a BIDS name. ReproIn is
HeuDiConv's built-in `reproin` heuristic. When series are named on the scanner by the ReproIn
convention (`<datatype[-suffix]>[_ses-…][_task-…][_acq-…][_run-…][_dir-…][__<custom>]`), no
study-specific heuristic has to be written. HeuDiConv already appears in the planner's
description and in `PERIPHERAL_BINARIES`, but no doer or toolbox exists for it.

## What Changes

- **A new `heudiconv` doer plugin** (`plugins/heudiconv/agents/heudiconv-doer.md`). The doer:
  - runs the first pass itself, into a scratch directory outside the dataset, and reads the
    series table;
  - selects `reproin` when every non-derived series name parses as ReproIn;
  - otherwise writes a heuristic scaffold to `code/heuristics/<name>.py` and returns it for the
    user to confirm;
  - constructs the conversion command and returns it with inputs, outputs, `run_via: planner` and
    bindings for heudiconv and dcm2niix.

  It never runs the conversion and never commits.
- **A new `heudiconv-cli` toolbox plugin**, split by pass: inspect (first pass, series table,
  ReproIn check), heuristic (reproin or a scaffold), and convert (construct only). It also has an
  offline check for `heudiconv` and `dcm2niix`.
- **`curate/raw-to-bids` routes by dataset layout.** A nipoppy dataset goes to the nipoppy doer
  as today; nipoppy's `bidsify` can itself be configured to use HeuDiConv. Any other dataset goes
  to the heudiconv doer. `delegates_to` becomes `[nipoppy, heudiconv]`. Either way the planner
  runs the returned command under `datalad run`. Curation-status tracking stays on the nipoppy
  path only.
- **Counts and enumerations**:
  - `README.md`: 21 → 23 plugins, 15 → 17 capability plugins, "seven doers" → eight, two new
    table rows;
  - `.claude-plugin/marketplace.json`: two new plugins, and `heudiconv` added to the enumerated
    doer list, which the lint checks;
  - `plugins/curate/.claude-plugin/plugin.json` description;
  - `docs/end-to-end-workflow.md`;
  - the `curate-raw` routing fixture.
- **`dcm2niix` joins `PERIPHERAL_BINARIES`**; `heudiconv` is already there.
- **e2e**: a gated block that converts a small ReproIn-named phantom set under `datalad run`.

**Not in this change:** dcm2bids or BIDScoin outside nipoppy; the `reproin` study-management
script and ReproNim container images; `--datalad` mode, in which HeuDiConv creates and saves
datasets itself; defacing (that stays with `curate/deidentify`).

## Capabilities

### New Capabilities

- `heudiconv`: the doer and toolbox. Two-pass inspection, heuristic selection, and command
  construction for the planner's `datalad run`.

### Modified Capabilities

- `curate`: raw-to-BIDS routes to the nipoppy or heudiconv doer by dataset layout; a custom
  heuristic is confirmed and saved before conversion; curation status applies to the nipoppy path.

## Impact

- New: `plugins/heudiconv/`, `plugins/heudiconv-cli/`
- `plugins/curate/skills/raw-to-bids/SKILL.md`, `plugins/curate/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`, `README.md`, `docs/end-to-end-workflow.md`
- `bench/tasks/routing-lifecycle.yaml` (`curate-raw`)
- `tests/lint-plugins.py` (`PERIPHERAL_BINARIES` gains `dcm2niix`), `tests/e2e-smoke.sh`
- No `structural-lint` spec change: the existing marketplace-enumeration, delegation and
  peripheral-syntax checks cover the new plugins.
- **Depends on** `live-tool-test-envs` for `tool_env heudiconv` in the e2e block. `dcm2niix` is
  expected on `PATH`.
