# curate

## Purpose

The workflow-plane plugin for Stage 2: getting raw data *into* the dataset and making it
self-describing. `raw-to-bids` converts DICOMs to a BIDS layout through nipoppy's containerized
converter under `datalad run`, so the ingest itself is provenanced rather than a manual step that
predates the record. `annotate` then advances STAMPED Metadata and Actionability — data dictionaries,
sidecars, and optionally controlled-term annotation via Neurobagel/SNOMED, ReproSchema, or NIDM.
Today `annotate` has no capability beneath it and does the metadata work inline.

## Requirements

### Requirement: Raw-to-BIDS conversion is provenanced

`curate/raw-to-bids` MUST have the nipoppy doer construct the converter invocation, MUST ensure a
clean tree, and MUST have the datalad doer execute it under `datalad run` with explicit inputs and
outputs. It MUST NOT run the converter outside the provenance chain.

#### Scenario: DICOMs are converted

- **WHEN** raw imaging data is converted with a named converter and version
- **THEN** the resulting commit records the command, inputs, and outputs, and the `bids/` tree is
  reachable through that run

#### Scenario: The tree is dirty

- **WHEN** uncommitted changes exist at conversion time
- **THEN** the skill resolves that through the datalad doer before running, because `datalad run`
  requires a clean tree

### Requirement: Curation status is recorded after conversion

After a successful conversion, `curate/raw-to-bids` MUST update nipoppy's curation status and append
a ledger log entry naming the converter, its version, and the scope converted.

#### Scenario: Conversion completes

- **WHEN** the run succeeds
- **THEN** curation status is updated and one log entry records what was converted, then the state is
  saved

### Requirement: Annotation makes the dataset self-describing

`curate/annotate` MUST complete `dataset_description.json`, generate a `participants.json` data
dictionary covering each phenotypic column, and fill or extend BIDS sidecars.

#### Scenario: A dataset lacks a data dictionary

- **WHEN** annotation runs on a dataset with an unannotated `participants.tsv`
- **THEN** a `participants.json` describes each column, and the survey of what already existed is
  reported alongside what was added

### Requirement: Controlled-term annotation is optional and honest about coverage

`curate/annotate` MUST report controlled-term coverage honestly whenever it annotates variables with
terms from Neurobagel, SNOMED, ReproSchema, or NIDM — naming which variables received a term and
which did not. This annotation step is optional and is offered when richer Metadata and
Actionability are wanted.

#### Scenario: Partial controlled-term coverage

- **WHEN** only some variables map to controlled terms
- **THEN** the report distinguishes annotated from unannotated variables

#### Scenario: A term cannot be resolved

- **WHEN** no controlled term is found for a variable
- **THEN** the variable is described in free text and the gap is reported, and no term identifier is
  invented

### Requirement: Metadata edits are provenanced

`curate/annotate` MUST delegate the save to the datalad doer and append a log entry, so annotation
joins the same chain as the data it describes.

#### Scenario: Annotations are written

- **WHEN** metadata files are added or changed
- **THEN** they are committed through the datalad doer with a message naming the operation
