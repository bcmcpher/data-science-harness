# nipoppy

## Purpose

The capability-plane wrapper over the Nipoppy CLI for neuroimaging dataset management — init,
track-curation, reorg, bidsify, process, track-processing, extract, and status. The governing
constraint is that Nipoppy's mutating commands would otherwise write to the dataset outside the
provenance chain, so this capability constructs and hands back those commands for the datalad doer
to execute under `datalad run`. Today the surface is `plugins/nipoppy/agents/nipoppy-doer.md` plus a
single `nipoppy-cli` toolbox skill.

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
