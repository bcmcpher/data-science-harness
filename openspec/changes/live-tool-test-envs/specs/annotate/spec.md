## ADDED Requirements

### Requirement: Each annotate backend tool is checked against the real CLI

`tests/e2e-smoke.sh` MUST run each installable annotate backend from its own environment under
`tests/envs/`:

- `bagel pheno` on a fixture dictionary with sourced Neurobagel annotations;
- `bidsmri2nidm` on a one-subject BIDS fixture;
- `reproschema validate` on a minimal protocol fixture.

Each check MUST run whenever its environment is present and in sync with its lock. Otherwise it MUST
skip, naming `bin/test-envs sync <tool>`. Inside each environment, the backend's
`check-backends.sh` answer MUST be `available`.

#### Scenario: bagel is synced

- **WHEN** `tests/envs/bagel` is synced and the e2e runs
- **THEN** `bagel pheno` produces a graph file from the annotated fixture, and the gate reports
  `bagel` available

#### Scenario: No environments are synced

- **WHEN** none of the annotate environments exist
- **THEN** each live check prints one `SKIP:` line with its sync command, and the rest of the
  annotate section still passes

### Requirement: A refusal is asserted for its reason, not only its exit code

A live check that asserts a tool rejects bad input MUST also assert that the rejection names the
defect under test. An exit code alone MUST NOT be accepted, because a usage error for a wrong flag
exits non-zero too.

#### Scenario: An unannotated dictionary

- **WHEN** `bagel pheno` is run on a dictionary with no `Annotations`
- **THEN** the check asserts a non-zero exit and an error about the missing annotations, and fails
  if the error is about an unrecognised option

### Requirement: Annotation fixtures carry no recalled identifiers

A fixture carrying controlled-term identifiers MUST be copied from a published source, and the
source and licence MUST be recorded beside it. A test MUST NOT hand-write a term identifier.

#### Scenario: Adding an annotated fixture

- **WHEN** a live check needs an annotated data dictionary
- **THEN** the fixture comes from Neurobagel's published example data, with a README naming where
  it came from
