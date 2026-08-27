# analyze

## Purpose

The workflow-plane plugin implementing the comparison model — the harness's answer to the fact that
real papers are a series of small analyses introduced in unpredictable order, not a rigid pipeline.
A comparison is one lightweight, addable unit realized as a DataLad branch plus a provenanced run.
It sits on a rigor spectrum: an exploratory query has zero ledger footprint and can be discarded
freely, while a confirmatory one is frozen by `govern/preregister` first. Kept comparisons are
grouped into products. Provides `propose-comparison`, `run-comparison`, `manage-product`, and
`checkpoint`.

## Requirements

### Requirement: A comparison is a branch plus a record, not a pipeline stage

`analyze/propose-comparison` MUST capture what is being compared and why, its inputs and expected
outputs, and its rigor mode, then create a clearly named `cmp/*` branch through the datalad doer.
A comparison MUST be introducible at any point in the project.

#### Scenario: A new analysis is proposed

- **WHEN** a user asks to look at one variable against another
- **THEN** a `cmp/*` branch exists for it and the proposal is recorded

#### Scenario: The bar to propose is low

- **WHEN** the user gives only a one-line description of an exploratory query
- **THEN** the comparison is created without demanding a full analysis plan

### Requirement: Exploratory comparisons have no ledger footprint

An exploratory comparison MUST live only as a branch and its run. It MUST NOT be written into
`project.yaml` `products[]` unless and until it is promoted.

#### Scenario: An exploratory query is discarded

- **WHEN** a quick comparison does not tell the story
- **THEN** the branch can be pruned and the ledger is unchanged by its existence

#### Scenario: An exploratory query is kept

- **WHEN** a comparison is worth publishing
- **THEN** it touches the ledger for the first time by being grouped into a product

### Requirement: Confirmatory comparisons are checked against their frozen spec

A comparison whose rigor mode is confirmatory MUST have been registered by `govern/preregister`
before execution, and its result MUST be checked against the registered spec.

#### Scenario: A registered comparison is executed

- **WHEN** a confirmatory comparison completes
- **THEN** its corresponding obligation moves to met, and any deviation from the frozen spec is
  recorded and reportable

### Requirement: Comparisons execute with full provenance inside the project container

`analyze/run-comparison` MUST confirm it is on the comparison's branch, gather the run's inputs,
outputs, and message, ensure the container image exists via the containers doer, and delegate
execution to the datalad doer as a `container-run`.

#### Scenario: A comparison is run

- **WHEN** the analysis script for a `cmp/*` branch is executed
- **THEN** the commit records the command, inputs, outputs, and the container image's annex key

#### Scenario: The container image is missing

- **WHEN** no built image exists for the project's recipe
- **THEN** the containers doer builds it and the datalad doer registers it before the run, rather
  than the analysis falling back to the host environment

### Requirement: Products group kept comparisons into deliverables

`analyze/manage-product` MUST verify that each named comparison exists and is complete before adding
it, then upsert a product into `products[]` rather than appending a duplicate.

#### Scenario: Grouping comparisons into a paper

- **WHEN** several kept comparisons are grouped
- **THEN** one product entry lists them, and re-running the skill with an additional comparison
  updates that entry instead of creating a second one

#### Scenario: A named comparison does not exist

- **WHEN** a comparison branch cannot be found
- **THEN** the skill reports it and does not record the product as if the comparison were present

### Requirement: Checkpoint leaves the tracking chain unbroken

`analyze/checkpoint` MUST inspect state, compose a descriptive message, save through the datalad
doer, and log the checkpoint. It MUST NOT use an empty or placeholder message.

#### Scenario: Ending a work session

- **WHEN** a user wraps up before switching context
- **THEN** the tree is clean, the snapshot carries a message describing what changed, and the branch
  it ended on is reported
