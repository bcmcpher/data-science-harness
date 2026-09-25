## ADDED Requirements

### Requirement: The nipoppy toolbox is checked against the real CLI

`tests/e2e-smoke.sh` MUST contain a live nipoppy section. The section MUST run `init`,
`track-curation` and `status` from the `tests/envs/nipoppy` environment on a fixture dataset, and
MUST assert the files the installed version actually writes. It MUST run whenever that environment
is present and in sync with its lock, and MUST otherwise skip, naming `bin/test-envs sync nipoppy`.
A dataset-mutating command (`bidsify`, `process`) MUST be exercised only with `--simulate`, and
only when apptainer and a pipeline bundle are available.

#### Scenario: The environment is synced

- **WHEN** `tests/envs/nipoppy/.venv` matches its lock and the e2e runs
- **THEN** `init`, `track-curation` and `status` run against the fixture, and a failure is reported
  as a failing assertion rather than a skip

#### Scenario: No apptainer

- **WHEN** the environment is synced but apptainer is absent
- **THEN** the setup and bookkeeping checks run, and the compute check skips with the reason

### Requirement: The nipoppy toolbox agrees with the tested version

The file names, directory layout, subcommands and flags that `plugins/nipoppy-cli/` and the nipoppy
doer state MUST match the version pinned in `tests/envs/nipoppy`. When the live section shows a
disagreement, the skill, its reference and the doer MUST be corrected in the same change that
observes it.

#### Scenario: The configuration file name differs

- **WHEN** `nipoppy init` in the pinned version writes `global_config.json`
- **THEN** the doer's state check and every reference that names `config.json` are corrected to the
  name the tool writes
