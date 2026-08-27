# datalad

## Purpose

The capability-plane wrapper over DataLad and git-annex. DataLad is the harness's connective tissue:
every computation goes through `datalad run` or `datalad container-run`, and every administrative
change is `datalad save`-d, so neither the analysis chain nor the administrative record is ever
broken. This capability is the reference shape for the whole plane — one doer agent
(`plugins/datalad/agents/datalad-doer.md`) plus a vendored `datalad-cli` toolbox of one skill per
CLI verb. Its behaviour is exercised end to end by `tests/e2e-smoke.sh`.

## Requirements

### Requirement: The datalad doer is the only executor of DataLad commands

Planner skills MUST NOT invoke the DataLad CLI. Any dataset creation, provenanced run, save, status
or log inspection, sibling operation, push, or `get` MUST be delegated to the datalad doer, which
owns the mechanics.

#### Scenario: A planner needs to record a result

- **WHEN** any workflow-plane skill reaches the point of committing a change
- **THEN** it delegates to the datalad doer with a plain-language request rather than constructing a
  command itself

### Requirement: The toolbox provides one user-invocable skill per CLI verb

`plugins/datalad-cli/` MUST provide a skill per DataLad verb the harness relies on, each
`user-invocable: true` with an `argument-hint`, and each scoping `allowed-tools` to what that verb
needs. The doer MUST read the matching skill and follow its steps and constraints rather than
improvising the invocation.

#### Scenario: The doer is asked to push to a sibling

- **WHEN** the doer receives a push request
- **THEN** it consults the `datalad-push` skill and constructs the command from that skill's rules

#### Scenario: A user drives a verb directly

- **WHEN** a user invokes a `datalad-*` skill themselves without a planner
- **THEN** the skill runs standalone, because toolbox skills are usable on their own

### Requirement: Provenanced execution is the default run path

The doer MUST execute analysis commands through `datalad run` or `datalad container-run` with
explicit inputs, outputs, and a non-empty message, so the result is replayable by `datalad rerun`.
It MUST NOT run an analysis bare and save the result afterwards.

#### Scenario: A comparison is executed

- **WHEN** a run is requested with inputs and outputs
- **THEN** the resulting commit records the command, its inputs, and its outputs, and `datalad rerun`
  reproduces it

#### Scenario: Message or paths are missing

- **WHEN** a required parameter such as the commit message or an output path is absent or ambiguous
- **THEN** the doer asks the delegating planner rather than guessing a message or inventing a path

### Requirement: The doer refuses to run against a dirty tree

The doer MUST verify a clean working tree before `run` or `container-run`, and MUST verify a DataLad
context exists before operating on a directory.

#### Scenario: Uncommitted changes are present

- **WHEN** a run is requested while `datalad status` reports modifications
- **THEN** the doer stops and asks for a save or confirmation instead of running

### Requirement: Container runs use a registered container

The doer MUST NOT call `datalad container-run` with an unregistered container. It MUST verify
registration with `datalad containers-list` and register with `containers-add` when needed, so the
container image's annex key is recorded in the run commit.

#### Scenario: A provenanced container run

- **WHEN** an analysis is run inside a registered container
- **THEN** the run commit annotates the image's annex key, and a later `datalad rerun` re-fetches
  that exact image

### Requirement: Every operation returns a structured result

The doer MUST report `op`, the exact command executed, `result` (`ok` or `failed`), and where
applicable the commit, outputs, and ending branch, plus notes on tree state or next steps. It MUST
show a constructed command before executing anything that writes to the dataset.

#### Scenario: An operation fails

- **WHEN** a DataLad command returns non-zero
- **THEN** the doer commits nothing further, surfaces the error, and returns `result: failed` with a
  suggested fix rather than leaving outputs half-written

### Requirement: The doer makes no research decisions

The doer MUST NOT decide which analysis to run, whether to promote a comparison, or how to version a
release. It executes and reports; the planner decides.

#### Scenario: An ambiguous request arrives

- **WHEN** the request implies a research choice rather than a mechanical one
- **THEN** the doer returns the question to the planner instead of choosing

### Requirement: Datasets are distributable

A dataset produced through this capability MUST be pushable to a sibling and independently
cloneable, and annexed content MUST be retrievable in the clone with `datalad get`.

#### Scenario: Distributability check

- **WHEN** a dataset is pushed to a sibling and cloned into a fresh location
- **THEN** the clone's history matches and `datalad get` retrieves the annexed file content
