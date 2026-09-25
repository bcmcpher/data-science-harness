## Why

A `datalad run` commit records what ran, on which inputs, and what it wrote. It does not record
what the run cost: peak memory, CPU time, wall-clock, or the host it ran on. Those numbers are
what a researcher needs to size the next cluster job, and what a reader needs to judge whether a
rerun is feasible. Today they are lost when the terminal closes.

`con-duct` (`duct`, from the Center for Open Neuroscience, a ReproNim partner) wraps a command,
samples its process tree, and writes the samples and a system summary next to the command's
captured stdout and stderr. It propagates the wrapped command's exit code, so a failing command
still fails the run. Put inside `datalad run`, its logs become declared outputs of the run commit,
and the resource record travels with the provenance record.

The evaluation protocol's cost probe measures agent cost: tokens, priced cost, wall-clock and
interventions per lifecycle stage. It has no measure of the compute that the stage triggered.
Committed duct logs would give it one without a new instrument.

## What Changes

- **The `datalad` skill's `run` and `container-run` verb references** describe wrapping the
  recorded command in `duct` when `duct` is on `PATH`. The log prefix sits under
  `.duct/logs/<DSH-Op>/`, that directory is declared as an output, and the run commit carries a
  `DSH-Binding` line for duct's version. The always-loaded rules file
  (`plugins/datalad-cli/rules/datalad.md`, 282 of 300 words) is not changed.
- **A `.duct/.gitattributes` rule** keeps the JSON logs (`usage.jsonl`, `info.json`) in git and
  annexes the captured `stdout` and `stderr`. The run reference writes it once, before the first
  wrapped run, and saves it.
- **`process/run-pipeline` and `analyze/run-comparison`** say in words to capture resource usage
  when duct is available, following the `datalad` skill's run reference. They quote no duct
  command line.
- **`tests/lint-plugins.py`**: `duct` and `con-duct` join `PERIPHERAL_BINARIES`, so a planner that
  quotes a duct command line is an error.
- **The cost probe** (`bench/probes/cost.yaml`, `docs/evaluation.md`) gains a `compute_usage`
  metric read from committed duct logs. It is reported beside agent cost and never summed with it.
- **`tests/e2e-smoke.sh`** gains a gated block: duct inside `datalad run` in a scratch dataset,
  asserting that the usage log is committed to git, the captured output is annexed, the run record
  lists the log directory as an output, and `datalad rerun` writes a second log set.

**Not in this change:** adding `con-duct` to container images or to the environment manifest that
`project/new-project` scaffolds; host-side wrapping through a container's `--call-fmt`; plotting
or summarising logs (`con-duct plot`, `con-duct ls`); any duct doer or toolbox plugin.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `datalad`: add the telemetry wrap to the run path, and allow a `DSH-Binding` for duct that no
  doer returns.
- `process`: pipeline runs capture resource usage when duct is available.
- `analyze`: comparison runs capture resource usage when the image provides duct.
- `evaluation-protocol`: duct logs are an input the cost probe may read, kept apart from agent
  cost.

## Impact

- `plugins/datalad-cli/skills/datalad/references/verbs/run.md`, `.../verbs/container-run.md`
- `plugins/process/skills/run-pipeline/SKILL.md`, `plugins/analyze/skills/run-comparison/SKILL.md`
- `tests/lint-plugins.py` (`PERIPHERAL_BINARIES`)
- `bench/probes/cost.yaml`, `docs/evaluation.md`
- `tests/e2e-smoke.sh`
- No rules-file, hook, doer or schema changes. `dsh-log.sh` already collects every `DSH-Binding`
  line of a commit.
- **Depends on** `live-tool-test-envs` for the e2e block's `tool_env con-duct`. Without it the
  block falls back to `command -v duct` and otherwise skips.
