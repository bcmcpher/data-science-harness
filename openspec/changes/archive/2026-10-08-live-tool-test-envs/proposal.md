## Why

The README's status line says it plainly: **most paths have never been run against their real
tool.** The doers for nipoppy and annotate wrap ReproNim-ecosystem tools (nipoppy, Neurobagel's
`bagel`, PyNIDM, ReproSchema), and their toolbox skills were written from documentation. Nothing in
the repository installs those tools, so nothing checks that the flags, file names and subcommands
the skills teach are the ones the tools accept. In `tests/e2e-smoke.sh`, the annotate section runs
`bagel` only if one happens to be on `PATH`. PyNIDM and ReproSchema are reached only through
`plugins/annotate-cli/scripts/check-backends.sh`, which reports presence and never runs them. No
nipoppy test exists at all.

A read-only probe on 2026-09-25 shows the gap is real. The probe used a nipoppy 0.4.5 found on
this machine, and the Neurobagel CLI documentation:

- `nipoppy init` in 0.4.5 writes `global_config.json`, not the `config.json` that the doer checks
  for before every command.
- `nipoppy track-curation` has no `--participant-id` or `--session-id` in 0.4.5.
- The Neurobagel docs install the CLI as `pip install bagel`, not `bagel-cli`.
- `bagel pheno` takes `--dataset-description`, not the `--name` the skill and the e2e pass.
- `bagel bids` takes `--bids-table`, not `--bids-dir`.

The e2e's `bagel pheno` assertion ("rejects a dictionary with no Annotations") would pass on a
usage error for `--name`. That is the right exit code for the wrong reason.

The user is part of the ReproNim collaboration and wants the doers tested against ReproNim tools.
That needs the tools installed reproducibly, one version each, without leaking into the
repository's own check toolchain.

## What Changes

- **One uv project per wrapped tool**:
  - Each lives at `tests/envs/<tool>/`, as a `pyproject.toml` with a committed `uv.lock`.
  - Its venv at `tests/envs/<tool>/.venv/` is already gitignored by the existing `.venv/` pattern.
  - First round: `nipoppy`, `bagel`, `pynidm`, `reproschema`.
  - Later changes add `heudiconv`, `neurodocker` and `con-duct` the same way. `repronim-containers`
    adds `neurodocker`.
- **`bin/test-envs sync|check [tool]`**:
  - `sync` runs `uv sync --locked --project tests/envs/<tool>` and prints each tool's runtime
    `--version`.
  - `check` reports each env as `ok`, `missing` or `stale` without changing anything.
  - With no tool named, both act on every directory under `tests/envs/`.
- **An e2e helper, `tool_env <name> <cmd…>`.** It runs a command in a subshell with
  `tests/envs/<name>/.venv/bin` first on `PATH`. When the env is absent or stale, the calling
  section skips with `SKIP: run bin/test-envs sync <name>`.
- **Live e2e sections**:
  - **nipoppy**: `init`, then `track-curation`, then `status` on a one-participant fixture
    manifest.
  - **nipoppy compute**: `bidsify` / `process` with `--simulate`, only when apptainer and a
    pipeline bundle with its image are present.
  - **bagel**: `pheno` on a fixture dictionary that carries real Neurobagel annotations, plus the
    existing refusal of an unannotated one, now checked to fail for the right reason.
  - **pynidm**: `bidsmri2nidm` on a one-subject BIDS fixture.
  - **reproschema**: `validate` on a minimal protocol fixture.
- **A refinement loop.** Where the real tool disagrees with a toolbox skill (flags, file names,
  versions, subcommands), the skill and its doer are fixed in this change. Each fix is recorded in
  `design.md` under "Refinements found".
- **Docs.** The README's setup section documents `bin/test-envs`, and `environment.yml` and
  `pyproject.toml` name the new manifests among their siblings.

**Not in this change:** heudiconv, neurodocker (see `repronim-containers`), con-duct, network
fetches, and running a real pipeline. CI stays as it is: the e2e job remains dispatch-only, and
adding `bin/test-envs sync` to it is task 6.3, gated on runner time.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `dependency-environment`: per-tool test environments, one locked uv project per wrapped tool,
  separate from the repository's check toolchain.
- `nipoppy`: a live check against the real CLI exists and runs when its environment is present.
- `annotate`: live checks for `bagel`, `pynidm` and `reproschema` exist and run when their
  environments are present.

## Impact

- New: `tests/envs/{nipoppy,bagel,pynidm,reproschema}/{pyproject.toml,uv.lock}`, `bin/test-envs`,
  and fixtures under `tests/fixtures/live/`.
- `tests/e2e-smoke.sh`: the `tool_env` helper, a new nipoppy section, and a rewritten annotate
  tool block (around lines 870–885).
- Changed where the tools disagree:
  - `plugins/nipoppy-cli/references/*.md` and `plugins/nipoppy-cli/skills/*/SKILL.md`
  - `plugins/nipoppy/agents/nipoppy-doer.md`
  - `plugins/annotate-cli/skills/{bagel-cli,pynidm,reproschema}/SKILL.md`
  - the `enable:` lines in `plugins/annotate-cli/scripts/check-backends.sh`
  - `plugins/annotate/agents/annotate-doer.md`
- `README.md` (setup), and the sibling-manifest comments in `pyproject.toml` and `environment.yml`.
- No change to plugin or skill counts.
- **Depended on by** `repronim-containers`.
