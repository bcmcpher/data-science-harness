## ADDED Requirements

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

## MODIFIED Requirements

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
