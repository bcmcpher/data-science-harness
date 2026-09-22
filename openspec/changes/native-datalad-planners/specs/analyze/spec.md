## MODIFIED Requirements

### Requirement: A comparison is a branch plus a record, not a pipeline stage

`analyze/propose-comparison` MUST capture what is being compared and why, its inputs and expected
outputs, and its rigor mode, then create a clearly named `cmp/*` branch, running DataLad directly
as it runs git. A comparison MUST be introducible at any point in the project.

#### Scenario: A new analysis is proposed

- **WHEN** a user asks to look at one variable against another
- **THEN** a `cmp/*` branch exists for it and the proposal is recorded

#### Scenario: The bar to propose is low

- **WHEN** the user gives only a one-line description of an exploratory query
- **THEN** the comparison is created without demanding a full analysis plan

### Requirement: Comparisons execute with full provenance inside the project container

`analyze/run-comparison` MUST confirm it is on the comparison's branch, gather the run's inputs,
outputs, and message, ensure the container image exists via the containers doer, and run the
execution itself under `datalad containers-run`. The run commit MUST carry `DSH-Op` and
`DSH-Stage` lines in its message.

#### Scenario: A comparison is run

- **WHEN** the analysis script for a `cmp/*` branch is executed
- **THEN** the commit records the command, inputs, outputs, and the container image's annex key,
  and its message carries `DSH-Op: run-comparison`

#### Scenario: The container image is missing

- **WHEN** no built image exists for the project's recipe
- **THEN** the containers doer builds it and the planner registers it with `datalad containers-add`
  before the run, rather than the analysis falling back to the host environment

### Requirement: Checkpoint leaves the tracking chain unbroken

`analyze/checkpoint` MUST inspect state, compose a descriptive message, and save with
`datalad save`, the commit carrying `DSH-Op: checkpoint` and `DSH-Stage` lines so the checkpoint is
in the history `dsh-log` reads. It MUST NOT use an empty or placeholder message.

#### Scenario: Ending a work session

- **WHEN** a user wraps up before switching context
- **THEN** the tree is clean, the snapshot carries a message describing what changed and a
  `DSH-Op: checkpoint` line, and the branch it ended on is reported
