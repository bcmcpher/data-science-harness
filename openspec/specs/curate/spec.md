# curate

## Purpose

The workflow-plane plugin for Stage 2: getting raw data *into* the dataset and making it
self-describing. `raw-to-bids` converts DICOMs to a BIDS layout through nipoppy's containerized
converter under `datalad run`, so the ingest itself is provenanced rather than a manual step that
predates the record. `annotate` then advances STAMPED Metadata and Actionability — data dictionaries,
sidecars, and optionally controlled-term annotation via Neurobagel/SNOMED, ReproSchema, or NIDM.
That annotation is delegated to the `annotate` capability, which checks each backend independently,
so the dataset-level metadata still completes when no vocabulary tool is installed. `deidentify`
makes identifier removal a provenanced run with a recorded approach and a required residual-risk
statement — it scaffolds the decision and the record, and refuses to select a tool, to claim
compliance, or to answer whether the data may be shared. `merge-data` combines tabular sources on a
supplied join key and reports the row and column arithmetic, because a wrong join does not fail — it
produces a table. `gen-data-dict` derives a dictionary's skeleton from the data and takes every
meaning from the user or the `annotate` doer, leaving undescribed columns out and naming them.

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

`curate/annotate` MUST delegate controlled-term annotation to the annotate doer and report the
coverage that doer returns — naming which variables received a term, which did not, and why. This
annotation step is optional and is offered when richer Metadata and Actionability are wanted. The
skill MUST declare `delegates_to: [annotate, datalad]`.

#### Scenario: Partial controlled-term coverage

- **WHEN** only some variables map to controlled terms
- **THEN** the report distinguishes annotated from unannotated variables, attributing each term to
  the source the doer queried

#### Scenario: A term cannot be resolved

- **WHEN** the annotate doer reports a variable as unannotated
- **THEN** the variable is described in free text, the gap is reported, and no term identifier is
  invented

#### Scenario: The annotate capability is unavailable

- **WHEN** no annotation backend is installed
- **THEN** the skill still completes the dataset-level metadata and data-dictionary steps, and
  reports controlled-term coverage as unavailable

### Requirement: Metadata edits are provenanced

`curate/annotate` MUST delegate the save to the datalad doer and append a log entry, so annotation
joins the same chain as the data it describes.

#### Scenario: Annotations are written

- **WHEN** metadata files are added or changed
- **THEN** they are committed through the datalad doer with a message naming the operation

### Requirement: De-identification is a recorded, provenanced step

Removing identifying information from a dataset MUST be carried out through the provenance chain and
recorded in the ledger, naming the approach applied, the inputs it was applied to, and the residual
risk the researcher accepted. The record MUST state what was deliberately retained as well as what
was removed.

#### Scenario: A dataset is de-identified

- **WHEN** identifying information is removed from a dataset
- **THEN** each removal is a provenanced run, and the ledger records the approach, its inputs, and
  the residual risk

#### Scenario: Identifying information is deliberately kept

- **WHEN** a category of identifier is retained for a research reason, such as scan dates in a
  longitudinal design
- **THEN** the retention is recorded as a decision, so it is distinguishable from an oversight

### Requirement: De-identification claims nothing it did not do

A skill MUST NOT state that a dataset is de-identified unless a recorded action produced that state,
and MUST NOT present its record as a compliance determination. The residual-risk statement MUST be
present; an absent one is a claim that nothing remains.

#### Scenario: No de-identification has been run

- **WHEN** a report is produced for a dataset with no recorded de-identification action
- **THEN** it reports the absence rather than describing the dataset as de-identified

#### Scenario: The researcher asks whether the data can be shared

- **WHEN** a sharing decision is requested
- **THEN** the skill reports what was done and what risk remains, and does not answer the question

