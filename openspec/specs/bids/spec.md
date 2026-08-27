# bids

## Purpose

The capability-plane wrapper over the Brain Imaging Data Structure. It answers one question —
does this dataset conform, and if not, where — and it answers it without changing anything. Being
read-only is the point: BIDS conformance is evidence used by `govern/qc-review` and the curation
skills, and evidence that mutates its subject is not evidence. Today the whole surface is
`plugins/bids/agents/bids-doer.md`; `bids-validator` is a detail inside the doer rather than a
first-class toolbox skill.

## Requirements

### Requirement: The bids doer never modifies the dataset

The doer MUST be read-only. It MUST NOT write, move, rename, or repair files, even when the fix is
obvious.

#### Scenario: A fixable conformance error is found

- **WHEN** validation reports a malformed `dataset_description.json`
- **THEN** the doer reports the error and the fix, and leaves the file untouched for a planner to act on

### Requirement: Conformance is reported structurally

The doer MUST run the BIDS validator and report a structured result distinguishing errors from
warnings, naming the offending paths.

#### Scenario: A dataset is validated

- **WHEN** a planner asks whether a dataset is BIDS-valid
- **THEN** the doer returns the validator's verdict with errors and warnings separated and located

### Requirement: Structural completeness is checked beyond the validator verdict

The doer MUST also report on `dataset_description.json`, the participants file, and sidecar
completeness, since a dataset can pass the validator while still being unusable downstream.

#### Scenario: Valid but incomplete

- **WHEN** a dataset validates but lacks participant-level sidecar metadata
- **THEN** the doer reports the gap rather than a bare "valid"

### Requirement: Absent tooling is reported, not simulated

When no BIDS validator is available, the doer MUST report the missing dependency and return no
verdict.

#### Scenario: Validator not installed

- **WHEN** validation is requested on a host without a validator
- **THEN** the doer reports that it cannot validate, and does not infer conformance from directory
  names
