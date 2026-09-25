## ADDED Requirements

### Requirement: DataLad commands run in the main thread

Planner skills MUST run DataLad commands directly, the way they would run git. The commands
covered are dataset creation, provenanced runs, save, status, log, sibling operations, push and
get. No subagent MAY be interposed for DataLad operations. A planner MUST NOT declare `datalad` in
`delegates_to`.

#### Scenario: A planner records a result

- **WHEN** a workflow-plane skill reaches the point of committing a change
- **THEN** it runs `datalad save` itself with a message carrying its `DSH-*` lines, and no
  subagent is spawned

#### Scenario: Another doer returns a mutating command

- **WHEN** the nipoppy doer returns a constructed command with `run_via: datalad-run`
- **THEN** the planner runs it under `datalad run` with the doer's declared inputs and outputs

### Requirement: Harness commits carry DSH lines

Every commit a harness skill makes MUST have a single-message body containing exactly one
`DSH-Op: <skill-name>` line. It MAY contain `DSH-Stage`, and zero or more each of
`DSH-Binding: <doer>/<tool>@<version>`, `DSH-Product: <id>` and
`DSH-Obligation: <id> <opened|resolved>`. No other `DSH-` key is defined. A `DSH-Binding` value
MUST be copied from a doer's structured result, never assumed by the planner. The message MUST be
passed as one `-m` argument, because `datalad save` keeps only the last of several.

#### Scenario: A save commit

- **WHEN** `govern/ethics-track` saves an amendment
- **THEN** the commit message has a subject stating what and why, followed by a paragraph with
  `DSH-Op: ethics-track` and `DSH-Stage: govern`

#### Scenario: A doer chose the tool

- **WHEN** the archive doer mints through its `auto` selection and reports `backend: zenodo`
- **THEN** the release commit carries `DSH-Binding: archive/zenodo@<reported version>`

### Requirement: dsh-log reads the activity history

`plugins/datalad-cli/scripts/dsh-log.sh` MUST print one JSON object per commit that has a `DSH-Op`
line. Each object MUST include `sha`, `ts`, `subject`, `run` (true for `datalad run` commits) and
the parsed `DSH-*` fields. It MUST read lines from `datalad run` commits by stopping at the run
record marker, rather than relying on git's trailer parser. With `--legacy`, it MUST also print
each `project.yaml` `log` entry in the same shape with `sha: null`. It MUST need nothing beyond
git and a POSIX shell.

#### Scenario: A run commit

- **WHEN** a `datalad run` commit's message body contains `DSH-Op: run-pipeline`
- **THEN** `dsh-log` returns it with `run: true`, even though `git log --format='%(trailers)'`
  returns nothing for that commit

#### Scenario: A ledger written before this change

- **WHEN** `dsh-log --legacy` runs on a dataset whose `project.yaml` has `log` entries
- **THEN** those entries appear alongside commit-derived entries in timestamp order

### Requirement: The toolbox is one skill with per-verb references

`plugins/datalad-cli/` MUST provide a single `datalad` skill. The skill MUST be user-invocable
with an argument of the form `<verb> [args]`, and MUST route by verb to
`references/verbs/<verb>.md` for every DataLad verb the harness relies on. Each verb reference
MUST keep the steps and constraints of the per-verb skill it replaces. The main thread MUST read
the matching verb reference before constructing an operation it is unsure of, rather than
improvising the invocation.

#### Scenario: A push is needed

- **WHEN** a planner reaches a push step
- **THEN** the main thread consults `references/verbs/push.md` and constructs the command from its
  rules

#### Scenario: A user drives a verb directly

- **WHEN** a user invokes `/datalad save "message"` without a planner
- **THEN** the skill runs standalone, because the toolbox is usable on its own

## MODIFIED Requirements

### Requirement: Provenanced execution is the default run path

Analysis commands MUST be executed through `datalad run` or `datalad containers-run`, with explicit
inputs, outputs, and a non-empty message carrying the `DSH-*` lines, so the result is replayable by
`datalad rerun`. An analysis MUST NOT be run bare and saved afterwards.

#### Scenario: A comparison is executed

- **WHEN** a run is requested with inputs and outputs
- **THEN** the resulting commit records the command, its inputs, and its outputs, and `datalad rerun`
  reproduces it

#### Scenario: Message or paths are missing

- **WHEN** a required parameter such as the commit message or an output path is absent or ambiguous
- **THEN** the planner asks the user rather than guessing a message or inventing a path

### Requirement: Runs refuse a dirty tree

A clean working tree MUST be verified before `run` or `containers-run`, and a DataLad context MUST
be verified before operating on a directory.

#### Scenario: Uncommitted changes are present

- **WHEN** a run is about to start while `datalad status` reports modifications
- **THEN** the planner stops and asks for a save or confirmation instead of running

### Requirement: Container runs use a registered container

`datalad containers-run` MUST NOT be called with an unregistered container. Registration MUST be
verified with `datalad containers-list`, and the container MUST be registered with
`containers-add` when needed, so the container image's annex key is recorded in the run commit.

#### Scenario: A provenanced container run

- **WHEN** an analysis is run inside a registered container
- **THEN** the run commit annotates the image's annex key, and a later `datalad rerun` re-fetches
  that exact image

## RENAMED Requirements

- FROM: `### Requirement: The doer refuses to run against a dirty tree`
- TO: `### Requirement: Runs refuse a dirty tree`

## REMOVED Requirements

### Requirement: The toolbox provides one user-invocable skill per CLI verb

**Reason**: The 19 per-verb skills are consolidated into one `datalad` skill, so a single trigger
decision covers the toolbox. The per-verb steps and constraints are kept verbatim as references.
**Migration**: See "The toolbox is one skill with per-verb references". `/datalad-<verb>` becomes
`/datalad <verb>`; `plugins/datalad-cli/README.md` lists the mapping.

### Requirement: The datalad doer is the only executor of DataLad commands

**Reason**: The doer is retired. DataLad is the substrate and runs in the main thread, like git.
**Migration**: See "DataLad commands run in the main thread". Planners run the commands directly,
and `datalad` is dropped from `delegates_to`.

### Requirement: Every operation returns a structured result

**Reason**: The structured result existed to hand results from the doer back to its planner. With
no doer, the planner sees the command output directly.
**Migration**: Planners report the commit and outputs themselves. Activity is recorded in the
`DSH-*` lines ("Harness commits carry DSH lines").

### Requirement: The doer makes no research decisions

**Reason**: This separated a subagent from its planner. Once DataLad runs in the planner's own
thread, there is no second party to separate.
**Migration**: None. Research decisions remain the planner's by definition, per `skill-format`.
