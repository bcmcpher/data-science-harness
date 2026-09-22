# datalad-cli

DataLad toolbox (capability plane): one skill per `datalad` subcommand, read by the `datalad` doer
as reference material. Routes data processing and file changes through DataLad for provenance
tracking, following YODA principles for reproducible local analysis projects.

## Skills

| Skill | Slash command | Trigger |
|---|---|---|
| `datalad-init` | `/datalad-init` | Explicit: creating a new dataset or YODA layout |
| `datalad-run` | `/datalad-run` | Auto: executing scripts/pipelines that produce output files |
| `datalad-save` | `/datalad-save` | Auto: saving code changes inside a DataLad dataset |
| `datalad-container-run` | `/datalad-container-run` | Auto: running commands inside Singularity/Apptainer/Docker containers |
| `datalad-status` | `/datalad-status` | Auto: checking dataset state |
| `datalad-diff` | `/datalad-diff` | Auto: comparing dataset versions |
| `datalad-clone` | `/datalad-clone` | Auto: obtaining a copy of a dataset |
| `datalad-get` | `/datalad-get` | Auto: retrieving annexed file content |
| `datalad-push` | `/datalad-push` | Auto: pushing dataset to a sibling |
| `datalad-update` | `/datalad-update` | Auto: updating from a sibling |
| `datalad-siblings` | `/datalad-siblings` | Auto: configuring remote siblings |
| `datalad-subdatasets` | `/datalad-subdatasets` | Auto: managing nested subdatasets |
| `datalad-untrack` | `/datalad-untrack` | Auto: dropping content or removing files |
| `datalad-addurls` | `/datalad-addurls` | Auto: bulk-adding files from URLs |
| `datalad-configuration` | `/datalad-configuration` | Explicit: dataset configuration |
| `datalad-export` | `/datalad-export` | Explicit: exporting to archive or Figshare |
| `datalad-log` | `/datalad-log` | Auto: browsing run history and provenance |
| `datalad-credentials` | `/datalad-credentials` | Auto: setting up authentication credentials |

## Install

```bash
# Session-only (for testing)
claude --plugin-dir ./plugins/datalad-cli

# Permanent install
claude plugin install ./plugins/datalad-cli
```

## Quick workflow

```bash
# 1. Create a YODA dataset
/datalad-init my-analysis

# 2. Add code, link inputs as subdatasets
# (put scripts in code/, link data via datalad clone)

# 3. Run analysis with provenance
/datalad-run python code/analysis.py

# 4. Save code changes
/datalad-save "add preprocessing step to analysis script"
```

## YODA principles enforced

- **P1**: Input data linked as subdatasets (`inputs/`), not copied
- **P2**: Data origins recorded via `datalad download-url` or `datalad clone`
- **P3**: `inputs/` treated as read-only; all results go to `outputs/`

## Hooks and rules

The plugin ships three hooks and one always-loaded rules file. Together they let the assistant
treat a DataLad dataset the way it treats a git repository: it knows the state when the session
starts, the data-losing git commands are stopped, and unsaved work is raised rather than silently
committed. All three hooks do nothing outside a DataLad dataset, and nothing when `datalad` is not
on `$PATH`.

**Auto-save is off by default.** Before this version, the Stop hook committed every dirty tree at
the end of every turn with an `Auto-checkpoint` message. It now reminds instead. To get the old
behaviour back, set `DATALAD_AUTOSAVE=1`.

| Hook | Fires | Does | Never does | Controlled by |
|---|---|---|---|---|
| `dsh-status.sh` (SessionStart) | once when a session starts, resumes, clears or compacts | prints `rules/datalad.md` and a status block: dataset root, branch, clean or dirty counts, subdatasets, siblings ahead or behind, and the ledger stage and open obligations | touch the network (ahead/behind is as of the last fetch); change anything | — |
| `dsh-guard.sh` (PreToolUse, Bash) | before every shell command | blocks `git commit` (use `datalad save -m`) and `git push` (use `datalad push --to`); warns on `git annex add`/`drop`/`unlock` and on a repeated `-m` to `datalad save`/`run` | block `git add`, quoted mentions such as `echo "git commit"`, or anything in a plain git repo | `DSH_GUARD=0` turns it off |
| `datalad-checkpoint.sh` (Stop) | at the end of every turn | if the tree is dirty and this exact state was not already raised, asks the assistant once to save with a message stating what and why, or to tell you why not | commit anything (unless `DATALAD_AUTOSAVE=1`); repeat a reminder for unchanged state; re-fire on the turn it caused | `DATALAD_AUTOSAVE=1` saves silently as before; `DATALAD_AUTOSAVE=0` turns it off |

The reminder remembers the last state it raised in `.git/dsh-last-reminded`, a hash of
`git status --porcelain`. The file lives inside `.git/`, so it is never committed. Leaving work unsaved on
purpose is fine: say so once, and the reminder stays quiet until the changes change.

The guard reads the command by token after splitting on `;`, `&&`, `||` and `|`, and follows
`cd <dir>` and `git -C <dir>`. It acts only when the innermost repository has `.datalad/`, so a
plain git repository nested inside a dataset is left alone. It needs `python3`; without it the
guard allows everything.

```bash
DSH_GUARD=0 claude             # no guard for this session
DATALAD_AUTOSAVE=1 claude      # silent auto-save, the old behaviour
DATALAD_AUTOSAVE=0 claude      # no reminder and no save
```

**Rules.** `rules/datalad.md` (300 words at most, enforced by the lint) states the working rules:
save rather than commit, run with provenance, keep the tree clean before a run, push rather than
`git push`, get before reading, keep output quiet, and ask before publishing. Claude Code gets it
from `dsh-status.sh --with-rules`.

**OpenCode.** `bin/install.sh --harness opencode` generates `plugins/dsh-datalad-cli.js` in the
target, which runs the same three scripts from OpenCode's plugin events. It also adds the
installed `rules/datalad.md` to `opencode.json` `instructions`. See the main README's Install
section for the event mapping.

**Checkpoint commits in run history.** Commits made with `DATALAD_AUTOSAVE=1` start with
`Auto-checkpoint`. To list only run records:
```bash
git log --oneline --grep="\[DATALAD RUNCMD\]"
```

## Structure

```
datalad-cli/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── dsh-status.sh              ← SessionStart
│       ├── dsh-guard.sh               ← PreToolUse (Bash)
│       └── datalad-checkpoint.sh      ← Stop
├── rules/
│   └── datalad.md                     ← always loaded
├── references/                        ← shared across all skills
│   ├── yoda-layout.md
│   ├── subdataset-patterns.md
│   ├── siblings-and-remotes.md
│   ├── annex-content-states.md
│   └── troubleshooting.md
└── skills/
    ├── datalad-init/SKILL.md
    ├── datalad-run/
    │   ├── SKILL.md
    │   └── references/run-command.md
    ├── datalad-save/SKILL.md
    ├── datalad-container-run/
    │   ├── SKILL.md
    │   └── references/container-run.md
    ├── datalad-log/SKILL.md
    ├── datalad-credentials/SKILL.md
    └── [... 12 more skill directories]
```
