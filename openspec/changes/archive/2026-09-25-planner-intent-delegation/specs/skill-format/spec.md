## ADDED Requirements

### Requirement: Planner delegation to peripheral doers states intent, not command lines

A workflow-plane skill SHALL phrase every request to a doer as intent, parameters and required
outputs. It SHALL NOT phrase the request as a peripheral tool's command line. The planner owns the
research decision (which pipeline, which version, which scope, where to deploy) and states it in
words. The doer owns how the decision becomes a command. A safeguard that the command line carried,
such as a preview before a live run or explicit version flags, SHALL be restated as a constraint in
words.

Tool *names* are not command lines. A planner MAY name doers and the research tools a user chooses
between.

#### Scenario: A planner requests a pipeline run

- **WHEN** `process/run-pipeline` asks the nipoppy doer for an invocation
- **THEN** the request names the pipeline, version, step and scope, and asks for a simulated
  preview plus the inputs and outputs, and contains no `nipoppy process …` command line

#### Scenario: A planner builds the executable article

- **WHEN** `disseminate/executable-article` needs the article built
- **THEN** it asks the compendium doer to build and check the article, and does not quote `myst`
  commands

### Requirement: The native toolchain is written directly

DataLad, git and git-annex SHALL be treated as native to the main thread. A planner MAY write
their commands directly, and SHALL NOT describe an alternative provenance backend. A planner MAY
also run the harness's own scripts, those under `plugins/*/scripts/` and `schemas/`, directly.

#### Scenario: A planner saves and runs

- **WHEN** a planner records a change or runs a provenanced command
- **THEN** it writes the `datalad save` or `datalad run` command itself, and the lint does not
  count it
