## MODIFIED Requirements

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
