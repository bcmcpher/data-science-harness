# datalad

## Purpose

The capability-plane wrapper over DataLad and git-annex. DataLad is the harness's connective tissue:
every computation goes through `datalad run` or `datalad container-run`, and every administrative
change is `datalad save`-d, so neither the analysis chain nor the administrative record is ever
broken. This capability is the reference shape for the whole plane — one doer agent
(`plugins/datalad/agents/datalad-doer.md`) plus a vendored `datalad-cli` toolbox of one skill per
CLI verb. Its behaviour is exercised end to end by `tests/e2e-smoke.sh`.
## Requirements
### Requirement: The datalad doer is the only executor of DataLad commands

Planner skills MUST NOT invoke the DataLad CLI. Any dataset creation, provenanced run, save, status
or log inspection, sibling operation, push, or `get` MUST be delegated to the datalad doer, which
owns the mechanics.

#### Scenario: A planner needs to record a result

- **WHEN** any workflow-plane skill reaches the point of committing a change
- **THEN** it delegates to the datalad doer with a plain-language request rather than constructing a
  command itself

### Requirement: The toolbox provides one user-invocable skill per CLI verb

`plugins/datalad-cli/` MUST provide a skill per DataLad verb the harness relies on, each
`user-invocable: true` with an `argument-hint`, and each scoping `allowed-tools` to what that verb
needs. The doer MUST read the matching skill and follow its steps and constraints rather than
improvising the invocation.

#### Scenario: The doer is asked to push to a sibling

- **WHEN** the doer receives a push request
- **THEN** it consults the `datalad-push` skill and constructs the command from that skill's rules

#### Scenario: A user drives a verb directly

- **WHEN** a user invokes a `datalad-*` skill themselves without a planner
- **THEN** the skill runs standalone, because toolbox skills are usable on their own

### Requirement: Provenanced execution is the default run path

The doer MUST execute analysis commands through `datalad run` or `datalad container-run` with
explicit inputs, outputs, and a non-empty message, so the result is replayable by `datalad rerun`.
It MUST NOT run an analysis bare and save the result afterwards.

#### Scenario: A comparison is executed

- **WHEN** a run is requested with inputs and outputs
- **THEN** the resulting commit records the command, its inputs, and its outputs, and `datalad rerun`
  reproduces it

#### Scenario: Message or paths are missing

- **WHEN** a required parameter such as the commit message or an output path is absent or ambiguous
- **THEN** the doer asks the delegating planner rather than guessing a message or inventing a path

### Requirement: The doer refuses to run against a dirty tree

The doer MUST verify a clean working tree before `run` or `container-run`, and MUST verify a DataLad
context exists before operating on a directory.

#### Scenario: Uncommitted changes are present

- **WHEN** a run is requested while `datalad status` reports modifications
- **THEN** the doer stops and asks for a save or confirmation instead of running

### Requirement: Container runs use a registered container

The doer MUST NOT call `datalad container-run` with an unregistered container. It MUST verify
registration with `datalad containers-list` and register with `containers-add` when needed, so the
container image's annex key is recorded in the run commit.

#### Scenario: A provenanced container run

- **WHEN** an analysis is run inside a registered container
- **THEN** the run commit annotates the image's annex key, and a later `datalad rerun` re-fetches
  that exact image

### Requirement: Every operation returns a structured result

The doer MUST report `op`, the exact command executed, `result` (`ok` or `failed`), and where
applicable the commit, outputs, and ending branch, plus notes on tree state or next steps. It MUST
show a constructed command before executing anything that writes to the dataset.

#### Scenario: An operation fails

- **WHEN** a DataLad command returns non-zero
- **THEN** the doer commits nothing further, surfaces the error, and returns `result: failed` with a
  suggested fix rather than leaving outputs half-written

### Requirement: The doer makes no research decisions

The doer MUST NOT decide which analysis to run, whether to promote a comparison, or how to version a
release. It executes and reports; the planner decides.

#### Scenario: An ambiguous request arrives

- **WHEN** the request implies a research choice rather than a mechanical one
- **THEN** the doer returns the question to the planner instead of choosing

### Requirement: Datasets are distributable

A dataset produced through this capability MUST be pushable to a sibling and independently
cloneable, and annexed content MUST be retrievable in the clone with `datalad get`.

#### Scenario: Distributability check

- **WHEN** a dataset is pushed to a sibling and cloned into a fresh location
- **THEN** the clone's history matches and `datalad get` retrieves the annexed file content

