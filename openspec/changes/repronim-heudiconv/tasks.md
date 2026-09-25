## 1. Toolbox: `heudiconv-cli`

- [ ] 1.1 `plugins/heudiconv-cli/.claude-plugin/plugin.json` registering three skills; `stamped` tags on each
- [ ] 1.2 `skills/heudiconv-inspect/SKILL.md`: first pass with `-c none -f convertall` into a scratch `-o` outside the dataset; where `dicominfo` lands; scoping by subject and session; the ReproIn parse rule (D3); never write into the dataset
- [ ] 1.3 `skills/heudiconv-heuristic/SKILL.md`: `reproin` selection; the `code/heuristics/<name>.py` scaffold (one `create_key` per series, unplaced series commented and listed); hand the save back
- [ ] 1.4 `skills/heudiconv-convert/SKILL.md`: construct only — `--files`, `-b`, `-c dcm2niix`, `-o .`, `-l ''`; no `--datalad`, no `--overwrite` by default; doubled braces for a `-d` template; declared inputs and outputs; the `.heudiconv/` `.gitattributes` rule (D7)
- [ ] 1.5 `scripts/check-heudiconv.sh`: offline presence and version check for `heudiconv` and `dcm2niix`, exit codes in the style of `bids-cli/scripts/check-validator.sh`
- [ ] 1.6 Before writing 1.2–1.4, run both passes locally against the e2e phantom set and record the observed `dicominfo` path and output tree in the skills; correct the D2/D5 claims if v1.5.1 differs from `master`

## 2. Doer: `heudiconv`

- [ ] 2.1 `plugins/heudiconv/agents/heudiconv-doer.md`: parse the request (DICOM source, subject, session, output root, heuristic preference); check tools; run the first pass; select or scaffold the heuristic; construct the conversion; no `model:` (not read-only)
- [ ] 2.2 The structured result: `op`, `heuristic` (`reproin` | path), `series` (table with target BIDS names), `command`, `inputs`, `outputs`, `run_via: planner`, `save_via` (planner, when a scaffold was written), `result` (`constructed` | `needs-confirmation` | `failed`), `binding` (heudiconv and dcm2niix), `notes`
- [ ] 2.3 Constraints: never run the conversion; never commit; never fetch annexed content (report it missing); never pass `--datalad`
- [ ] 2.4 `plugins/heudiconv/.claude-plugin/plugin.json`

## 3. Planner: `curate/raw-to-bids`

- [ ] 3.1 Route by layout (D8) as a first step; `delegates_to: [nipoppy, heudiconv]`; body names the **heudiconv doer** (lint requires the prose mention)
- [ ] 3.2 HeuDiConv path in words: get the DICOM source, ask the doer to inspect and propose, show the series table, confirm and save any scaffolded heuristic, ask for the conversion command, save the `.gitattributes` rule if new, run under `datalad run` with the doer's inputs, outputs and both `DSH-Binding` lines. No heudiconv or dcm2niix command lines
- [ ] 3.3 Curation-status step applies to the nipoppy path only; description and "When to use" cover both paths
- [ ] 3.4 `plugins/curate/.claude-plugin/plugin.json` description: raw-to-bids via nipoppy or HeuDiConv

## 4. Counts, enumerations and docs

- [ ] 4.1 `.claude-plugin/marketplace.json`: add both plugins; add `heudiconv` to "capability-plane doers (…)" (lint `check_marketplace_claims` errors otherwise)
- [ ] 4.2 `README.md`: `**21 plugins**` → 23; 15 → 17 capability plugins; two table rows (`heudiconv` doer, `heudiconv-cli` toolbox "3 skills, one per pass, + offline tool check"); "seven doers" → eight; the uneven-depth paragraph
- [ ] 4.3 `docs/end-to-end-workflow.md` Stage 2: `raw-to-bids` → the `nipoppy` or `heudiconv` doer
- [ ] 4.4 `bench/tasks/routing-lifecycle.yaml` `curate-raw`: `expected_delegates_to` gains `heudiconv`. Its `datalad` entry is part of a pre-existing staleness (all 84 current `check-bench-fixtures` problems concern `datalad`) that this change does not fix
- [ ] 4.5 Add `dcm2niix` to `PERIPHERAL_BINARIES` in `tests/lint-plugins.py`
- [ ] 4.6 `python3 tests/lint-plugins.py --strict` and the selftest pass; lint reports 23 plugins and 9 agents

## 5. End-to-end

- [ ] 5.0 Add `tests/envs/heudiconv/` (`pyproject.toml` pinning `heudiconv==1.5.1`, committed `uv.lock`) in the layout `live-tool-test-envs` defines; that change creates only the nipoppy, bagel, pynidm and reproschema envs
- [ ] 5.1 `tests/e2e-smoke.sh` block gated on `tool_env heudiconv` (from `live-tool-test-envs`) and `command -v dcm2niix`, and on a source: `DSH_DICOM_DIR`, or `DSH_NET=1`; else `  SKIP: <reason>`
- [ ] 5.2 With `DSH_NET=1`: `datalad download-url` two ReproIn-named phantom DICOMs from HeuDiConv's tagged test data, `v1.5.1` (`heudiconv/tests/data/01-anat-scout/0001.dcm`, 174,070 bytes; `heudiconv/tests/data/01-fmap_acq-3mm/1.3.12.2.1107.5.2.43.66112.2016101409263663466202201.dcm`, 122,162 bytes; about 296 KB together) into `inputs/dicom/` of a scratch `text2git` dataset
- [ ] 5.3 First pass into a scratch directory; assert a `dicominfo` table lists both series and the dataset tree is unchanged
- [ ] 5.4 Assert the ReproIn check passes for the phantom set, and fails for a copy of the table with one protocol name altered
- [ ] 5.5 Second pass under `datalad run` with `-l ''`; assert NIfTI and JSON under `sub-phantom1sid1/` (upstream tests name subject `phantom1sid1`, session `localizer`), the scout tarball under `sourcedata/`, `.heudiconv/` annexed, the run record listing the declared inputs and outputs, and two `DSH-Binding` lines
- [ ] 5.6 With `DSH_DICOM_DIR`: the same flow without the ReproIn assertion; assert only that some `sub-*` NIfTI is produced under a run record
