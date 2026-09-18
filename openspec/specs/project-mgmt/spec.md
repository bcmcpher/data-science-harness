# project-mgmt

## Purpose

The workflow-plane plugin for project initialization and the Manage & Comply lane: scaffolding a new
study, keeping the ledger's people, dates and decisions current, rendering status reports, reporting
what the project's environment declares against what the machine has, writing the project's assistant
configuration, and orienting a returning user. Administration is treated as first-class here —
funding, credit, and rationale are tracked with the same provenance discipline as the science, which
is what makes a project's history explain itself months later. Provides seven planner skills
(`new-project`, `status-report`, `people`, `log-decision`, `track-milestone`, `env-check`,
`claude-config`) and the read-only `coordinator` agent.
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

### Requirement: Deadlines are tracked as obligations, and a moved date leaves evidence

`project/track-milestone` MUST record a deadline as an `obligations[]` entry with `kind: milestone`
and a `due` date, in the same registry as every other commitment, and MUST obtain the date from the
user rather than deriving it. Moving a date MUST update `due` and log the previous value with the
reason. The skill MUST NOT resolve or delete a milestone.

#### Scenario: A deadline is tracked

- **WHEN** a submission target or funder report date is recorded
- **THEN** it appears as a `kind: milestone` obligation, and "what's due" is answerable from the
  obligations registry alone

#### Scenario: A deadline moves

- **WHEN** a tracked date slips
- **THEN** `due` is updated and the log records the old date, the new date and the reason, rather
  than the change being invisible

#### Scenario: A date is not supplied

- **WHEN** the deadline is implied by a conference name or a funder's usual cycle but not stated
- **THEN** the skill asks for it rather than inferring one, because a confidently wrong deadline in
  a tracking system is trusted

#### Scenario: The commitment is already tracked under another kind

- **WHEN** the deadline is a pre-registration, ethics expiry or DMP deliverable
- **THEN** the owning skill is named instead of a second entry being created

### Requirement: Environment reporting separates undeclared from absent

`project/env-check` MUST report a tool's declaration and its presence as two separate findings, and
MUST obtain each capability's availability from that capability's own gate script rather than
re-implementing the check. It MUST NOT install anything, edit a manifest, or state that the
environment is correct.

#### Scenario: A tool is present but not declared

- **WHEN** a workflow depends on a tool that no committed manifest declares
- **THEN** it is reported as a Portability defect naming the manifest that should own it, not as a
  missing tool

#### Scenario: A tool is declared but not installed

- **WHEN** a manifest declares a tool the machine does not have
- **THEN** it is reported as a setup step with the manifest and install route, not as an undeclared
  dependency

#### Scenario: A gate script reports a usage error

- **WHEN** a capability's check exits `2`
- **THEN** that is reported as a usage error rather than as `unavailable`, because reporting it as
  installable promises a path that does not exist

#### Scenario: A check would pass after an install

- **WHEN** a missing tool could be installed to make the report clean
- **THEN** the skill reports the route and does not run it

### Requirement: Assistant configuration is written only from verified facts

`project/claude-config` MUST derive every line of a project's `CLAUDE.md`, settings and MCP stubs
from evidence in the project, show existing content before replacing it, and ask the user about
anything it cannot source. It MUST NOT write a credential into a committed file, and MUST NOT claim
the configuration is complete.

#### Scenario: A convention cannot be sourced

- **WHEN** a plausible test command, layout or workflow is not evidenced in the project
- **THEN** the skill asks rather than writing it, because a CLAUDE.md is loaded into every session
  and followed rather than questioned

#### Scenario: A configuration already exists

- **WHEN** the project already has a `CLAUDE.md`
- **THEN** its current content is shown before anything is replaced, since it may carry instructions
  whose reason is not visible in the tree

#### Scenario: An MCP server needs a secret

- **WHEN** a generated stub requires a token
- **THEN** a placeholder and the environment variable name are written, never the value

