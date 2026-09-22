## ADDED Requirements

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
