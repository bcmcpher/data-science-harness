# project-ledger

## Purpose

`project.yaml` at the dataset root is the administrative source of truth for the Manage & Comply
lane — the cross-cutting track every lifecycle stage runs inside. It is a plain YAML file
`datalad save`-d like any other artifact, so administration inherits the same provenance discipline
as the science. This spec records the schema **as implemented** in
`schemas/project.schema.json`, validated by `schemas/validate-ledger.py` and exercised by
`tests/e2e-smoke.sh`. The richer aspirational ledger sketched in the README is not implemented and
is tracked as documentation drift, not as a requirement.

## Requirements

### Requirement: The ledger has a fixed, closed top-level shape

`project.yaml` MUST be an object with `additionalProperties: false` and exactly these permitted
top-level keys: `project`, `products`, `obligations`, `contributors`, `log`. Of these, only `project`
MUST be present. `log` is legacy. It is permitted so that ledgers written before activity moved
into commits still validate, and no skill writes to it.

#### Scenario: An unrecognised top-level key is introduced

- **WHEN** a skill writes a `milestones:` key that the schema does not define
- **THEN** `schemas/validate-ledger.py` fails, forcing the schema to be extended before the writer ships

#### Scenario: A minimal valid ledger

- **WHEN** a ledger contains only a `project` object with a `name`
- **THEN** validation passes

#### Scenario: A ledger written before this change

- **WHEN** a ledger contains a populated `log` array
- **THEN** validation still passes

### Requirement: The project header is written once

`project` MUST contain a `name`, and MAY contain `description`, `created` (date-time),
`dataset_root`, and `stack` (`python`, `R`, or `other`). It SHALL be set by `project/new-project`
and not rewritten by later skills.

#### Scenario: new-project scaffolds a dataset

- **WHEN** `project/new-project` completes
- **THEN** `project.yaml` exists at the dataset root with a populated `project.name` and is committed

### Requirement: Products group kept comparisons into deliverables

Each entry in `products` MUST have `id`, `kind` (`paper`, `dataset`, `report`, `article`,
`agent-bundle`, `other`), and `status` (`planned`, `in-progress`, `released`), and MAY carry `title`,
`comparisons`, `outputs`, `dois`, `relations`, and `submissions`.

`submissions` is a history, not a state. Each entry MUST have a `venue` and MAY carry `submitted`
(date), `status` (`preparing`, `submitted`, `under-review`, `revision-requested`, `accepted`,
`rejected`, `withdrawn`), `decision`, and `ref`. A product's own `status` MUST NOT be overloaded to
carry submission state: a product under review and a product whose submission was rejected are both
still `in-progress`, and a resubmission MUST NOT erase the record of the submission before it.

#### Scenario: A comparison is promoted into a product

- **WHEN** `analyze/manage-product` groups a kept `cmp/*` branch into a product
- **THEN** the product's `comparisons` list names that branch and the ledger still validates

#### Scenario: A product is released

- **WHEN** `disseminate/dataset-release` deposits a tagged version and a DOI is returned
- **THEN** the DOI is appended to that product's `dois` and its `status` becomes `released`

#### Scenario: A manuscript is submitted and rejected, then sent elsewhere

- **WHEN** `disseminate/submission-track` records a rejection and a later submission to a second
  venue
- **THEN** both entries are present in `submissions`, the product's `status` is unchanged, and the
  first venue's outcome is still readable

### Requirement: Relations use DataCite relation types

Each entry in a product's `relations` MUST have a `relation` naming a DataCite `relationType` (for
example `IsSourceOf`, `IsSupplementTo`, `IsDerivedFrom`, `IsVariantFormOf`) and a `target` that is
either a product `id` in this ledger or an external DOI or URL.

#### Scenario: Cross-linking a dataset to the paper built from it

- **WHEN** `disseminate/link-outputs` connects a released dataset to a manuscript product
- **THEN** both directions of the relation are recorded with DataCite relation types

### Requirement: Obligations track outstanding commitments

Each entry in `obligations` MUST have `id`, `kind` (`preregistration`, `confirmatory-comparison`,
`dmp`, `ethics`, `milestone`, `funder-report`, `other`), and `status` (`pending`, `met`, `waived`),
and MAY carry `description`, `due` (date), and `ref`.

An obligation at `status: met` MUST carry `resolved_by` naming the recorded action that met it: a
commit SHA (preferred, and the only form new skills write), a legacy log entry timestamp, or a
product id. The commit that sets `met` MUST carry `DSH-Obligation: <id> resolved`. `ref` remains the
*external* reference (a registration id or URL) and MUST NOT be used to carry internal evidence,
because whoever later checks the claim needs to know which of the two they are reading.

