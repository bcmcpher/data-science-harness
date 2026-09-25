## Context

Three toolchains are declared today, one owning manifest each (`openspec/specs/dependency-environment/spec.md`):

- `pyproject.toml` + `uv.lock` for the Python checks;
- `package.json` + `package-lock.json` for the Node CLIs;
- `environment.yml` for the e2e stack (DataLad, git-annex, datalad-container), which is
  deliberately unlocked.

None of them contains a tool a doer wraps. `check-backends.sh` names `pip install bagel-cli`,
`pip install pynidm` and `pip install reproschema` as the way to enable each annotate backend. So
whether a live check runs depends on what a developer happened to install.

The tools do not belong in `pyproject.toml`'s groups. They pull heavy and mutually unrelated
dependency trees. The local nipoppy 0.4.5 install alone carries pydantic, boutiques, pybids and
bids-validator, and pynidm and bagel each bring their own. Resolving them together with the check scripts couples four upstream
release schedules to the lint's lock file. They are also not what the checks need, which is the
line `pyproject.toml`'s own header draws.

**What the tools look like today.** This is evidence gathered on 2026-09-25, before any env
existed. None of it has been checked against a locked version yet.

| Tool | Source | Finding | Skill says |
|---|---|---|---|
| nipoppy 0.4.5 | `nipoppy --help`, `nipoppy init` into a temp dir (existing conda env, read-only probe) | `init` writes `global_config.json`, `manifest.tsv`, `pipelines/{bidsification,processing,extraction}/`, `containers/`, `logs/`, `code/hpc/`, `sourcedata/{imaging,tabular}/`; no `tabular/`, no `proc/logs/` | `config.json`, `tabular/curation_status.tsv`, `proc/logs/` |
| nipoppy 0.4.5 | `track-curation --help` | `--dataset`, `--empty`, `--force/--regenerate`, `--layout`, `--dry-run`; no participant or session filter | `--participant-id`, `--session-id` |
| nipoppy 0.4.5 | `status --help` | `--dataset`, `--layout`, `--verbose` (DEBUG logging), `--dry-run` | `--verbose` = per-participant detail |
| nipoppy 0.4.5 | `process --help`, `bidsify --help` | `--simulate`, `--dry-run`, `--pipeline-version`, `--pipeline-step`, `--participant-id`, `--session-id`, `--hpc`, `--tar` (process), `--keep-workdir` | consistent |
| bagel | neurobagel.org/user_guide/cli | package `bagel`; `pheno --pheno --dictionary --dataset-description --output`; `bids --jsonld-path --bids-table --output`; `derivatives --jsonld-path --tabular --output` | package `bagel-cli`; `pheno --name`; `bids --bids-dir` |
| pynidm | not reached (PyPI and GitHub README fetches failed) | **unverified**: `bidsmri2nidm -d <bids> -o <ttl>` and `pynidm query` | as in skill |
| reproschema | PyPI README (no CLI listing) | **unverified**: `reproschema validate <path>` and the `convert`, `redcap2reproschema`, `reproschema2redcap` subcommand names | as in skill |
| neurobagel `pheno` in e2e | `tests/e2e-smoke.sh:883` passes `--name` | under the documented CLI this is a usage error, so "rejects an unannotated dictionary" passes for the wrong reason | — |

## Goals / Non-Goals

**Goals:**
- Each wrapped tool installs at one recorded version, reproducibly, with one command.
- The e2e runs each tool for real when its env exists, and says how to get it when it does not.
- Every disagreement between a real tool and its toolbox skill is fixed and written down.

**Non-Goals:**
- Running a real pipeline. `process` and `bidsify` are exercised only through `--simulate`, and
  only when apptainer and a pipeline bundle are present.
- Network access in the default run. No section fetches unless `DSH_NET=1`, the gate that
  `repronim-containers` introduces.
- Replacing `environment.yml` or merging these envs into it. The e2e stack stays the conda
  environment it is.
- Doer behaviour evaluation. This tests the command lines the toolboxes teach, not the agents.

## Decisions

**D1. One uv project per tool, under `tests/envs/<tool>/`.** Each project has
`[tool.uv] package = false`, a `requires-python` floor taken from the tool, and one direct
dependency pinned with `==`. The `==` makes the version under test visible in review, and the
committed `uv.lock` pins the rest. `bin/test-envs sync` always passes `--locked`, so a sync never
re-resolves. A version bump is `uv lock --project tests/envs/<tool> --upgrade-package <pkg>`
together with an edit to the `==`: one reviewable diff that then drives the refinement loop.

*Alternative: dependency groups in the root `pyproject.toml` (`test-nipoppy`, …).* Rejected. One
`uv.lock` resolves all groups together, so one tool's pin can force another's downgrade, and a bump
to `bagel` rewrites the lint's lock file.

