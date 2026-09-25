## ADDED Requirements

### Requirement: The retired datalad doer is not referenced

The lint MUST report an error for the phrase "datalad doer", or the identifier `datalad-doer`,
matched case-insensitively and ignoring emphasis markers. It MUST scan every file under `plugins/`,
`templates/`, and `docs/` except `docs/talk/`. Archived OpenSpec changes MUST NOT be scanned.

#### Scenario: An instruction to the retired doer creeps back

- **WHEN** a planner body says "delegate to the **datalad doer**"
- **THEN** the lint errors, naming the file and line, and states that DataLad runs in the main thread

#### Scenario: History mentions it

- **WHEN** an archived change under `openspec/changes/archive/` names the datalad doer
- **THEN** nothing is reported

### Requirement: The retired-doer check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include a case that injects "datalad doer" into a planner
body and asserts the lint reports it.

#### Scenario: The check is weakened

- **WHEN** the retired-term check is removed or loosened
- **THEN** the selftest case fails
