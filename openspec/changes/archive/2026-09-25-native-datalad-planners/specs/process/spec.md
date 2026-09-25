## MODIFIED Requirements

### Requirement: Pipelines execute only through datalad run

The constructed command MUST be executed by the planner itself under `datalad run` on a clean tree,
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
doer and save it with `datalad save` in a commit whose message names the pipeline, version, and
scope, and carries `DSH-Op: run-pipeline` and `DSH-Stage` lines, with a `DSH-Binding` line for the
pipeline named in the nipoppy doer's result.

#### Scenario: Recording what was processed

- **WHEN** processing finishes
- **THEN** the tracked status and the recording commit's message agree on which participants were
  processed with which pipeline version
