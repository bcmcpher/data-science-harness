## RENAMED Requirements

- FROM: `### Requirement: Every state change is committed through the datalad doer`
- TO: `### Requirement: Every state change is committed with DataLad`

## MODIFIED Requirements

### Requirement: new-project scaffolds a provenanced, self-describing project

`project/new-project` MUST create a YODA-structured DataLad dataset with a `text2git` configuration,
overlay a plain BIDS skeleton, scaffold an analysis container recipe under `containers/`, initialize
`project.yaml`, and commit the result with `datalad save` in a commit carrying
`DSH-Op: new-project`.

#### Scenario: A new study is started

- **WHEN** a user asks to start a new project and supplies a name
- **THEN** a DataLad dataset exists with a BIDS skeleton, a container recipe, and a `project.yaml`
  whose `project.name` is set, all in one committed state whose message carries
  `DSH-Op: new-project`

#### Scenario: Required information is missing

- **WHEN** the project name or target directory is not given
- **THEN** the skill asks for it briefly rather than inventing a name

### Requirement: Decisions are logged with their rationale

`project/log-decision` MUST write a single decision record file
`docs/decisions/<YYYY-MM-DD>-<slug>.md` capturing what was decided, why, the alternatives
considered, and its scope, and MUST save it with `datalad save` in a commit carrying
`DSH-Op: log-decision`.

#### Scenario: A design choice is made

- **WHEN** a user asks to record why an approach was chosen
- **THEN** one decision record file carries the decision, rationale, alternatives, and scope, and is
  committed with `DSH-Op: log-decision`

### Requirement: Status reports are derived, never hand-edited

`project/status-report` MUST render a human-readable report from `project.yaml` state and the
`dsh-log` history — study header, products and their release and DOI state, outstanding
obligations, contributors, and recent activity — and MUST NOT edit the ledger to make the report
read better. It MUST NOT write to the ledger or make a commit, unless the user asks for the report
to be written to a file.

#### Scenario: A progress report is requested

- **WHEN** a status report is generated
- **THEN** every figure in it traces to a ledger field or a `dsh-log` record, and the ledger and
  history are unchanged

### Requirement: The coordinator orients without acting

The `coordinator` agent MUST read `project.yaml` state, the `dsh-log` history and DataLad state and
report where the project stands and the sensible next action. It MUST be read-only: it recommends
planner skills and MUST NOT run tools that change state.

#### Scenario: Returning to a project

- **WHEN** a user asks "where am I" or "what's next"
- **THEN** the coordinator summarizes current state and names the planner skills that would advance
  it, changing nothing

### Requirement: Every state change is committed with DataLad

Each skill in this plugin MUST save its changes itself with `datalad save`, in a commit carrying
`DSH-Op` and `DSH-Stage` lines, so administrative changes join the same provenance chain as
analysis results.

#### Scenario: Any ledger write

- **WHEN** a skill in this plugin modifies `project.yaml`
- **THEN** the change is committed with `datalad save` with a message naming the operation and a
  `DSH-Op` line naming the skill

### Requirement: Deadlines are tracked as obligations, and a moved date leaves evidence

`project/track-milestone` MUST record a deadline as an `obligations[]` entry with `kind: milestone`
and a `due` date, in the same registry as every other commitment, and MUST obtain the date from the
user rather than deriving it. Moving a date MUST update `due` and record the previous value with the
reason in the message of the commit that makes the change. The skill MUST NOT resolve or delete a
milestone.

#### Scenario: A deadline is tracked

- **WHEN** a submission target or funder report date is recorded
- **THEN** it appears as a `kind: milestone` obligation, and "what's due" is answerable from the
  obligations registry alone

#### Scenario: A deadline moves

- **WHEN** a tracked date slips
- **THEN** `due` is updated and the commit that records it carries `DSH-Op: track-milestone` and a
  message giving the old date, the new date and the reason, rather than the change being invisible

#### Scenario: A date is not supplied

- **WHEN** the deadline is implied by a conference name or a funder's usual cycle but not stated
- **THEN** the skill asks for it rather than inferring one, because a confidently wrong deadline in
  a tracking system is trusted

#### Scenario: The commitment is already tracked under another kind

- **WHEN** the deadline is a pre-registration, ethics expiry or DMP deliverable
- **THEN** the owning skill is named instead of a second entry being created
