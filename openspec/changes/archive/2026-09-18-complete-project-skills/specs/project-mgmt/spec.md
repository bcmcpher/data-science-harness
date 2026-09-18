## ADDED Requirements

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
