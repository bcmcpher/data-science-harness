# govern

## Purpose

The workflow-plane plugin for Stage 0 (Propose & Govern) and Stage 5 (QC / Review), plus the
compliance half of the Manage & Comply lane. It holds the two mechanisms that make rigor checkable
rather than aspirational: freezing a comparison's specification before it is executed, and tracking
every outstanding commitment as a ledger obligation with a due date and a status. Provides
`init-ledger`, `dmp`, `ethics-track`, `preregister`, `obligations`, `qc-review` and
`stamped-assess`.

Its recurring problem is that most questions asked of a governance skill have the same honest
answer: a person decides that. So every skill here records rather than rules. `dmp` will not assert
a funder requirement it did not read, `ethics-track` will not compute an expiry from an approval date
or say whether a use is in scope, and `stamped-assess` reports seven dimensions with evidence and no
composite — marking what it could not check `unassessed` rather than zero, which is the same
distinction `annotate` draws between `unannotated` and `unavailable`.
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
not as a pass or fail gate. It MUST report each dimension separately and MUST NOT report a composite
or averaged score, because `docs/stamped.md` sets no pass mark.

A dimension for which no evidence could be gathered MUST be reported as `unassessed`, naming what
would make it assessable. `unassessed` MUST NOT be reported as a zero score or omitted: a zero claims
the requirement was checked and found unmet, and conflating the two biases the report against the
project while hiding which occurred. This is the same distinction the `annotate` capability draws
between `unannotated` and `unavailable`.

#### Scenario: Partial coverage

- **WHEN** a dataset is tracked and portable but not yet distributable
- **THEN** the scorecard reflects that unevenly rather than reporting a single overall verdict

#### Scenario: A dimension cannot be checked

- **WHEN** the evidence for a dimension is unavailable — a tool absent, a file outside the dataset
- **THEN** that dimension is `unassessed` with the reason, not scored zero and not omitted

#### Scenario: A composite score is requested

- **WHEN** a single overall STAMPED number is asked for
- **THEN** the per-dimension readout is given instead, because the framework declines to set the
  pass mark a composite would imply

### Requirement: A ledger can be added to a dataset that does not have one

`govern/init-ledger` MUST create a schema-valid `project.yaml` in an existing dataset, and MUST
refuse to overwrite, migrate or repair one that already exists. It MUST NOT backfill the append-only
log with entries for work that predates the ledger, and MUST record where the record begins.

#### Scenario: A ledger already exists

- **WHEN** `init-ledger` runs in a dataset that already has `project.yaml`
- **THEN** it reports that and stops, leaving the existing append-only log untouched

#### Scenario: An existing study adopts the ledger

- **WHEN** a dataset with prior history gains a ledger
- **THEN** the first log entry records that the ledger was added and from what point the record is
  complete, rather than reconstructing earlier activity

#### Scenario: The registries are empty at creation

- **WHEN** a ledger is created
- **THEN** `obligations`, `products` and `contributors` are absent or empty rather than populated
  with entries nobody committed to

### Requirement: A data management plan's commitments become tracked obligations

`govern/dmp` MUST record each commitment a plan makes as an `obligations[]` entry with `kind: dmp`,
so the plan is operative rather than archival. It MUST NOT assert a funder requirement, deadline,
retention period or repository mandate that was not read from a supplied template or stated by the
user, and MUST report the sections the user still has to complete.

#### Scenario: No funder template is supplied

- **WHEN** a plan is requested without a template or policy text
- **THEN** the project-derived sections are written, every funder-specific section is marked as
  needing the user's input, and that list is part of the report

#### Scenario: The plan promises a deposit by a date

- **WHEN** a plan commits to depositing data by a stated date
- **THEN** a `kind: dmp` obligation records that commitment with its due date

### Requirement: Ethics approvals are recorded with their expiry and amendment history

`govern/ethics-track` MUST record an approval as an `obligations[]` entry with `kind: ethics`, the
expiry in `due` and the protocol reference in `ref`, with the approval date and every amendment
appended to the log. It MUST NOT infer an approval date, an expiry, or a protocol number, and MUST
NOT state whether a planned use falls within an approval's scope.

#### Scenario: An approval is recorded

- **WHEN** an IRB approval with a protocol number and expiry is supplied
- **THEN** a `kind: ethics` obligation carries the expiry in `due` and the protocol in `ref`, and the
  approval date is in the log

#### Scenario: Only an approval date is known

- **WHEN** the expiry is not supplied
- **THEN** it is left unrecorded and reported as missing, rather than computed from the approval date

#### Scenario: The protocol is amended

- **WHEN** an amendment is granted
- **THEN** it is a new log entry, and any prior record of what was approved remains readable

#### Scenario: The researcher asks whether an analysis is covered

- **WHEN** a scope question is asked
- **THEN** the skill reports what the approval records and names who decides, without answering

