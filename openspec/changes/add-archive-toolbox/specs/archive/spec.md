## ADDED Requirements

### Requirement: The toolbox provides one skill per archive backend

`plugins/archive-cli/` MUST provide a `user-invocable: true` skill for each of `osf`, `zenodo`, and
`datacite`, each with an `argument-hint` and `allowed-tools` scoped to that backend. The archive doer
MUST consult the matching skill rather than carrying backend detail inline.

#### Scenario: The doer deposits to Zenodo

- **WHEN** a Zenodo deposit is requested
- **THEN** the doer follows the `zenodo` skill's steps and constraints to construct the calls

#### Scenario: A user drives a backend directly

- **WHEN** a user invokes the `osf` skill without a planner
- **THEN** the skill runs standalone

### Requirement: Each backend skill states its own readiness check

Each backend skill MUST state exactly what it requires to operate — the `datalad-osf` extension and
an OSF token, `ZENODO_TOKEN`, or a DataCite account and registered prefix — and how to report absence.

#### Scenario: Checking readiness

- **WHEN** the doer evaluates whether a backend is usable
- **THEN** the check comes from that backend's skill, and an unusable backend is reported with the
  specific thing that is missing

### Requirement: DataCite relation handling is implemented, not described

The `datacite` skill MUST implement `RelatedIdentifier` creation and lookup using DataCite
`relationType` values, and `disseminate/link-outputs` MUST delegate to it rather than describing the
mechanics in its own body.

#### Scenario: Recording a relation between two products

- **WHEN** `disseminate/link-outputs` relates a released dataset to a manuscript
- **THEN** the relation and its inverse are created through the `datacite` skill, and the ledger
  records the same relation types

#### Scenario: An external identifier is the target

- **WHEN** the relation target is an external DOI rather than a product in this ledger
- **THEN** the relation is still recorded, with the external identifier resolved or reported as
  unresolvable

### Requirement: The refusal and confirmation rules stay with the doer

The `unminted` contract and the confirmation step before irreversible publication MUST remain
properties of the archive doer, applying uniformly across backends.

#### Scenario: A backend skill could mint but no credential is present

- **WHEN** any backend reports itself unusable
- **THEN** the doer returns `result: unminted` with the reason, regardless of which backend was
  selected
