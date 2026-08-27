## MODIFIED Requirements

### Requirement: Controlled-term annotation is optional and honest about coverage

`curate/annotate` MUST delegate controlled-term annotation to the annotate doer and report the
coverage that doer returns — naming which variables received a term, which did not, and why. This
annotation step is optional and is offered when richer Metadata and Actionability are wanted. The
skill MUST declare `delegates_to: [annotate, datalad]`.

#### Scenario: Partial controlled-term coverage

- **WHEN** only some variables map to controlled terms
- **THEN** the report distinguishes annotated from unannotated variables, attributing each term to
  the source the doer queried

#### Scenario: A term cannot be resolved

- **WHEN** the annotate doer reports a variable as unannotated
- **THEN** the variable is described in free text, the gap is reported, and no term identifier is
  invented

#### Scenario: The annotate capability is unavailable

- **WHEN** no annotation backend is installed
- **THEN** the skill still completes the dataset-level metadata and data-dictionary steps, and
  reports controlled-term coverage as unavailable
