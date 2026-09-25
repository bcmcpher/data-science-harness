## Context

Facts this design relies on, checked on 2026-09-25 against con-duct v0.22.0 (PyPI, released
2026-08-24, `requires-python >=3.10`):

- The package `con-duct` installs two executables. `con-duct` has subcommands (`run`, `pp`,
  `plot`, `ls`); `duct` is the shorthand for `con-duct run`.
- `-p/--output-prefix` sets the log prefix. The default is `.duct/logs/{datetime}-{pid}_`; the
  understood placeholders are `{datetime}` and `{pid}`, and leading directories are created. The
  prefix can also come from `DUCT_OUTPUT_PREFIX`.
- With that prefix duct writes four files: `<prefix>stdout`, `<prefix>stderr`,
  `<prefix>usage.jsonl` (samples aggregated every `--report-interval`, default 60 s) and
  `<prefix>info.json` (system summary and the command). Before v0.18.0 the usage file was
  `usage.json`.
- duct refuses to overwrite existing log files unless `--clobber` is given.
- duct returns the wrapped command's exit code. If the command fails in under `--fail-time`
  (default 3 s) it deletes its logs.
- `datalad run` formats its command string with its own placeholders (`{inputs}`, `{outputs}`,
  `{pwd}` …). A literal brace must be doubled. A recorded command containing `{{datetime}}` is
  therefore stored as such and expands afresh on every `datalad rerun`.

In the harness, `datalad run` and `datalad containers-run` are native to the main thread. Their
procedure lives in `plugins/datalad-cli/skills/datalad/references/verbs/run.md` and
`container-run.md`. `process/run-pipeline` runs a nipoppy command under `datalad run`; nipoppy
starts Apptainer as a child process. `analyze/run-comparison` runs under `datalad containers-run`,
where the command string executes *inside* the image.

## Goals / Non-Goals

**Goals:**
- A provenanced run records its resource usage in the same commit, whenever duct is installed.
- Rerunning such a commit works and produces a new, separate log set.
- Planners ask for telemetry in words; the command form lives in the toolbox.
- The cost probe can read compute cost without a new instrument.

**Non-Goals:**
- Making duct a requirement. Without it every run proceeds exactly as today.
- Resource telemetry for runs submitted to a scheduler. duct would measure only the submission.
- A telemetry doer. duct has no choice to make that a doer would own.

## Decisions

**D1. The form lives in the verb references, not the rules.** The rules file is loaded into every
session and has 18 words of budget left. The run reference is read whenever a run is built. The
wrapped form it teaches:

```
datalad run -m "<message>" -i <inputs> -o <outputs> -o .duct/logs/<op> \
  "duct -p .duct/logs/<op>/{{datetime}}-{{pid}}_ <command>"
```

`<op>` is the commit's `DSH-Op` value, or `adhoc` for a run outside a harness skill.

*Alternative: a sentence in the rules.* Rejected: it spends the budget on an optional tool, and the
rules already send the model to the skill when it is unsure of a verb.

**D2. Default when available, never required.** The run reference checks `command -v duct`. If it
resolves, the run is wrapped and the user sees the wrapped command before it executes, as with any
run. If it does not, the run is not wrapped and nothing is said beyond one line in the report. A
user may decline the wrap for a single run.

*Alternative: opt-in per run.* Rejected: telemetry that has to be remembered is not collected, and
the cost of wrapping is one extra process and a few kilobytes of JSON.

**D3. Logs go in a per-operation directory, declared as an output.** Declaring `.duct/logs/<op>`
rather than `.duct/logs` limits what `datalad run` unlocks or removes before a rerun to that
operation's own earlier logs. The doubled braces keep `{datetime}` and `{pid}` unexpanded in the
record, so a rerun writes new names and duct's refusal to overwrite never triggers.

*Alternative: a planner-computed timestamp in the prefix.* Rejected: a rerun would reuse the
recorded name, and duct would refuse to overwrite it.

**D4. JSON in git, captured output annexed.** A `.duct/.gitattributes` file carries:

