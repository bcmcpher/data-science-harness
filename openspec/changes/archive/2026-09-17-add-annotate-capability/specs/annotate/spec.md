## ADDED Requirements

### Requirement: The annotate doer owns metadata-enrichment mechanics

The annotate doer MUST own all controlled-term lookup and metadata-file generation. Planner skills
MUST NOT call `bagel-cli`, `pynidm`, `reproschema`, or a terminology service directly.

#### Scenario: A planner needs a data dictionary

- **WHEN** `curate/annotate` needs `participants.json` generated from `participants.tsv`
- **THEN** it delegates to the annotate doer, which constructs and runs the tool invocation

### Requirement: Controlled terms are looked up, never recalled

The annotate doer MUST obtain every controlled-term identifier from a tool or terminology source it
actually queried. It MUST NOT emit an identifier produced from model knowledge.

#### Scenario: A term is found

- **WHEN** a variable maps to a controlled term
- **THEN** the doer reports the identifier together with the source it came from

#### Scenario: No lookup source is available

- **WHEN** the terminology tool or credential is absent
- **THEN** the doer reports the variable as unannotated with the reason, and emits no identifier

### Requirement: Backend availability degrades per tool

The annotate doer MUST check each backend independently and report which are available, so a dataset
can gain annotation from one vocabulary while another stays empty.

#### Scenario: One of several backends is installed

- **WHEN** `bagel-cli` is present but no SNOMED source is configured
- **THEN** Neurobagel annotation proceeds and SNOMED coverage is reported as unavailable, not as zero
  matches

### Requirement: The doer writes metadata but does not commit

The annotate doer MUST write metadata files into the dataset and MUST NOT commit them. The save MUST
be delegated to the datalad doer by the calling planner.

#### Scenario: Annotation completes

- **WHEN** the doer finishes writing `participants.json` and sidecars
- **THEN** the files are on disk uncommitted, and the doer reports what it wrote for the planner to save

### Requirement: The toolbox provides one skill per tool

`plugins/annotate-cli/` MUST provide a `user-invocable: true` skill per supported tool, each with an
`argument-hint` and `allowed-tools` scoped to that tool, following the `datalad-cli` shape.

#### Scenario: A user drives a tool directly

- **WHEN** a user invokes an `annotate-cli` skill without a planner
- **THEN** the skill runs standalone

### Requirement: Every operation returns a structured result

The annotate doer MUST report the operation, the tool and version used, `result`, the files written,
per-variable coverage, and notes naming any unavailable backend.

#### Scenario: Partial coverage

- **WHEN** some variables are annotated and others are not
- **THEN** the report distinguishes them and states why each unannotated variable was skipped
