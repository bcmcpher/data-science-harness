# bids

## Purpose

The capability-plane wrapper over the Brain Imaging Data Structure. It answers one question —
does this dataset conform, and if not, where — and it answers it without changing anything. Being
read-only is the point: BIDS conformance is evidence used by `govern/qc-review` and the curation
skills, and evidence that mutates its subject is not evidence. The doer
(`plugins/bids/agents/bids-doer.md`) holds the read-only contract; the `bids-cli` toolbox holds
`bids-validator` as a skill a user can invoke without a planner and a test can target, plus the
offline presence check that distinguishes an absent validator from a failing one. Two validator
distributions exist with non-shared command lines, and the Python `bids_validator` package is not
one of them — the gate refuses to count it deliberately.
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

### Requirement: BIDS validation is a first-class toolbox skill

`plugins/bids-cli/` MUST provide a `user-invocable: true` `bids-validator` skill with an
`argument-hint` and `allowed-tools` scoped to running the validator. The bids doer MUST consult it
rather than carrying invocation detail inline.

#### Scenario: A user validates a dataset directly

- **WHEN** a user invokes the `bids-validator` skill without a planner
- **THEN** the skill runs standalone and reports errors and warnings

#### Scenario: The doer validates on a planner's behalf

- **WHEN** `govern/qc-review` delegates validation
- **THEN** the doer follows the toolbox skill's steps and returns its structured result

### Requirement: Validation is assertable in the end-to-end test

`tests/e2e-smoke.sh` MUST assert BIDS validation against the scaffolded dataset, gated to skip
cleanly when no validator is installed.

#### Scenario: No validator on the host

- **WHEN** the e2e test runs without a BIDS validator
- **THEN** the block skips with a stated reason rather than failing or silently passing

