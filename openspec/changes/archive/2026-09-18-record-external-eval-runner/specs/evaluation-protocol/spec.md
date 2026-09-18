## ADDED Requirements

### Requirement: The runner may live outside this repository

The protocol MUST NOT require its runner to be implemented in this repository, and the documents
defining it MUST name the instrument that executes each probe, whether that instrument is in this
repository or another one. A probe whose instrument is unnamed is not reportable, for the same
reason a probe with no control is not.

#### Scenario: A runner exists elsewhere

- **WHEN** a runner capable of executing a probe is built outside this repository
- **THEN** the protocol names it and the fixtures are read unmodified, rather than a second runner
  being specified here

#### Scenario: No runner exists for a probe

- **WHEN** no instrument can execute a probe
- **THEN** the documents state that the probe is unrun and say what is missing, rather than
  describing the missing runner as this repository's deferred work when it is not

### Requirement: The fixtures are a stable contract for any consumer

`bench/` MUST remain consumable by an external runner without modification, and every expected
outcome it declares MUST stay derivable from this repository — `expected_delegates_to` against each
planner's declared `delegates_to`, checked by `tests/check-bench-fixtures.py`. A field that cannot be
checked against the repository MUST NOT be added to a fixture.

#### Scenario: A consumer needs a field the fixtures do not carry

- **WHEN** a runner's own suite format requires something these fixtures do not declare, such as a
  train/validation/test split
- **THEN** the consumer supplies it on its side, because a fixture edited to fit one runner is
  hand-maintained rather than repository-derived, and the probe's ground truth rests on that
  distinction

#### Scenario: A capability lands and a planner is rewired

- **WHEN** a planner's `delegates_to` grows
- **THEN** the affected task is updated in the same change and the external consumer needs no
  coordination, because it reads the fixture as it stands
