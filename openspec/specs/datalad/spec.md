# datalad

## Purpose

The capability-plane wrapper over DataLad and git-annex. DataLad is the harness's connective tissue:
every computation goes through `datalad run` or `datalad container-run`, and every administrative
change is `datalad save`-d, so neither the analysis chain nor the administrative record is ever
broken. DataLad is native to the main thread, as git is: planners run `datalad save`, `datalad run`
and `datalad containers-run` themselves, and record each step in the `DSH-*` lines of the commit
message, which `dsh-log.sh` reads back. There is no doer. The `datalad-cli` plugin supplies the
always-loaded rules, the guard and status hooks, and one `datalad` skill that routes to a reference
per verb. Its behaviour is exercised end to end by `tests/e2e-smoke.sh`.

## Requirements

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
