## MODIFIED Requirements

### Requirement: The frozen spec is not edited after registration

Once registered, the specification MUST NOT be rewritten. Any change to the analysis plan MUST be
recorded as a new commit whose message describes the deviation and carries `DSH-Op` and
`DSH-Stage` lines.

#### Scenario: The analysis plan changes mid-project

- **WHEN** a registered comparison must be run differently than specified
- **THEN** the frozen spec is left intact and the deviation is recorded in a commit message that
  `dsh-log` returns, so it is reportable

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
- **THEN** its status changes, and the commit that records the change carries
  `DSH-Obligation: <id> resolved`

### Requirement: qc-review reports without changing the dataset

`govern/qc-review` MUST delegate BIDS validation to the bids doer and inspect DataLad state itself
with read-only DataLad commands, then produce a STAMPED self-assessment scorecard. It MUST NOT
modify the dataset.

#### Scenario: A pre-release review

- **WHEN** a dataset is reviewed before release
- **THEN** the result is a scorecard giving the BIDS verdict with errors and warnings, a
  per-principle STAMPED assessment, and for each gap the skill that would close it

#### Scenario: A gap is found

- **WHEN** the review identifies a shortfall
- **THEN** it is reported with a recommended skill, and the dataset is left untouched

### Requirement: A ledger can be added to a dataset that does not have one

`govern/init-ledger` MUST create a schema-valid `project.yaml` in an existing dataset, and MUST
refuse to overwrite, migrate or repair one that already exists. It MUST NOT backfill the history
with records of work that predates the ledger, and MUST record where the record begins.

#### Scenario: A ledger already exists

- **WHEN** `init-ledger` runs in a dataset that already has `project.yaml`
- **THEN** it reports that and stops, leaving the existing `project.yaml`, including any legacy
  `log` entries, untouched

#### Scenario: An existing study adopts the ledger

- **WHEN** a dataset with prior history gains a ledger
- **THEN** the commit that adds the ledger carries `DSH-Op: init-ledger` and its message records
  from what point the record is complete, rather than reconstructing earlier activity

#### Scenario: The registries are empty at creation

- **WHEN** a ledger is created
- **THEN** `obligations`, `products` and `contributors` are absent or empty rather than populated
  with entries nobody committed to

### Requirement: Ethics approvals are recorded with their expiry and amendment history

`govern/ethics-track` MUST record an approval as an `obligations[]` entry with `kind: ethics`, the
expiry in `due` and the protocol reference in `ref`, with the approval date and every amendment
recorded in the message of the commit that records it, carrying `DSH-Op: ethics-track`. It MUST NOT
infer an approval date, an expiry, or a protocol number, and MUST NOT state whether a planned use
falls within an approval's scope.

#### Scenario: An approval is recorded

- **WHEN** an IRB approval with a protocol number and expiry is supplied
- **THEN** a `kind: ethics` obligation carries the expiry in `due` and the protocol in `ref`, and the
  approval date is in the recording commit's message

#### Scenario: Only an approval date is known

- **WHEN** the expiry is not supplied
- **THEN** it is left unrecorded and reported as missing, rather than computed from the approval date

#### Scenario: The protocol is amended

- **WHEN** an amendment is granted
- **THEN** it is recorded in a new commit carrying `DSH-Op: ethics-track`, and any prior record of
  what was approved remains readable through `dsh-log`

#### Scenario: The researcher asks whether an analysis is covered

- **WHEN** a scope question is asked
- **THEN** the skill reports what the approval records and names who decides, without answering
