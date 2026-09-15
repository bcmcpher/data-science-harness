# govern

## Purpose

The workflow-plane plugin for Stage 0 (Propose & Govern) and Stage 5 (QC / Review), plus the
compliance half of the Manage & Comply lane. It holds the two mechanisms that make rigor checkable
rather than aspirational: freezing a comparison's specification before it is executed, and tracking
every outstanding commitment as a ledger obligation with a due date and a status. Provides
`preregister`, `obligations`, and `qc-review`.

## Requirements

### Requirement: Pre-registration freezes the spec before execution

`govern/preregister` MUST capture an immutable specification for a comparison, guide its submission
to an external registry such as OSF Registrations, ClinicalTrials.gov, or PROSPERO, and record a
`confirmatory-comparison` obligation in the ledger with the registration reference.

#### Scenario: A confirmatory comparison is registered

- **WHEN** a user pre-registers a comparison
- **THEN** the frozen spec is written and committed, and an obligation with `status: pending` records
  the registration reference

#### Scenario: External registration has not completed

- **WHEN** the registry submission is still pending
- **THEN** the obligation is recorded with the registration marked pending rather than with an
  invented identifier

### Requirement: The frozen spec is not edited after registration

Once registered, the specification MUST NOT be rewritten. Any change to the analysis plan MUST be
recorded as a new log entry describing the deviation.

#### Scenario: The analysis plan changes mid-project

- **WHEN** a registered comparison must be run differently than specified
- **THEN** the frozen spec is left intact and the deviation is logged so it is reportable

### Requirement: Obligations are a queryable registry of what is owed

`govern/obligations` MUST read and update the ledger's `obligations[]` — adding, listing, and
resolving pre-registered comparisons, DMP and ethics deliverables, and funder reports — and MUST
report the next item due ordered by date and then by kind.

#### Scenario: Asking what is outstanding

- **WHEN** a user asks what they owe
- **THEN** pending obligations are listed with their kinds and due dates, and the next one due is
  named

#### Scenario: An obligation is discharged

- **WHEN** a commitment is met or waived
- **THEN** its status changes and a log entry records the resolution

### Requirement: qc-review reports without changing the dataset

`govern/qc-review` MUST delegate BIDS validation to the bids doer and a read-only state inspection to
the datalad doer, then produce a STAMPED self-assessment scorecard. It MUST NOT modify the dataset.

#### Scenario: A pre-release review

- **WHEN** a dataset is reviewed before release
- **THEN** the result is a scorecard giving the BIDS verdict with errors and warnings, a
  per-principle STAMPED assessment, and for each gap the skill that would close it

#### Scenario: A gap is found

- **WHEN** the review identifies a shortfall
- **THEN** it is reported with a recommended skill, and the dataset is left untouched

### Requirement: STAMPED is assessed as a spectrum

The self-assessment MUST treat each STAMPED principle as a position on a spectrum with evidence,
not as a pass or fail gate.

#### Scenario: Partial coverage

- **WHEN** a dataset is tracked and portable but not yet distributable
- **THEN** the scorecard reflects that unevenly rather than reporting a single overall verdict