*Alternative: conda envs.* Rejected. The tools are pure-Python on PyPI, and conda envs cannot be
locked cheaply per platform. `environment.yml` already records that trade-off.

**D2. `bin/test-envs` is a thin shell script over `uv`, with no Python dependency of its own.**

- `sync [tool]` runs `uv sync --locked --project tests/envs/<tool>`, then prints
  `<tool>: <runtime --version>` using the env's own binary.
- `check [tool]` prints one line per env: `ok <version>`, `missing` (no `.venv`), or `stale`
  (`uv sync --locked --check` reports that the env differs from the lock). It exits 0 when every
  named env is `ok`, and 1 otherwise.
- An unknown tool is a usage error (exit 2), matching the gate-script contract the toolboxes use.

*Alternative: `uv run --project … <cmd>` inside the e2e.* Rejected. `uv run` syncs on first use,
so a test run would silently install or re-resolve, which is a side effect the e2e must not have.

**D3. `tool_env` puts the venv's `bin/` first on `PATH` in a subshell.** It does not activate the
env. `check-backends.sh` detects pynidm and reproschema with `python3 -c 'import …'`, and a uv venv
ships a `python3` link, so the existing gate scripts see the tool without modification. The
subshell keeps the change of `PATH` from leaking into later sections, which use the conda env's
`python3`.

*Alternative: call `tests/envs/<tool>/.venv/bin/<cmd>` by absolute path.* Rejected. That exercises
the command but not the gate scripts. The gates are what the doers run first, so testing them
through `PATH` is the point.

**D4. Fixtures are small, committed, and sourced.** They live in `tests/fixtures/live/`:

- a one-row nipoppy `manifest.tsv`;
- a one-subject BIDS tree whose one-voxel NIfTI-1 file is written at test time by a few lines of
  standard-library Python (a 348-byte header plus data), so no binary is committed and no imaging
  library becomes a test dependency;
- a minimal ReproSchema protocol, with one activity and one item;
- a Neurobagel-annotated `participants.json`.

The annotated dictionary is copied from Neurobagel's published example data, with its source and
licence recorded beside it. Writing term identifiers by hand would be the recall the annotate spec
forbids, even in a fixture.

*Alternative: annotate the e2e's own `participants.json` inline.* Rejected for the same reason.

**D5. The e2e scaffold is not reused for nipoppy.** `nipoppy init` wants to own its layout, and
the scaffold is a YODA dataset. The nipoppy section runs `init --dataset` in a fresh directory
under `$WORKDIR`. It does not assert anything about how a nipoppy dataset nests inside a DataLad
superdataset, which is `curate/raw-to-bids`'s concern and out of scope.

**D6. Refinements are fixed here, not deferred.** Every mismatch the live runs surface is fixed in
the skill, its reference and the doer, in this change. Each one is logged below with the tool
version it was checked against. A mismatch left unfixed would be a known-wrong instruction in a
toolbox, which is worse than an untested one.

## Refinements found

_Filled in during implementation (task 5). One row per fix._

| Tool@version | What the skill said | What the tool does | Files changed |
|---|---|---|---|

## Risks / Trade-offs

- [Upstream moves faster than the locks.] → That is the point of the locks. A bump is a deliberate
  diff that re-runs the refinement loop, and nothing drifts silently.
- [Four venvs cost disk space and sync time.] → They are opt-in. The e2e skips cleanly without
  them, and CI does not build them on push.
- [A hand-written NIfTI header is rejected by pynidm's reader.] → Then the fixture is at fault, not
  the skill. Fix the writer, and record the case in "Refinements found" only if the skill's
  instructions also change.
- [A fixture copied from Neurobagel drifts from their current schema.] → `bagel pheno` validates
  it, so drift shows as a failing assertion rather than as a silent pass.

## Migration Plan

Additive. Removing `tests/envs/`, `bin/test-envs` and the new e2e sections restores the current
state. Skill fixes stand on their own, because each is a correction.

## Open Questions

- **What does `DSH-Binding` record?** The options are the version from the env's lock file or the
  tool's runtime `--version`. **Default: runtime `--version`.** It is what the doers already
  report (`binding: nipoppy/…@<version>` "from config.json / `nipoppy --version`"). It is also the
  only source a user's own install has. In a harness test the two should agree, and `bin/test-envs
  sync` prints the runtime value so a disagreement is visible.
- **When an env exists but is stale, does the e2e fail or skip?** **Default: skip**, with the
  reason from `bin/test-envs check` (`SKIP: nipoppy env stale — run bin/test-envs sync nipoppy`). A
  stale env means the lock moved and the developer has not re-synced. That is a setup state, not
  a harness defect. The alternative, failing, would make a lock bump break every contributor's
  next e2e run until they re-sync.
- Whether the dispatch-only e2e CI job should run `bin/test-envs sync` for all four tools, given
  runner time. Task 6.3 measures the time and decides.
