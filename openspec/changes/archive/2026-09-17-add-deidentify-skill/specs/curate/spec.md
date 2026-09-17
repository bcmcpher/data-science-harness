## ADDED Requirements

### Requirement: De-identification is a recorded, provenanced step

Removing identifying information from a dataset MUST be carried out through the provenance chain and
recorded in the ledger, naming the approach applied, the inputs it was applied to, and the residual
risk the researcher accepted. The record MUST state what was deliberately retained as well as what
was removed.

#### Scenario: A dataset is de-identified

- **WHEN** identifying information is removed from a dataset
- **THEN** each removal is a provenanced run, and the ledger records the approach, its inputs, and
  the residual risk

#### Scenario: Identifying information is deliberately kept

- **WHEN** a category of identifier is retained for a research reason, such as scan dates in a
  longitudinal design
- **THEN** the retention is recorded as a decision, so it is distinguishable from an oversight

### Requirement: De-identification claims nothing it did not do

A skill MUST NOT state that a dataset is de-identified unless a recorded action produced that state,
and MUST NOT present its record as a compliance determination. The residual-risk statement MUST be
present; an absent one is a claim that nothing remains.

#### Scenario: No de-identification has been run

- **WHEN** a report is produced for a dataset with no recorded de-identification action
- **THEN** it reports the absence rather than describing the dataset as de-identified

#### Scenario: The researcher asks whether the data can be shared

- **WHEN** a sharing decision is requested
- **THEN** the skill reports what was done and what risk remains, and does not answer the question
