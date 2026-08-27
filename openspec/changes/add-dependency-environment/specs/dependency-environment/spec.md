## ADDED Requirements

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