```
logs/**/*_usage.jsonl annex.largefiles=nothing
logs/**/*_info.json   annex.largefiles=nothing
logs/**/*_stdout      annex.largefiles=anything
logs/**/*_stderr      annex.largefiles=anything
```

The JSON is small and diffable, and the cost probe reads it without `datalad get`. Captured output
can be large and may contain data values, so it is annexed and follows the dataset's content
policy. `text2git` alone would put stdout and stderr in git, because they are text. The run
reference writes the file and saves it before the first wrapped run, since `datalad run` needs a
clean tree.

*Alternative: `--capture-outputs none`.* Rejected as a default: stdout and stderr are the first
thing needed when a run's numbers look wrong. It stays available to a user who asks.

**D5. The binding is read from duct, not from a doer.** The wrapped run's commit carries
`DSH-Binding: datalad-cli/duct@<version>`, with the version taken from `duct --version` in the
same session. This is the one `DSH-Binding` that no doer returns, and the `datalad` spec is
amended to say so. The binding keeps the `<doer>/<tool>@<version>` shape by naming the plugin
whose reference prescribes the wrap.

*Alternative: record the version only in `info.json`.* Rejected: `dsh-log` reads bindings, not
log files, and a reader of the history should see which runs were measured.

**D6. Container runs: inside the image, only when the image provides duct.** For
`containers-run` the command string runs inside the container, so `duct` must be in the image.
`analyze/run-comparison` wraps the command only when the environment's pinned manifest lists
`con-duct`; the binding version comes from that pin. Otherwise the run is not wrapped, and the
report says resource usage was not captured.

`process/run-pipeline` is different: it uses plain `datalad run`, and duct on the host wraps the
nipoppy command. Apptainer is a child of that process, so its usage is sampled. Docker is not:
the container runs under the daemon. Scheduler submission (`--hpc`) is never wrapped.

*Alternative: host-side wrap through `--call-fmt`* (registering the container with a call format
that starts with duct). Rejected for now: it changes container registration, applies to every run
of that container, and sees nothing under Docker. Kept as an open question for Apptainer.

**D7. The cost probe reads logs; it does not add them to agent cost.** `compute_usage` is a new
measured metric: peak RSS, CPU time and wall-clock per run commit in a stage, read from committed
`info.json` and `usage.jsonl`. It is reported next to agent cost. A stage whose runs carry no duct
binding reports `compute_usage` as unmeasured.

*Alternative: fold compute wall-clock into the existing `wall_clock` metric.* Rejected: agent time
and compute time overlap and measure different things.

## Risks / Trade-offs

- [The usage file name changed once (`usage.json` → `usage.jsonl`, v0.18.0)] → The
  `.gitattributes` rule and the cost probe name both; the e2e asserts the current name, so a
  future rename fails a test rather than silently annexing JSON.
- [Declared outputs are unlocked before a rerun] → Per-operation directories (D3) bound this. The
  e2e covers a rerun.
- [A failing command under 3 s leaves no logs] → Acceptable: `datalad run` commits nothing on
  failure anyway.
- [stdout may carry sensitive values] → Annexed (D4), so it is governed by the same siblings and
  `datalad drop` rules as other content.
- [Planners drift back into quoting duct] → `duct` and `con-duct` in `PERIPHERAL_BINARIES`.

## Migration Plan

Additive. Existing run commits are untouched and replay unchanged. Rollback is removing the
paragraphs from the two verb references and the two planners; committed logs remain as ordinary
files.

## Open Questions

- Host-side wrapping for Apptainer through `--call-fmt`: worth a registration option, given it
  sees nothing under Docker?
- The concurrent `repronim-containers` change documents ReproNim's `singularity_cmd`, which wraps a
  run in duct when `REPRONIM_USE_DUCT` is set. If both land, a ReproNim image run through that
  launcher is measured on the host, and D6's inside-the-image rule must not wrap it a second time.
- Should `project/new-project`'s environment manifest include `con-duct` by default, so
  `run-comparison` is measured without the user adding it?
- Should `dsh-log` gain a flag that joins a run commit to its `info.json` summary? Deferred until
  the cost probe is run.
