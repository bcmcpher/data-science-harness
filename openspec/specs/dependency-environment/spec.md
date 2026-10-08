# dependency-environment Specification

## Purpose

What the repository needs in order to check and build *itself*, declared in committed manifests
rather than assumed to be on a developer's machine. Three toolchains, one owning manifest each:
`pyproject.toml` for the Python checks, `package.json` for the Node CLIs, `environment.yml` for the
end-to-end stack. The first two carry lock files; the third says in the file why it does not.
STAMPED P.2 and P.3 ask that computational environments be explicitly specified and version
controlled, and it would be odd to ask that of users and not of ourselves. This spec covers the
repository's own tooling — what a *consumer* of the harness content needs is nothing, which is
`harness-distribution`'s concern.
## Requirements
### Requirement: Every tool the repository depends on is declared in a manifest

Each toolchain the repository requires MUST be declared in a committed manifest. No check script,
test, or build step may rely on a tool that is present only by convention on a developer's machine.

#### Scenario: A check script gains a dependency

- **WHEN** a script under `tests/` or `schemas/` imports a third-party module
- **THEN** that module appears in `pyproject.toml`, and the lock file is regenerated in the same change

#### Scenario: A build step gains a CLI

- **WHEN** a documented workflow requires a command-line tool
- **THEN** that tool is declared in the manifest owning its toolchain, and the documented invocation
  resolves it from there

### Requirement: Each toolchain has one owning manifest

The Python checks MUST be owned by `pyproject.toml`, the Node CLIs by `package.json`, and the
end-to-end stack by `environment.yml`. A dependency MUST NOT be declared in more than one.

#### Scenario: A contributor adds a dependency

- **WHEN** a new dependency is needed
- **THEN** exactly one manifest declares it, chosen by which toolchain provides it

### Requirement: Locked toolchains are locked, and unlocked ones say why

`pyproject.toml` and `package.json` MUST have committed lock files pinning a resolved version set.
A manifest without a lock file MUST state in the file why it is unlocked.

#### Scenario: Reproducing the Python checks

- **WHEN** a contributor syncs from the lock file
- **THEN** they obtain the same resolved versions the checks were last exercised against

#### Scenario: The e2e stack

- **WHEN** `environment.yml` is read
- **THEN** it states that it is deliberately unlocked and why, rather than leaving the omission to be
  inferred

### Requirement: CI installs from the manifests

`.github/workflows/ci.yml` MUST install every dependency from a committed manifest and MUST NOT
install a floating version specifier inline.

#### Scenario: A CI job needs a tool

- **WHEN** a workflow step requires a dependency
- **THEN** it installs from the lock file, so a green run corresponds to a recorded version set

#### Scenario: An upstream release breaks a check

- **WHEN** a dependency publishes a breaking version
- **THEN** CI is unaffected until the lock file is updated, and that update is a reviewable diff

### Requirement: The harness content itself stays dependency-free

Skills, agents, references, and manifests under `plugins/` MUST remain plain Markdown and JSON. The
manifests added here pin the tooling that checks and builds the repository, not anything a consumer
of the harness content needs.

#### Scenario: Installing the harness

- **WHEN** a user installs plugins with `bin/install.sh`
- **THEN** no Python or Node dependency is required, because the installer is a shell file copier

### Requirement: A fresh clone has one documented path to a passing check run

The README MUST document how to obtain each toolchain and which commands each one enables.

#### Scenario: A new contributor

- **WHEN** someone clones the repository and follows the documented setup
- **THEN** the structural lint, the selftest, the ledger validator, the fixture check, and
  `openspec validate` all run

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
`ok`, and MUST exit 2 for an unknown tool. `check --quiet` MUST report the same states without
launching any tool's CLI, and the e2e gate MUST use it. The e2e MUST NOT install or re-resolve an
environment.

#### Scenario: The lock moved since the last sync

- **WHEN** a contributor pulls a changed `tests/envs/bagel/uv.lock` and runs `bin/test-envs check`
- **THEN** `bagel` is reported `stale`, the command exits 1, and nothing is installed

#### Scenario: The e2e meets a missing environment

- **WHEN** `tests/e2e-smoke.sh` reaches a live section whose environment is missing or stale
- **THEN** the section prints `SKIP:` with the `bin/test-envs sync <tool>` command, and the run
  continues (bagel alone may instead run an install found on `PATH`; see the annotate spec)

### Requirement: The setup documentation covers the test environments

The README MUST document `bin/test-envs`, which tools it provides, and which e2e sections each one
enables.

#### Scenario: A contributor wants the live checks

- **WHEN** someone follows the README's setup section
- **THEN** they can sync every test environment with one documented command and see which e2e
  sections now run

