# nipoppy

## Purpose

The capability-plane wrapper over the Nipoppy CLI for neuroimaging dataset management — init,
track-curation, reorg, bidsify, process, track-processing, extract, and status. The governing
constraint is that Nipoppy's mutating commands would otherwise write to the dataset outside the
provenance chain, so this capability constructs and hands back those commands for the datalad doer
to execute under `datalad run`. The doer (`plugins/nipoppy/agents/nipoppy-doer.md`) holds that
policy; the `nipoppy-cli` toolbox is split by **command class** rather than by verb — `nipoppy-query`
reads and saves nothing, `nipoppy-track` refreshes the derived status files and hands the save back
as a checkpoint, `nipoppy-compute` constructs and refuses to execute the commands that produce data,
and `nipoppy-setup` writes declarations. The handling rule is a property of the class, not of the
verb, which is what makes the split survive a command nobody has seen yet.
## Requirements
### Requirement: The nipoppy doer owns all nipoppy CLI mechanics

Planner skills MUST NOT invoke `nipoppy`. `curate/raw-to-bids` and `process/run-pipeline` MUST
delegate here.

#### Scenario: A pipeline must be run

- **WHEN** `process/run-pipeline` needs an fMRIPrep invocation
- **THEN** it delegates command construction to the nipoppy doer

### Requirement: Mutating commands are never executed bare

The doer MUST NOT execute a dataset-mutating nipoppy command directly. It MUST classify the request,
construct the command with its inputs and outputs, and hand it back for the datalad doer to run with
provenance.

#### Scenario: A processing command is requested

- **WHEN** a `process` invocation is requested
- **THEN** the doer returns the constructed command with explicit inputs and outputs, and the datalad
  doer executes it under `datalad run`

#### Scenario: A read-only command is requested

- **WHEN** `status` or `track-processing` is requested
- **THEN** the doer may run it directly, because it changes nothing

### Requirement: Command classes are handled explicitly

The doer MUST distinguish read-only inspection, dataset-mutating operations, and setup operations,
and MUST state which class a request falls into in its report.

#### Scenario: An ambiguous request

- **WHEN** the request does not make the command class clear
- **THEN** the doer asks the planner rather than assuming the safer or the faster path

### Requirement: Every operation returns a structured result

The doer MUST report the operation, the constructed or executed command, `result`, and any outputs
or next-step handoff.

#### Scenario: Handing off to datalad

- **WHEN** the doer returns a mutating command
- **THEN** the report names the datalad doer as the next executor and includes the inputs and outputs
  that run requires

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

