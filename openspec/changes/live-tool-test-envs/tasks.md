## 1. Per-tool environments

- [ ] 1.1 Create `tests/envs/{nipoppy,bagel,pynidm,reproschema}/pyproject.toml`: `[tool.uv] package = false`, one direct dependency pinned `==` to the current PyPI release (confirm the Neurobagel package name is `bagel` on PyPI), a `requires-python` floor from the tool, and a header comment stating scope (live tool tests only; not a check dependency; not a harness dependency)
- [ ] 1.2 `uv lock --project tests/envs/<tool>` for each; commit the four `uv.lock` files
- [ ] 1.3 Confirm `git check-ignore tests/envs/nipoppy/.venv` matches the existing `.venv/` rule; add nothing to `.gitignore` if it does

## 2. bin/test-envs

- [ ] 2.1 `bin/test-envs sync [tool]`: `uv sync --locked --project tests/envs/<tool>`, then print `<tool>: <runtime --version>` from the env's own binary; all tools under `tests/envs/` when none is named
- [ ] 2.2 `bin/test-envs check [tool]`: one line per env, `ok <version>` | `missing` | `stale` (via `uv sync --locked --check`); exit 0 all ok, 1 otherwise, 2 unknown tool; never modifies an env
- [ ] 2.3 Exit 2 with a message when `uv` is not on `PATH`

## 3. e2e helper and fixtures

- [ ] 3.1 Add `tool_env <name> <cmd…>` to the helpers block of `tests/e2e-smoke.sh` (beside `ok`/`bad`/`assert`/`skip`): subshell, `tests/envs/<name>/.venv/bin` prepended to `PATH`; a companion `tool_env_ready <name>` that calls `bin/test-envs check <name>` and prints the skip reason
- [ ] 3.2 `tests/fixtures/live/nipoppy/manifest.tsv`: one participant, one visit/session, columns as `nipoppy init`'s template manifest has them
- [ ] 3.3 `tests/fixtures/live/bids/`: `dataset_description.json`, `participants.tsv`, `sub-01/anat/sub-01_T1w.json`; a stdlib-only writer for `sub-01_T1w.nii.gz` run at test time
- [ ] 3.4 `tests/fixtures/live/reproschema/`: minimal protocol → one activity → one item, from the ReproSchema examples; source recorded
- [ ] 3.5 `tests/fixtures/live/bagel/participants.{tsv,json}` and a dataset description: copied from Neurobagel's published example data with source and licence recorded in a README beside them; no hand-written term identifiers

## 4. Live e2e sections

- [ ] 4.1 nipoppy (gated on `tool_env_ready nipoppy`): `init --dataset` in a fresh dir; assert the files the version actually writes; install the fixture manifest; `track-curation`; assert the curation status file exists at the path the tool uses; `status` exits 0
- [ ] 4.2 nipoppy compute (additionally gated on apptainer and `DSH_NIPOPPY_PIPELINE=<bundle dir>` with its image present): `bidsify` or `process --simulate` with explicit `--pipeline`, `--pipeline-version`, `--pipeline-step`; assert exit 0 and that no output directory was populated. Unverified: whether `--simulate` needs the image file to exist
- [ ] 4.3 bagel (gated on `tool_env_ready bagel`): `pheno` on the annotated fixture produces a JSONLD file; `pheno` on the e2e's unannotated dictionary fails, and the assertion checks the error text names the annotation problem, not an unknown option
- [ ] 4.4 pynidm (gated on `tool_env_ready pynidm`): `bidsmri2nidm` on the BIDS fixture writes a non-empty Turtle file; confirm it does not block on stdin (run with `</dev/null` and a timeout)
- [ ] 4.5 reproschema (gated on `tool_env_ready reproschema`): `validate` on the fixture exits 0; `validate` on a copy with a required field removed exits non-zero
- [ ] 4.6 Every section also runs the relevant `check-backends.sh` / gate inside `tool_env` and asserts `result: available`, so the gate and the tool agree
- [ ] 4.7 With no env synced, the full e2e still passes and prints one `SKIP: run bin/test-envs sync <name>` per tool

## 5. Refinement loop

- [ ] 5.1 Run each live section; for each disagreement with a toolbox skill or reference, fix the skill/reference and the doer (and `check-backends.sh` `enable:` lines for package names), then add a row to design.md "Refinements found" with `tool@version`, the old text, the observed behaviour, and the files changed
- [ ] 5.2 Confirm or correct the pre-recorded findings in design.md Context: `global_config.json` vs `config.json`; nipoppy layout paths (`tabular/`, `proc/logs/`); `track-curation` filters; `status --verbose`; the bagel package name; `pheno --name` vs `--dataset-description`; `bids --bids-dir` vs `--bids-table`
- [ ] 5.3 Verify the unverified subcommands (pynidm `bidsmri2nidm` flags, `pynidm query`; reproschema `validate`, `convert`, `redcap2reproschema`, `reproschema2redcap`) against `--help` in the locked envs
- [ ] 5.4 Settle the `DSH-Binding` open question and apply it to the doers' `binding:` lines if it changes them

## 6. Docs, manifests, checks

- [ ] 6.1 `README.md` setup section: `bin/test-envs sync` and what each env enables; the e2e skips per tool without them
- [ ] 6.2 Sibling-manifest comments in `pyproject.toml` and `environment.yml` name `tests/envs/*/pyproject.toml`
- [ ] 6.3 Measure `bin/test-envs sync` time on a clean runner; add it to the dispatch-only e2e job in `.github/workflows/ci.yml` if acceptable, else record why not in the workflow header
- [ ] 6.4 `python3 tests/lint-plugins.py --strict`, the selftest, `bash tests/e2e-smoke.sh` (with and without envs), and `openspec validate live-tool-test-envs --strict` pass
