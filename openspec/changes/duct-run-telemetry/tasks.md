## 1. Verb references

- [ ] 1.1 `references/verbs/run.md`: a "Resource telemetry" step between gathering parameters and constructing the command — `command -v duct`; if found, write and save `.duct/.gitattributes` (D4) when absent, wrap the command with the D1 form, add `-o .duct/logs/<op>`, read `duct --version` for the binding; if not found, run unwrapped and say so in one line
- [ ] 1.2 `run.md` constraints: double the braces of duct's placeholders inside `datalad run`; never pass `--clobber`; never wrap a scheduler submission; the user may decline the wrap per run
- [ ] 1.3 `references/verbs/container-run.md`: wrap only when the image provides duct (D6), with the same prefix, output and binding rules; otherwise run unwrapped and report that usage was not captured
- [ ] 1.4 Confirm `plugins/datalad-cli/rules/datalad.md` is byte-identical before and after

## 2. Planners

- [ ] 2.1 `process/run-pipeline` step 4: in words, capture resource usage when duct is available, per the `datalad` skill's run reference, and add duct's binding to the commit; not for scheduler submission. No duct command line
- [ ] 2.2 `analyze/run-comparison` step 4: in words, capture resource usage when the environment's pinned manifest provides duct; report when it does not
- [ ] 2.3 Both planners' report steps name the log directory when one was written

## 3. Lint

- [ ] 3.1 Add `duct` and `con-duct` to `PERIPHERAL_BINARIES` in `tests/lint-plugins.py`
- [ ] 3.2 `python3 tests/lint-plugins.py --strict` and `python3 tests/lint-plugins-selftest.py` pass

## 4. Cost probe

- [ ] 4.1 `bench/probes/cost.yaml`: add `compute_usage` (type `measured`), its source (committed `*_info.json` and `*_usage.jsonl` of run commits carrying a duct binding), and an invalidator for summing it with agent `wall_clock`
- [ ] 4.2 `docs/evaluation.md` "Probe: cost": the same metric, and that a stage without duct bindings reports it as unmeasured
- [ ] 4.3 `python3 tests/check-bench-fixtures.py` reports no new problem for `cost.yaml`

## 5. End-to-end

- [ ] 5.0 Add `tests/envs/con-duct/` (`pyproject.toml` pinning `con-duct==0.22.0`, committed `uv.lock`) in the layout `live-tool-test-envs` defines; that change creates only the nipoppy, bagel, pynidm and reproschema envs
- [ ] 5.1 `tests/e2e-smoke.sh`: a block gated on `tool_env con-duct` (from `live-tool-test-envs`), falling back to `command -v duct`, else `  SKIP: duct not available`
- [ ] 5.2 In a scratch `text2git` dataset: write and save `.duct/.gitattributes`, then `datalad run` a short successful command (duct deletes logs only for a command that fails within `--fail-time`) wrapped per D1 with `-o .duct/logs/e2e`
- [ ] 5.3 Assert: `*_usage.jsonl` and `*_info.json` are tracked in git and not annexed; `*_stdout` is annexed; the run record's `outputs` lists `.duct/logs/e2e`; the commit carries a `DSH-Binding: datalad-cli/duct@` line
- [ ] 5.4 `datalad rerun` the commit; assert it succeeds and a second, differently named log set exists
- [ ] 5.5 Record the con-duct version the block ran against in the test's comment header
