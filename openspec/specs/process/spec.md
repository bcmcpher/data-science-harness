# process

## Purpose

The workflow-plane plugin for running established neuroimaging pipelines — fMRIPrep, MRIQC, and
their peers — on a dataset's BIDS data. It exists as its own step because a pipeline run is the
sharpest case of the harness's central rule: nipoppy knows how to build the invocation, but only
DataLad may execute it, so the derivatives that result are reachable from the raw data by
`datalad rerun`. Provides `run-pipeline`.

## Requirements

### Requirement: Pipeline invocations are constructed by the nipoppy doer

`process/run-pipeline` MUST determine the pipeline, its version, and the participant scope, then
delegate command construction to the nipoppy doer. It MUST NOT assemble the invocation itself.

#### Scenario: An fMRIPrep run is requested

- **WHEN** a user asks to run fMRIPrep on a dataset
- **THEN** the nipoppy doer returns the constructed command with explicit inputs and outputs

#### Scenario: The pipeline version is unspecified

- **WHEN** no version is given
- **THEN** the skill asks rather than defaulting silently, because the version is part of the
  provenance record

### Requirement: Pipelines execute only through datalad run

The constructed command MUST be executed by the datalad doer under `datalad run` on a clean tree,
never bare.

#### Scenario: A pipeline completes

- **WHEN** the run succeeds
- **THEN** the derivatives are recorded as outputs of a run commit and the run is replayable

#### Scenario: A pipeline fails

- **WHEN** the run returns non-zero
- **THEN** the failure is surfaced, nothing is committed as if it had succeeded, and partial
  derivatives are not registered as outputs

### Requirement: Completion is tracked and logged

After a successful run, `process/run-pipeline` MUST record processing status through the nipoppy
doer, append a ledger log entry naming the pipeline, version, and scope, and save through the
datalad doer.

#### Scenario: Recording what was processed

- **WHEN** processing finishes
- **THEN** the tracked status and the log entry agree on which participants were processed with which
  pipeline version
