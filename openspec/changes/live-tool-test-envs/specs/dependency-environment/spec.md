## ADDED Requirements

### Requirement: Each wrapped tool under live test has its own locked environment

A tool that a doer wraps and that the repository tests live MUST be declared in its own uv project
at `tests/envs/<tool>/pyproject.toml`, with a committed `uv.lock`. That project MUST pin the tool
with `==`. The tool MUST NOT also be declared in `pyproject.toml`, `package.json` or
`environment.yml`. The environment's venv MUST NOT be committed.

These environments are test fixtures for the harness's toolboxes. They are not a dependency of the
check scripts, and they are not something a consumer of the harness installs.

#### Scenario: A new tool is brought under live test

- **WHEN** a change adds a live e2e section for a wrapped tool
- **THEN** it adds `tests/envs/<tool>/pyproject.toml` and its `uv.lock` in the same change, and
  does not add the tool to a root manifest

#### Scenario: A tool version is bumped

- **WHEN** the tested version of a wrapped tool changes
- **THEN** the `==` pin and the `uv.lock` for that tool change in one diff, and no other tool's lock
  changes

### Requirement: Test environments are synced from their locks and never re-resolved implicitly

`bin/test-envs sync [tool]` MUST install each environment with `uv sync --locked`, and MUST print
each tool's runtime version. `bin/test-envs check [tool]` MUST report each environment as `ok`,
`missing` or `stale` without modifying it. It MUST exit 0 only when every named environment is
`ok`, and MUST exit 2 for an unknown tool. The e2e MUST NOT install or re-resolve an environment.

#### Scenario: The lock moved since the last sync

- **WHEN** a contributor pulls a changed `tests/envs/bagel/uv.lock` and runs `bin/test-envs check`
- **THEN** `bagel` is reported `stale`, the command exits 1, and nothing is installed

#### Scenario: The e2e meets a missing environment

- **WHEN** `tests/e2e-smoke.sh` reaches a live section whose environment is missing or stale
- **THEN** the section prints `SKIP:` with the `bin/test-envs sync <tool>` command, and the run
  continues

### Requirement: The setup documentation covers the test environments

The README MUST document `bin/test-envs`, which tools it provides, and which e2e sections each one
enables.

#### Scenario: A contributor wants the live checks

- **WHEN** someone follows the README's setup section
- **THEN** they can sync every test environment with one documented command and see which e2e
  sections now run
