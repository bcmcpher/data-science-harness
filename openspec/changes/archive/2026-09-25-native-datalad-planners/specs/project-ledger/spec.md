## ADDED Requirements

### Requirement: Activity is recorded in commits, not in the ledger

Skills MUST record activity in the `DSH-*` lines of the commit that makes the change, as defined
by the `datalad` capability. They MUST NOT append to `project.yaml` `log`. The history of a project
MUST be read with `dsh-log`, which also returns legacy `log` entries, so no record is lost.

#### Scenario: A skill records an action

- **WHEN** any planner skill completes an action that changes project state
- **THEN** exactly one new commit carries its `DSH-Op`, and `project.yaml` `log` is unchanged

#### Scenario: A previous decision turns out to be wrong

- **WHEN** a recorded decision is superseded
- **THEN** a new commit records the correction, and the original commit is left intact, because
  history is immutable

## MODIFIED Requirements

### Requirement: The ledger has a fixed, closed top-level shape

`project.yaml` MUST be an object with `additionalProperties: false` and exactly these permitted
top-level keys: `project`, `products`, `obligations`, `contributors`, `log`. Of these, only `project`
MUST be present. `log` is legacy. It is permitted so that ledgers written before activity moved
into commits still validate, and no skill writes to it.

#### Scenario: An unrecognised top-level key is introduced

- **WHEN** a skill writes a `milestones:` key that the schema does not define
- **THEN** `schemas/validate-ledger.py` fails, forcing the schema to be extended before the writer ships

#### Scenario: A minimal valid ledger

- **WHEN** a ledger contains only a `project` object with a `name`
- **THEN** validation passes

#### Scenario: A ledger written before this change

- **WHEN** a ledger contains a populated `log` array
- **THEN** validation still passes

### Requirement: Obligations track outstanding commitments

Each entry in `obligations` MUST have `id`, `kind` (`preregistration`, `confirmatory-comparison`,
`dmp`, `ethics`, `milestone`, `funder-report`, `other`), and `status` (`pending`, `met`, `waived`),
and MAY carry `description`, `due` (date), and `ref`.

An obligation at `status: met` MUST carry `resolved_by` naming the recorded action that met it: a
commit SHA (preferred, and the only form new skills write), a legacy log entry timestamp, or a
product id. The commit that sets `met` MUST carry `DSH-Obligation: <id> resolved`. `ref` remains the
*external* reference (a registration id or URL) and MUST NOT be used to carry internal evidence,
because whoever later checks the claim needs to know which of the two they are reading.

#### Scenario: A pre-registered comparison is registered

- **WHEN** `govern/preregister` freezes a confirmatory comparison spec
- **THEN** a `confirmatory-comparison` obligation is appended with `status: pending` and the
  registration identifier in `ref`, and the commit carries `DSH-Obligation: <id> opened`

#### Scenario: The registered comparison is executed

- **WHEN** `analyze/run-comparison` completes that comparison and the result is checked against the
  frozen spec
- **THEN** the obligation moves to `met` with `resolved_by` naming the recording run's commit SHA,
  and any deviation from the registered spec is stated in that commit's message

#### Scenario: An obligation is marked met with no evidence

- **WHEN** a ledger sets an obligation to `status: met` without `resolved_by`
- **THEN** `schemas/validate-ledger.py` rejects it, so a status flip cannot stand in for a record of
  what actually happened

#### Scenario: A deadline is tracked

- **WHEN** `project/track-milestone` records a project deadline
- **THEN** it is an obligation with `kind: milestone` and a `due` date, surfaced by
  `govern/obligations` alongside every other outstanding commitment

## REMOVED Requirements

### Requirement: The log is append-only

**Reason**: Activity moves into commit `DSH-*` lines. Commit history is immutable, so the
append-only guarantee is now structural rather than a rule skills must follow.
**Migration**: See "Activity is recorded in commits, not in the ledger". Existing `log` entries
are kept and read by `dsh-log --legacy`.
