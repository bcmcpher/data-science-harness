## ADDED Requirements

### Requirement: The nipoppy toolbox is split by command class

`plugins/nipoppy-cli/` MUST provide separate `user-invocable: true` skills for each command class
the nipoppy doer distinguishes — read-only queries, bookkeeping writes, dataset-mutating
computations, and setup declarations — each with an `argument-hint` and scoped `allowed-tools`. A
class's handling rule MUST be stated in its own skill rather than restated per verb.

#### Scenario: A mutating command is constructed

- **WHEN** the doer is asked for a `process` invocation
- **THEN** it follows the mutating-class skill, which states that the command is handed back for the
  datalad doer to execute under `datalad run`

#### Scenario: A read-only command is run

- **WHEN** `status` is requested
- **THEN** the doer follows the read-only-class skill and may run it directly

#### Scenario: A command writes derived state without producing data

- **WHEN** `track-curation` or `track-processing` is requested
- **THEN** the doer follows the bookkeeping skill, which runs it directly and hands the save back as
  a checkpoint rather than recording a run whose inputs would be the whole dataset

### Requirement: The doer's classification rule points at the toolbox

The nipoppy doer MUST name, for each command class, the toolbox skill that governs it, so the
classification is documented in one place rather than restated in the doer.

#### Scenario: A new nipoppy command appears

- **WHEN** a command not yet covered is requested
- **THEN** the doer reports which class it believes the command falls into and asks the planner
  before executing anything that could mutate the dataset
