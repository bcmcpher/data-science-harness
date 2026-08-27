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
top-level keys: `project`, `products`, `obligations`, `contributors`, `log`. Of these, `project` and
`log` MUST be present.

#### Scenario: An unrecognised top-level key is introduced

- **WHEN** a skill writes a `milestones:` key that the schema does not define
- **THEN** `schemas/validate-ledger.py` fails, forcing the schema to be extended before the writer ships

#### Scenario: A minimal valid ledger

- **WHEN** a ledger contains only a `project` object with a `name` and an empty `log` array
- **THEN** validation passes

### Requirement: The project header is written once

`project` MUST contain a `name`, and MAY contain `description`, `created` (date-time),
`dataset_root`, and `stack` (`python`, `R`, or `other`). It SHALL be set by `project/new-project`
and not rewritten by later skills.

#### Scenario: new-project scaffolds a dataset

- **WHEN** `project/new-project` completes
- **THEN** `project.yaml` exists at the dataset root with a populated `project.name` and is committed

### Requirement: The log is append-only

`log` MUST be an array of entries each having `ts` (date-time) and `op`, and optionally `stage`,
`note`, and `branch`. Skills MUST append; they MUST NOT rewrite or reorder prior entries. A
correction is a new entry.

#### Scenario: A skill records an action

- **WHEN** any planner skill completes an action that changes project state
- **THEN** it appends one entry naming the operation, and the entry count strictly increases

#### Scenario: A previous decision turns out to be wrong

- **WHEN** a recorded decision is superseded
- **THEN** a new entry is appended describing the correction, and the original entry is left intact

### Requirement: Products group kept comparisons into deliverables

Each entry in `products` MUST have `id`, `kind` (`paper`, `dataset`, `report`, `article`,
`agent-bundle`, `other`), and `status` (`planned`, `in-progress`, `released`), and MAY carry
`title`, `comparisons`, `outputs`, `dois`, and `relations`.

#### Scenario: A comparison is promoted into a product

- **WHEN** `analyze/manage-product` groups a kept `cmp/*` branch into a product
- **THEN** the product's `comparisons` list names that branch and the ledger still validates

#### Scenario: A product is released

- **WHEN** `disseminate/dataset-release` deposits a tagged version and a DOI is returned
- **THEN** the DOI is appended to that product's `dois` and its `status` becomes `released`

### Requirement: Relations use DataCite relation types

Each entry in a product's `relations` MUST have a `relation` naming a DataCite `relationType` (for
example `IsSourceOf`, `IsSupplementTo`, `IsDerivedFrom`, `IsVariantFormOf`) and a `target` that is
either a product `id` in this ledger or an external DOI or URL.

#### Scenario: Cross-linking a dataset to the paper built from it

- **WHEN** `disseminate/link-outputs` connects a released dataset to a manuscript product
- **THEN** both directions of the relation are recorded with DataCite relation types

### Requirement: Obligations track outstanding commitments

Each entry in `obligations` MUST have `id`, `kind` (`preregistration`, `confirmatory-comparison`,
`dmp`, `ethics`, `funder-report`, `other`), and `status` (`pending`, `met`, `waived`), and MAY carry
`description`, `due` (date), and `ref`.

#### Scenario: A pre-registered comparison is registered

- **WHEN** `govern/preregister` freezes a confirmatory comparison spec
- **THEN** a `confirmatory-comparison` obligation is appended with `status: pending` and the
  registration identifier in `ref`

#### Scenario: The registered comparison is executed

- **WHEN** `analyze/run-comparison` completes that comparison and the result is checked against the
  frozen spec
- **THEN** the obligation moves to `met`, and any deviation from the registered spec is recorded in
  the log

### Requirement: Contributors carry persistent identifiers and CRediT roles

Each entry in `contributors` MUST have a `name` and MAY carry `orcid`, `affiliation_ror`, and
`roles` drawn from CRediT. This list is the source for `dataset_description.json` authors and
DataCite creators.

#### Scenario: Credit is recorded and propagated

- **WHEN** `project/people` adds a contributor with an ORCID and CRediT roles
- **THEN** a later release derives its DataCite creators from that list rather than from free text
