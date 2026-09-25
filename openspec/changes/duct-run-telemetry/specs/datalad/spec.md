## ADDED Requirements

### Requirement: Provenanced runs capture resource usage when duct is available

When `duct` resolves on `PATH`, the `datalad` skill's run reference SHALL wrap the recorded command
in `duct` with an output prefix under `.duct/logs/<op>/`, where `<op>` is the commit's `DSH-Op`
value or `adhoc`. It SHALL declare `.duct/logs/<op>` as an output of the run. The prefix's
`{datetime}` and `{pid}` placeholders SHALL be written with doubled braces, so the record keeps
them unexpanded and a rerun writes new log names. When `duct` does not resolve, the run SHALL
proceed unwrapped. The always-loaded rules file MUST NOT carry this procedure.

#### Scenario: duct is installed

- **WHEN** a run is built in a dataset and `command -v duct` succeeds
- **THEN** the recorded command starts with `duct -p .duct/logs/<op>/{{datetime}}-{{pid}}_`, the
  run declares `-o .duct/logs/<op>`, and the commit contains that run's `usage.jsonl` and
  `info.json`

#### Scenario: duct is not installed

- **WHEN** a run is built and `command -v duct` fails
- **THEN** the run is recorded exactly as it would be without this requirement, and the report
  says resource usage was not captured

#### Scenario: A measured run is replayed

- **WHEN** `datalad rerun` replays a commit whose command was wrapped in duct
- **THEN** the rerun succeeds and writes a new log set beside the original

### Requirement: duct logs keep JSON in git and captured output in the annex

Before the first wrapped run in a dataset, the run reference SHALL write `.duct/.gitattributes`
so that `*_usage.jsonl` and `*_info.json` under `.duct/logs/` are stored in git and `*_stdout` and
`*_stderr` are annexed, and SHALL save it with `datalad save` before the run.

#### Scenario: First measured run in a text2git dataset

- **WHEN** a dataset created with `text2git` has no `.duct/.gitattributes` and a wrapped run is
  about to start
- **THEN** the file is written and saved first, and after the run the captured stdout is an
  annexed file while the usage log is a plain git blob

### Requirement: Container runs are measured only inside an image that provides duct

For `datalad containers-run`, the command SHALL be wrapped in duct only when the image provides
duct, because the command string executes inside the container. Otherwise the run SHALL proceed
unwrapped and the report SHALL say resource usage was not captured.

#### Scenario: The image lacks duct

- **WHEN** a container run is built for an image whose pinned manifest does not list `con-duct`
- **THEN** the command is not wrapped, and the report states that usage was not captured

## MODIFIED Requirements

### Requirement: Harness commits carry DSH lines

Every commit a harness skill makes MUST have a single-message body containing exactly one
`DSH-Op: <skill-name>` line. It MAY contain `DSH-Stage`, and zero or more each of
`DSH-Binding: <doer>/<tool>@<version>`, `DSH-Product: <id>` and
`DSH-Obligation: <id> <opened|resolved>`. No other `DSH-` key is defined. A `DSH-Binding` value
MUST be copied from a doer's structured result, never assumed by the planner. The one exception is
the resource-telemetry wrap, which no doer performs: a run wrapped in duct carries
`DSH-Binding: datalad-cli/duct@<version>`, with the version read from `duct --version` in the same
session, or from the image's pinned manifest for a container run. The message MUST be passed as
one `-m` argument, because `datalad save` keeps only the last of several.

#### Scenario: A save commit

- **WHEN** `govern/ethics-track` saves an amendment
- **THEN** the commit message has a subject stating what and why, followed by a paragraph with
  `DSH-Op: ethics-track` and `DSH-Stage: govern`

#### Scenario: A doer chose the tool

- **WHEN** the archive doer mints through its `auto` selection and reports `backend: zenodo`
- **THEN** the release commit carries `DSH-Binding: archive/zenodo@<reported version>`

#### Scenario: A pipeline run is measured

- **WHEN** `process/run-pipeline` runs a nipoppy command wrapped in duct 0.22.0
- **THEN** the run commit carries the nipoppy doer's binding and `DSH-Binding:
  datalad-cli/duct@0.22.0`, and `dsh-log` reports both
