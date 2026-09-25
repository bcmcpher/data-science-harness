## ADDED Requirements

### Requirement: The lint rejects peripheral command lines in planner bodies

The lint MUST report an error for each workflow-plane skill whose body contains a peripheral
command span. A span is either:

- an inline code span whose first token is in a closed set of peripheral tool binaries;
- a line inside a fenced code block whose first token is in that set.

The set MUST be defined alongside the other closed vocabularies in `tests/lint-plugins.py`, and
MUST NOT include `datalad`, `git` or `git-annex`. Spans that run the harness's own scripts MUST
NOT be counted. The error MUST name the skill, the line and the binary.

#### Scenario: A planner quotes a nipoppy command

- **WHEN** a planner body contains `` `nipoppy process --pipeline fmriprep` ``
- **THEN** the lint errors, naming the skill, the line and `nipoppy`

#### Scenario: A planner saves with DataLad

- **WHEN** a planner body contains `` `datalad save -m "…"` ``
- **THEN** nothing is reported

#### Scenario: A planner runs a gate script

- **WHEN** `project/env-check` runs `bash plugins/bids-cli/scripts/check-validator.sh`
- **THEN** nothing is reported

#### Scenario: Toolbox skills

- **WHEN** a `*-cli` toolbox skill contains peripheral command lines
- **THEN** nothing is reported, because toolboxes are where command lines belong

### Requirement: The peripheral-syntax check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include an error case that injects a peripheral command span
into a planner, and MUST keep the pristine control at zero errors and zero warnings.

#### Scenario: The check is weakened

- **WHEN** the check is removed or its binary set is emptied
- **THEN** the selftest case fails
