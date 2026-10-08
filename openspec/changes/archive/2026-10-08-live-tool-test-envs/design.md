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

Pins as locked on 2026-10-01: `nipoppy==0.4.7`, `bagel==0.11.6`, `pynidm==4.5.5`,
`reproschema==1.1.0`. nipoppy moved on from the 0.4.5 the Context probe used, so every nipoppy row
there is re-checked against 0.4.7 in task 5.2. PyPI has no `bagel-cli`; `bagel` is the Neurobagel
CLI. One floor departs from the tool's own: pynidm declares `>=3.8`, but at that floor uv forks the
resolution and picks `prov` 2.x for 3.8-3.9, which has no `graph` extra (266 packages, with
warnings). The repository's own floor, `>=3.10`, leaves one resolution with `prov` 3.2.2 (153
packages).

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

**D7. Network-bound tools are gated on `DSH_NET=1`, introduced here.** Running the fixtures with no
network (`unshare -rn`, loopback up) on 2026-10-01 showed that two of the tools cannot work offline:

| Tool@version | Offline | Why |
|---|---|---|
| pynidm 4.5.5 `bidsmri2nidm -no_concepts` | runs | — |
| bagel 0.11.6 `pheno` | fails: `'Neurobagel' is not one of .` | It fetches `config_namespace_map.json` from GitHub. Its fallback, `bagel/communities/`, is a git submodule that is not in the PyPI wheel. |
| reproschema 1.1.0 `validate` | hangs until the timeout | It fetches the ReproSchema schema from `raw.githubusercontent.com`. |

The bagel and reproschema sections therefore also require `DSH_NET=1`, and without it they print
`SKIP: … needs network — set DSH_NET=1`. nipoppy and pynidm run whenever their env is ready. Every
live call runs under `timeout`, so an outage fails fast instead of hanging. `repronim-containers`
reuses this gate rather than introducing it. This revises the Non-Goal above: there is still no
fetch in the default run.

*Alternative: treat a synced env as consent to network.* Rejected. The default run should behave
the same on a plane as on a desk.
*Alternative: vendor the upstream configs and contexts into the fixtures.* Rejected. bagel has no
flag for a local config, so this would mean writing into the env's site-packages, and the test
would then check the vendored copy rather than what a user's install does.

## Refinements found

_Filled in during task 5, 2026-10-08, from live runs and `--help` in the locked envs._

