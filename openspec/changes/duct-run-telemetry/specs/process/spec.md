## ADDED Requirements

### Requirement: Pipeline runs capture resource usage when duct is available

`process/run-pipeline` SHALL ask, in words, for the pipeline run to capture resource usage when
duct is available, following the `datalad` skill's run reference, and SHALL carry duct's binding
on the run commit beside the nipoppy doer's. It SHALL NOT quote a duct command line. It SHALL NOT
wrap a run submitted to a scheduler, because duct would measure only the submission.

#### Scenario: A local fMRIPrep run with duct installed

- **WHEN** the pipeline runs locally under Apptainer and duct is on `PATH`
- **THEN** the run commit contains the run's duct logs under `.duct/logs/run-pipeline/` and a
  `DSH-Binding: datalad-cli/duct@<version>` line, and the report names the log directory

#### Scenario: A scheduler submission

- **WHEN** the nipoppy doer returns a command that submits to a cluster scheduler
- **THEN** the command is run under `datalad run` without the duct wrap

#### Scenario: The planner body is linted

- **WHEN** `tests/lint-plugins.py` reads `process/run-pipeline`
- **THEN** no span in its body starts with `duct` or `con-duct`