### Requirement: DataLad rules are always loaded inside a dataset

`plugins/datalad-cli/rules/datalad.md` MUST state the core DataLad rules in 300 words or fewer:

- save rather than commit;
- run analyses with provenance rather than bare;
- push rather than `git push`;
- keep the tree clean before a run;
- use quiet output flags for `get`, `push` and `clone`;
- if no status block is present in context, run `dsh-status.sh`.

Every supported harness MUST load this file into the main thread, not into a subagent.

#### Scenario: A Claude Code session starts in a dataset

- **WHEN** a session starts with its working directory inside a DataLad dataset
- **THEN** the rules text and the status block are in context before the first user turn

#### Scenario: An OpenCode session starts in a dataset

- **WHEN** an OpenCode session starts with the plugin installed
- **THEN** the rules file is loaded through the configured instructions, whether or not the status
  block could be injected

#### Scenario: The rules outgrow their budget

- **WHEN** the rules file exceeds 300 words
- **THEN** the lint reports an error

### Requirement: Session status is reported at session start

`dsh-status.sh` MUST find the innermost enclosing DataLad dataset. It MUST print:

- the dataset root;
- the current branch;
- clean or dirty, with a count of modified and untracked files;
- the installed subdatasets;
- each sibling, with whether the local branch is ahead of or behind it where that is known without
  network access;
- when `project.yaml` exists, the current stage and the number of open obligations.

It MUST print nothing and exit 0 outside a dataset, or when `datalad` is absent. It MUST NOT touch
the network.

#### Scenario: Outside a dataset

- **WHEN** the session starts in a plain directory or a plain git repository
- **THEN** no status is printed and nothing is added to context

#### Scenario: A sibling is behind

- **WHEN** local `main` has commits the last-fetched `origin/main` lacks
- **THEN** the status names the sibling and the number of unpushed commits

### Requirement: Data-losing git commands are guarded inside a dataset

Before a shell command runs inside a DataLad dataset, `dsh-guard.sh` MUST act as follows:

- block `git commit`, with a message naming `datalad save -m`;
- block `git push`, with a message naming `datalad push --to <sibling>`;
- warn, but not block, on `git annex add`, `drop` and `unlock`;
- warn when `datalad save` or `datalad run` is given more than one `-m`, because DataLad keeps only
  the last message and silently drops the others.

It MUST match commands by token within each `;`/`&&`/`||`/`|` segment, not by substring. It MUST
allow every command when `DSH_GUARD=0` is set.

#### Scenario: A chained commit

- **WHEN** the assistant runs `cd code && git commit -m wip` inside a dataset
- **THEN** the command is blocked, and the assistant is told to use `datalad save -m`

#### Scenario: A quoted mention

- **WHEN** the command is `echo "never git commit here"`
- **THEN** it runs unblocked

#### Scenario: Plain git repository

- **WHEN** `git push` runs in a repository with no `.datalad/`
- **THEN** it runs unblocked

### Requirement: The end-of-turn hook reminds rather than saves by default

At the end of each turn inside a dataset with a dirty tree, the checkpoint hook MUST ask the
assistant to save with a message stating what changed and why, or to tell the user why the
changes stay unsaved. It MUST ask at most once for each distinct dirty state, and MUST NOT ask when
the harness reports that the hook itself caused the continuation. It MUST save silently only when
`DATALAD_AUTOSAVE=1`, and MUST do nothing when `DATALAD_AUTOSAVE=0`. The reminder state MUST be
kept inside `.git/` so it is never committed.

#### Scenario: Unsaved work at the end of a turn

- **WHEN** a turn ends with modified files and no prior reminder for that state
- **THEN** the assistant is prompted once to save meaningfully, and no commit is made by the hook

#### Scenario: The user deliberately leaves work unsaved

- **WHEN** the next turn ends with the same dirty state
- **THEN** no reminder is repeated

#### Scenario: Opted-in auto-save

- **WHEN** `DATALAD_AUTOSAVE=1` and the tree is dirty at the end of a turn
- **THEN** the hook saves with an `Auto-checkpoint` message, as before this change

### Requirement: Hook behaviour is documented where users look

`README.md` and `plugins/datalad-cli/README.md` MUST describe each hook: when it fires, what it
does, what it never does, and which environment variable controls it. They MUST state that
auto-save is off by default.

#### Scenario: A user wonders why nothing was committed

- **WHEN** a user reads the datalad-cli README
- **THEN** it explains the reminder behaviour and how to enable `DATALAD_AUTOSAVE=1`