| Tool@version | What the skill said | What the tool does | Files changed |
|---|---|---|---|
| nipoppy@0.4.7 | dataset config is `config.json` | `global_config.json`; `~/.nipoppy/config.json` is user-level; pipelines have their own `pipelines/<type>/<name>-<version>/config.json` | nipoppy-cli references + skills, `nipoppy-doer.md` |
| nipoppy@0.4.7 | config keys `DATASET_NAME`, `VISITS`, `SESSIONS`, `BIDS_CONVERTER`, `PROC_PIPELINES`, `CONTAINER` | keys `SUBSTITUTIONS`, `DICOM_DIR_PARTICIPANT_FIRST`, `CONTAINER_CONFIG`, `HPC_PREAMBLE`, `PIPELINE_VARIABLES`, `CUSTOM`, `SCHEMA_VERSION`; image from pipeline `CONTAINER_INFO.FILE` | `workflow-overview.md`, `setup-commands.md`, `bids-commands.md`, `nipoppy-compute`, doer |
| nipoppy@0.4.7 | layout has `proc/logs/`; status files in `tabular/` | no `proc/`; `init` writes `.nipoppy/`, `logs/`, `pipelines/{bidsification,processing,extraction}/`, `containers/`, `code/hpc/`, `scratch/`, `sourcedata/{imaging,tabular}/`, `tabular/assessments/`; `tabular/` is phenotypic only | `setup-commands.md`, `workflow-overview.md` |
| nipoppy@0.4.7 | curation status `tabular/curation_status.tsv` (`has_*_data` columns), made by `init` | `sourcedata/imaging/curation_status.tsv`, columns `participant_id`…`in_pre_reorg`, `in_post_reorg`, `in_bids`; first `track-curation` creates it | `curation-commands.md`, `bids-commands.md`, `nipoppy-track` |
| nipoppy@0.4.7 | processing status `tabular/bagel.tsv` | `derivatives/processing_status.tsv` with `pipeline_name`, `pipeline_version`, `pipeline_step`, `status` | `track-extract-commands.md`, `process-command.md`, `setup-commands.md`, `workflow-overview.md`, `nipoppy-track`, nipoppy-cli `README.md` |
| nipoppy@0.4.7 | `track-curation --participant-id/--session-id` | no filters: `--dataset`, `--empty`, `--regenerate`, `--layout`, `--dry-run`, `-v` | `curation-commands.md` |
| nipoppy@0.4.7 | `status --verbose` gives per-participant detail | `--verbose` is DEBUG logging; output is always aggregate counts | `setup-commands.md` |
| nipoppy@0.4.7 | `reorg --participant-id/--session-id/--simulate`, `--layout` a heuristic | `reorg` takes `--copy-files`, `--check-dicoms`, `--dry-run`, `--layout` (JSON spec); mapping via `DICOM_DIR_*` in `global_config.json` | `curation-commands.md` |
| nipoppy@0.4.7 | `nipoppy init <path>` | positional path is a usage error; `init --dataset <path>` | `setup-commands.md` |
| nipoppy@0.4.7 | `--simulate` only prints | still needs apptainer, the image file, and eligible rows (`in_bids` for process) | `process-command.md`, `bids-commands.md`, `workflow-overview.md`, `nipoppy-compute` |
| nipoppy@0.4.7 | logs under `proc/logs/<pipeline>/` | `logs/<workflow>/<name>-<version>/`; `logs/track_curation/` | doer, `nipoppy-compute`, `nipoppy-track` |
| nipoppy@0.4.7 | omitting `--pipeline` may fan out | `--pipeline` required; version defaults to latest installed, step to first | doer, `nipoppy-track` |
| nipoppy@0.4.7 | doer: use nipoppy's manifest workflow; manifest columns `visit`/`session` | no command writes the manifest; columns `visit_id`/`session_id`, `datatype` a list | doer, `workflow-overview.md` |
| bagel@0.11.6 | `pip install bagel-cli` | PyPI package is `bagel` | `check-backends.sh`, `annotate-doer.md` |
| bagel@0.11.6 | `pheno --name <dataset name>` | no `--name`; `--dataset-description/-m <json>` required, label from its `Name` | bagel-cli `SKILL.md` |
| bagel@0.11.6 | `pheno --output <dir-or-file>`; silent on network | one `.jsonld` file, exits 1 if present without `--overwrite`; fetches vocab configs at start-up, fails offline | bagel-cli `SKILL.md`, `check-backends.sh` header, doer |
| bagel@0.11.6 | `bids --bids-dir <dir>` | `bids --bids-table <tsv>` from `bids2tsv --bids-dir`; needs `BIDSVersion`; `--strip-id-prefixes` | bagel-cli `SKILL.md` |
| pynidm@4.5.5 | `pynidm --version` | no such option (exit 2); `pynidm version` subcommand or package metadata | pynidm `SKILL.md`, `annotate-doer.md` |
| pynidm@4.5.5 | `csv2nidm` runs unattended | crashes (`TypeError … dataset_identifier`) without `-no_concepts` | pynidm `SKILL.md` |
| pynidm@4.5.5 | `bidsmri2nidm -d -o` runs unattended | prompts on stdin without `-no_concepts`, and per column without a `participants.json` sidecar; `EOFError` with stdin closed | pynidm `SKILL.md` |
| pynidm@4.5.5 | `pynidm query -nl <ttl> -u <query or uri>` | `-nl` is a comma list; exactly one of `-q -p -i -iv -de -debv -bv -gf -u`; `-u` is REST-style; `-de` empty on `-no_concepts` output | pynidm `SKILL.md` |
| reproschema@1.1.0 | `validate`, no hang warning | an `@id`/file-name mismatch leaves the local server running and never exits; wrap in `timeout` | reproschema `SKILL.md` |
| reproschema@1.1.0 | validation failure means the tool worked | models have no required fields; only wrong types and `@id` mismatches fail | reproschema `SKILL.md` |
| reproschema@1.1.0 | `convert --format <from --help>` | `jsonld`, `n-triples` (default), `turtle`; one document to stdout | reproschema `SKILL.md` |
| reproschema@1.1.0 | `redcap2reproschema` may want a YAML config; `reproschema2redcap <file>` | YAML is a required positional (`protocol_name`, `protocol_display_name`, `source_version`); output `<out>/<protocol_name>/` without `.jsonld`; `reproschema2redcap` takes the protocol dir; round trip is exact | reproschema `SKILL.md` |

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
  **Settled (task 5.4): runtime `--version`, falling back to the package metadata
  (`importlib.metadata.version`) when the CLI has no `--version`.** Of the four, only pynidm 4.5.5
  lacks it (its `pynidm version` subcommand prints the version instead); reproschema 1.1.0 has it,
  contrary to an earlier note. `bin/test-envs` already falls back; the annotate doer's `version:`
  line now says so.
- **When an env exists but is stale, does the e2e fail or skip?** **Default: skip**, with the
  reason from `bin/test-envs check` (`SKIP: nipoppy env stale — run bin/test-envs sync nipoppy`). A
  stale env means the lock moved and the developer has not re-synced. That is a setup state, not
  a harness defect. The alternative, failing, would make a lock bump break every contributor's
  next e2e run until they re-sync.
- Whether the dispatch-only e2e CI job should run `bin/test-envs sync` for all four tools, given
  runner time. Task 6.3 measures the time and decides.
  **Settled (task 6.3): yes.** With an empty uv cache all four synced in ~15 s (~820 MB), measured
  locally 2026-10-08. The e2e job runs `bin/test-envs sync` and sets `DSH_NET=1`.