#### Scenario: A pre-registered comparison is registered

- **WHEN** `govern/preregister` freezes a confirmatory comparison spec
- **THEN** a `confirmatory-comparison` obligation is appended with `status: pending` and the
  registration identifier in `ref`, and the commit carries `DSH-Obligation: <id> opened`

#### Scenario: The registered comparison is executed

- **WHEN** `analyze/run-comparison` completes that comparison and the result is checked against the
  frozen spec
- **THEN** the obligation moves to `met` with `resolved_by` naming the recording run's commit SHA,
  and any deviation from the registered spec is stated in that commit's message

#### Scenario: An obligation is marked met with no evidence

- **WHEN** a ledger sets an obligation to `status: met` without `resolved_by`
- **THEN** `schemas/validate-ledger.py` rejects it, so a status flip cannot stand in for a record of
  what actually happened

#### Scenario: A deadline is tracked

- **WHEN** `project/track-milestone` records a project deadline
- **THEN** it is an obligation with `kind: milestone` and a `due` date, surfaced by
  `govern/obligations` alongside every other outstanding commitment

### Requirement: Contributors carry persistent identifiers and CRediT roles

Each entry in `contributors` MUST have a `name` and MAY carry `orcid`, `affiliation_ror`, and
`roles` drawn from CRediT. This list is the source for `dataset_description.json` authors and
DataCite creators.

#### Scenario: Credit is recorded and propagated

- **WHEN** `project/people` adds a contributor with an ORCID and CRediT roles
- **THEN** a later release derives its DataCite creators from that list rather than from free text

### Requirement: Activity is recorded in commits, not in the ledger

Skills MUST record activity in the `DSH-*` lines of the commit that makes the change, as defined
by the `datalad` capability. They MUST NOT append to `project.yaml` `log`. The history of a project
MUST be read with `dsh-log`, which also returns legacy `log` entries, so no record is lost.

#### Scenario: A skill records an action

- **WHEN** any planner skill completes an action that changes project state
- **THEN** exactly one new commit carries its `DSH-Op`, and `project.yaml` `log` is unchanged

#### Scenario: A previous decision turns out to be wrong

- **WHEN** a recorded decision is superseded
- **THEN** a new commit records the correction, and the original commit is left intact, because
  history is immutable

### Requirement: Overdue has one definition

An obligation SHALL be overdue exactly when its `status` is `pending` and its `due` is a date
earlier than today in UTC. Today SHALL be read from the clock (`date -u +%F`), not assumed. An
obligation due today, one with no `due`, and one at `met` or `waived` SHALL NOT be overdue.

Every surface that reports obligations SHALL use this definition and SHALL list overdue obligations
before other pending ones. The surfaces are the session status block (`dsh-status.sh`),
`project/status-report`, the `coordinator` agent and `govern/obligations`. None of them SHALL
report an obligation as "near"; "due soon" SHALL mean only what the next requirement defines.

#### Scenario: A lapsed ethics renewal

- **WHEN** the ledger holds `ethics-renewal` with `status: pending` and a `due` date before today
- **THEN** the status block, a status report, the coordinator and `govern/obligations` all report
  it as overdue, and list it before the other pending obligations

#### Scenario: A met obligation with a past date

- **WHEN** `prereg-h1` has `status: met` and a `due` date in the past
- **THEN** no surface reports it as overdue

#### Scenario: The model's sense of the date is wrong

- **WHEN** a planner surface reports obligations
- **THEN** it compares against the date printed by `date -u +%F`, not against a date it infers

### Requirement: The due-soon window is set in the ledger

The `project` header SHALL accept an optional `due_warn_days`, an integer of 0 or more, and the
ledger schema SHALL validate it. When it is absent or 0, no surface SHALL report obligations as due
soon. When it is N > 0, an obligation SHALL be due soon exactly when its `status` is `pending` and
its `due` is on or after today and on or before today + N days, in UTC. An obligation is never both
overdue and due soon.

Every surface named in the overdue requirement SHALL use this definition, and SHALL list due-soon
obligations after overdue ones and before the other pending ones.

#### Scenario: A window of 14 days

- **WHEN** `due_warn_days` is 14 and `funder-report` is `pending` and due in 10 days
- **THEN** the status block, a status report, the coordinator and `govern/obligations` all report it
  as due soon

#### Scenario: No window

- **WHEN** `due_warn_days` is absent
- **THEN** no surface reports any obligation as due soon

#### Scenario: The schema rejects a bad window

- **WHEN** `due_warn_days` is -3 or `"two weeks"`
- **THEN** `schemas/validate-ledger.py` reports the ledger as invalid
