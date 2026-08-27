# project-mgmt

## Purpose

The workflow-plane plugin for project initialization and the Manage & Comply lane: scaffolding a new
study, keeping the ledger's people and decisions current, rendering status reports, and orienting a
returning user. Administration is treated as first-class here — funding, credit, and rationale are
tracked with the same provenance discipline as the science, which is what makes a project's history
explain itself months later. Provides four planner skills (`new-project`, `status-report`, `people`,
`log-decision`) and the read-only `coordinator` agent.

## Requirements

### Requirement: new-project scaffolds a provenanced, self-describing project

`project/new-project` MUST create a YODA-structured DataLad dataset with a `text2git` configuration,
overlay a plain BIDS skeleton, scaffold an analysis container recipe under `containers/`, initialize
`project.yaml`, and commit the result through the datalad doer.

#### Scenario: A new study is started

- **WHEN** a user asks to start a new project and supplies a name
- **THEN** a DataLad dataset exists with a BIDS skeleton, a container recipe, and a `project.yaml`
  whose `project.name` is set, all in one committed state

#### Scenario: Required information is missing

- **WHEN** the project name or target directory is not given
- **THEN** the skill asks for it briefly rather than inventing a name

### Requirement: Contributions are recorded as standard-coded credit

`project/people` MUST upsert contributors into the ledger's `contributors[]`, matching existing
entries rather than duplicating them, recording ORCID iDs, ROR affiliations, and CRediT roles, and
MUST reflect the resulting author list into `dataset_description.json`.

#### Scenario: A contributor is added

- **WHEN** a person is credited with CRediT roles and an ORCID
- **THEN** `contributors[]` contains one entry for them and `dataset_description.json` `Authors`
  matches the ledger

#### Scenario: An identifier is unknown

- **WHEN** no ORCID is supplied
- **THEN** the contributor is still recorded and the missing identifier is reported rather than
  fabricated

### Requirement: Decisions are logged with their rationale

`project/log-decision` MUST append a single log entry capturing what was decided, why, and the
alternatives considered.

#### Scenario: A design choice is made

- **WHEN** a user asks to record why an approach was chosen
- **THEN** one append-only entry carries the decision, rationale, and alternatives, and is committed

### Requirement: Status reports are derived, never hand-edited

`project/status-report` MUST render a human-readable report from `project.yaml` — study header,
products and their release and DOI state, outstanding obligations, contributors, and recent activity
— and MUST NOT edit the ledger to make the report read better.

#### Scenario: A progress report is requested

- **WHEN** a status report is generated
- **THEN** every figure in it traces to a ledger field, and the ledger is unchanged apart from the
  appended log entry recording that the report was produced

### Requirement: The coordinator orients without acting

The `coordinator` agent MUST read the project log and DataLad state and report where the project
stands and the sensible next action. It MUST be read-only: it recommends planner skills and MUST NOT
run tools that change state.

#### Scenario: Returning to a project

- **WHEN** a user asks "where am I" or "what's next"
- **THEN** the coordinator summarizes current state and names the planner skills that would advance
  it, changing nothing

### Requirement: Every state change is committed through the datalad doer

Each skill in this plugin MUST delegate its save to the datalad doer, so administrative changes join
the same provenance chain as analysis results.

#### Scenario: Any ledger write

- **WHEN** a skill in this plugin modifies `project.yaml`
- **THEN** the change is committed via the datalad doer with a message naming the operation
