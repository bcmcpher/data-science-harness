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
clean tree, and MUST execute the returned command itself under `datalad run` with explicit inputs
and outputs. It MUST NOT run the converter outside the provenance chain.

#### Scenario: DICOMs are converted

- **WHEN** raw imaging data is converted with a named converter and version
- **THEN** the resulting commit records the command, inputs, and outputs, and the `bids/` tree is
  reachable through that run

#### Scenario: The tree is dirty

- **WHEN** uncommitted changes exist at conversion time
- **THEN** the skill resolves that with `datalad save` before running, because `datalad run`
  requires a clean tree

### Requirement: Curation status is recorded after conversion

After a successful conversion, `curate/raw-to-bids` MUST update nipoppy's curation status and save
it in a commit whose message names the converter, its version, and the scope converted, and carries
`DSH-Op: raw-to-bids` and `DSH-Stage` lines, with a `DSH-Binding` line for the converter named in the
nipoppy doer's result.

#### Scenario: Conversion completes

- **WHEN** the run succeeds
- **THEN** curation status is updated and saved, and that commit's message records what was
  converted together with its `DSH-Op`, `DSH-Stage` and `DSH-Binding` lines

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
skill MUST declare `delegates_to: [annotate]`.

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

`curate/annotate` MUST save its changes with `datalad save` in a commit carrying `DSH-Op: annotate`
and `DSH-Stage` lines, so annotation joins the same chain as the data it describes.

#### Scenario: Annotations are written

- **WHEN** metadata files are added or changed
- **THEN** they are committed with `datalad save` with a message naming the operation and carrying
  `DSH-Op: annotate`

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

### Requirement: A merge is reported with the arithmetic that would expose its failure

`curate/merge-data` MUST take the join key from the user rather than inferring it, check key overlap
and uniqueness before merging, and produce the merged table as a provenanced run whose report states
rows in, rows out, keys matched and keys dropped per side. It MUST NOT reconcile conflicting values,
impute missing ones, or modify a source table in place.

#### Scenario: Two tables are combined

- **WHEN** phenotypic sources are merged on a supplied key
- **THEN** a new file is produced through a recorded run and the report carries the row and column
  arithmetic, so a silent drop or multiplication is visible

#### Scenario: The identifiers do not overlap

- **WHEN** key overlap is zero or near zero
- **THEN** the skill reports an identifier-format mismatch and stops, rather than producing an empty
  or tiny table that will be mistaken for a real one

#### Scenario: A join key is not supplied

- **WHEN** both tables contain a plausibly-matching column such as `id` or `participant_id`
- **THEN** the skill asks which key to join on rather than inferring that the columns mean the same
  thing

#### Scenario: Two sources disagree about a value

- **WHEN** the same participant has different values for a column in each source
- **THEN** the disagreement is reported as a data-quality finding and no precedence rule is applied
  silently

### Requirement: A data dictionary describes only what it was told

`curate/gen-data-dict` MUST derive the dictionary's skeleton — columns, types, observed levels —
from the data, and MUST obtain each column's meaning, units and level coding from the user or from
the `annotate` doer. An undescribed column MUST be omitted from the dictionary and named in the
report. The skill MUST NOT restate a column's name as its description, assume a unit, or overwrite
an existing description.

#### Scenario: A dictionary is generated

- **WHEN** a tabular file is documented
- **THEN** described columns get entries and the report names every column still undescribed, so the
  dictionary's completeness is visible rather than assumed

#### Scenario: A level coding is not supplied

- **WHEN** a column contains `0` and `1` and no coding was given
- **THEN** no meaning is written, because `1 = male` and `1 = female` are both common and a guess
  becomes documentation

#### Scenario: A column name suggests its content

- **WHEN** a column is called `age` and nothing states its units
- **THEN** the unit is asked for rather than assumed, since age in years and age in months both
  appear in phenotypic exports and a wrong unit silently rescales an analysis

#### Scenario: A controlled term was not looked up

- **WHEN** the annotate doer returns no identifier for a variable
- **THEN** the free-text description stays and no code is written, inheriting that doer's refusal to
  recall an identifier
