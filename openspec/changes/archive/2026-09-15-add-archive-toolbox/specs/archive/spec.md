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
- **THEN** the skill runs standalone, showing the publishing call and confirming before any
  irreversible step, and never reporting an identifier the backend did not return

### Requirement: Readiness is checkable without an agent

`plugins/archive-cli/scripts/check-readiness.sh <backend>` MUST report, for `osf`, `zenodo`, or
`datacite`, either `result: ready` or `result: unminted` together with the specific missing item. It
MUST exit 0 when the backend is ready, 1 when it is not, and 2 on a usage error. It MUST check only
the presence of an extension or credential, MUST NOT print a secret value, and MUST NOT contact the
network.

#### Scenario: No credentials are present

- **WHEN** the check runs for `zenodo` with no `ZENODO_TOKEN` in the environment
- **THEN** it prints `result: unminted` naming `ZENODO_TOKEN` as missing and exits 1

#### Scenario: An unknown backend is named

- **WHEN** the check is given a backend other than `osf`, `zenodo`, or `datacite`
- **THEN** it exits 2 and names the accepted backends

### Requirement: Relations are written to the archive that owns the DOI

The toolbox MUST implement `RelatedIdentifier` creation and lookup using DataCite `relationType`
values. Creation MUST go through the backend that owns the source DOI: the `datacite` skill for a DOI
under the user's registered prefix, and the `zenodo` skill's `related_identifiers` metadata for a
Zenodo-minted DOI. Lookup MUST use DataCite's public REST API, which needs no credentials.
`disseminate/link-outputs` MUST delegate these mechanics to the archive doer rather than describing
them in its own body.

#### Scenario: Recording a relation between two released products

- **WHEN** `disseminate/link-outputs` relates a released dataset to a manuscript and both carry a DOI
- **THEN** the relation and its inverse are written through each DOI's owning backend, and the ledger
  records the same relation types

#### Scenario: The source has no writable DOI

- **WHEN** the source product has no DOI, or its DOI is owned by a backend with no relation write
  path or no usable credential
- **THEN** the doer returns `result: ledger-only` with the reason, and the relation exists in the
  ledger alone

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

## MODIFIED Requirements

### Requirement: Readiness is checked before any deposit

The doer MUST verify the selected backend's credential or extension before depositing — the
`datalad-osf` extension and an OSF token for OSF, `ZENODO_TOKEN` for Zenodo, an account and
registered prefix for DataCite. Each backend skill MUST state exactly what it requires and how to
report its absence, and the doer MUST take the check from that skill rather than restating it.

#### Scenario: No credentials are configured

- **WHEN** a mint is requested and no backend is usable
- **THEN** the doer stops before depositing and reports `result: unminted` with the reason and how
  to enable it

#### Scenario: Checking readiness

- **WHEN** the doer evaluates whether a backend is usable
- **THEN** the check comes from that backend's skill, and an unusable backend is reported with the
  specific thing that is missing

### Requirement: Every operation returns a structured result

The doer MUST report `op` (`mint-doi`, `lookup-doi`, `deposit`, `relate`, or `lookup-relations`),
`backend`, `version`, `result` (`ok`, `unminted`, or `failed`, plus `ledger-only` for `relate`), the
`doi` only when `result: ok`, any archive record URL, and notes.

#### Scenario: A backend error

- **WHEN** the archive returns an error
- **THEN** the doer surfaces it, returns `result: failed`, and publishes nothing further

#### Scenario: A relation cannot be written remotely

- **WHEN** a `relate` request names a source whose DOI has no write path
- **THEN** the doer returns `result: ledger-only` rather than `failed`, because the ledger record is
  still valid
