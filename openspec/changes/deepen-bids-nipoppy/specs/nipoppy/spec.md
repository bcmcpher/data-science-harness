## ADDED Requirements

### Requirement: The nipoppy toolbox is split by command class

`plugins/nipoppy-cli/` MUST provide separate `user-invocable: true` skills for the read-only,
dataset-mutating, and setup command classes the nipoppy doer already distinguishes, each with an
`argument-hint` and scoped `allowed-tools`.

#### Scenario: A mutating command is constructed

- **WHEN** the doer is asked for a `process` invocation
- **THEN** it follows the mutating-class skill, which states that the command is handed back for the
  datalad doer to execute under `datalad run`

#### Scenario: A read-only command is run

- **WHEN** `status` is requested
- **THEN** the doer follows the read-only-class skill and may run it directly

### Requirement: The doer's classification rule points at the toolbox

The nipoppy doer MUST name, for each command class, the toolbox skill that governs it, so the
classification is documented in one place rather than restated in the doer.

#### Scenario: A new nipoppy command appears

- **WHEN** a command not yet covered is requested
- **THEN** the doer reports which class it believes the command falls into and asks the planner
  before executing anything that could mutate the dataset
