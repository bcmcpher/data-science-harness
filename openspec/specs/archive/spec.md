# archive

## Purpose

The capability-plane wrapper over external archives and persistent-identifier services — OSF,
Zenodo, and DataCite. It deposits an already-tagged dataset or product version and reads back the
identifier the archive assigns. Its defining property is refusal to invent: publishing is
irreversible and a DOI that does not resolve is worse than no DOI, so the doer reports
`result: unminted` whenever credentials or extensions are absent. Today the whole surface is the
doer (`plugins/archive/agents/archive-doer.md`); the per-backend toolbox is not yet built.

## Requirements

### Requirement: The archive doer owns all deposit and identifier mechanics

Planner skills MUST NOT call archive APIs. `disseminate/dataset-release` and
`disseminate/link-outputs` MUST delegate minting and lookup to the archive doer.

#### Scenario: A release needs a DOI

- **WHEN** a planner has tagged a releasable version
- **THEN** it delegates the deposit to the archive doer and records whatever identifier comes back

### Requirement: Readiness is checked before any deposit

The doer MUST verify the selected backend's credential or extension before depositing — the
`datalad-osf` extension and an OSF token for OSF, `ZENODO_TOKEN` for Zenodo, an account and
registered prefix for DataCite.

#### Scenario: No credentials are configured

- **WHEN** a mint is requested and no backend is usable
- **THEN** the doer stops before depositing and reports `result: unminted` with the reason and how
  to enable it

### Requirement: Identifiers are never fabricated

A DOI MUST appear in the doer's report only when a backend actually returned it. The doer MUST NOT
guess, construct, or reuse a plausible identifier.

#### Scenario: Recording a release without a DOI

- **WHEN** the doer reports `result: unminted`
- **THEN** the planner records the release in the ledger with no DOI, and the absence is visible
  rather than papered over

### Requirement: Only an already-tagged, committed state is deposited

The doer MUST deposit an immutable tagged state created by the planner via
`datalad save --version-tag`. It MUST NOT create or move tags, and MUST NOT mutate the dataset to
make a deposit fit.

#### Scenario: The requested version is not tagged

- **WHEN** a deposit is requested for an untagged state
- **THEN** the doer asks the planner for the tag rather than creating one

### Requirement: Irreversible publication is confirmed before it happens

Because a published record or minted DOI cannot be withdrawn, the doer MUST show the deposit command
or endpoint and confirm before the final publish step.

#### Scenario: The final publish step

- **WHEN** the deposit is ready to publish
- **THEN** the exact call is displayed first, and publication proceeds only after confirmation

### Requirement: Every operation returns a structured result

The doer MUST report `op` (`mint-doi`, `lookup-doi`, or `deposit`), `backend`, `version`, `result`
(`ok`, `unminted`, or `failed`), the `doi` only when `result: ok`, any archive record URL, and notes.

#### Scenario: A backend error

- **WHEN** the archive returns an error
- **THEN** the doer surfaces it, returns `result: failed`, and publishes nothing further

### Requirement: Release scope is the planner's decision

The doer MUST NOT decide what to release or how to version it.

#### Scenario: An underspecified release request

- **WHEN** the request does not say which version to deposit
- **THEN** the doer asks the planner rather than choosing a version
