## MODIFIED Requirements

### Requirement: Obligations track outstanding commitments

Each entry in `obligations` MUST have `id`, `kind` (`preregistration`, `confirmatory-comparison`,
`dmp`, `ethics`, `milestone`, `funder-report`, `other`), and `status` (`pending`, `met`, `waived`),
and MAY carry `description`, `due` (date), and `ref`.

An obligation at `status: met` MUST carry `resolved_by` naming the recorded action that met it — a
commit SHA, a log entry timestamp, or a product id. `ref` remains the *external* reference (a
registration id or URL) and MUST NOT be used to carry internal evidence, because whoever later
checks the claim needs to know which of the two they are reading.

#### Scenario: A pre-registered comparison is registered

- **WHEN** `govern/preregister` freezes a confirmatory comparison spec
- **THEN** a `confirmatory-comparison` obligation is appended with `status: pending` and the
  registration identifier in `ref`

#### Scenario: The registered comparison is executed

- **WHEN** `analyze/run-comparison` completes that comparison and the result is checked against the
  frozen spec
- **THEN** the obligation moves to `met` with `resolved_by` naming the recording run, and any
  deviation from the registered spec is recorded in the log

#### Scenario: An obligation is marked met with no evidence

- **WHEN** a ledger sets an obligation to `status: met` without `resolved_by`
- **THEN** `schemas/validate-ledger.py` rejects it, so a status flip cannot stand in for a record of
  what actually happened

#### Scenario: A deadline is tracked

- **WHEN** `project/track-milestone` records a project deadline
- **THEN** it is an obligation with `kind: milestone` and a `due` date, surfaced by
  `govern/obligations` alongside every other outstanding commitment

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
