# datalad-cli

DataLad toolbox (capability plane). DataLad is the harness's provenance substrate, and the main
thread uses it natively, the way it uses git. DataLad has no doer subagent. Planners run `datalad
save`, `datalad run` and `datalad push` in their own steps. This plugin supplies what makes that
safe: always-loaded rules, three hooks, one `datalad` skill with per-verb references, and
`dsh-log` for reading harness activity back out of the commit history. Follows YODA principles
for reproducible local analysis projects.

## The `datalad` skill

`skills/datalad/SKILL.md` is a single skill that takes `<verb> [args]`. It routes to
`skills/datalad/references/verbs/<verb>.md`, which holds that verb's steps and constraints. These
were one skill per verb until the toolbox was consolidated, so a single trigger decision now
covers the whole toolbox. The old slash commands map as follows:

| Old command | Now | Reference | Trigger |
|---|---|---|---|
| `/datalad-init` | `/datalad init` | `verbs/init.md` | Explicit: creating a new dataset or YODA layout |
| `/datalad-run` | `/datalad run` | `verbs/run.md` | Auto: executing scripts/pipelines that produce output files |
| `/datalad-save` | `/datalad save` | `verbs/save.md` | Auto: saving code changes inside a DataLad dataset |
| `/datalad-container-run` | `/datalad container-run` | `verbs/container-run.md` | Auto: running commands inside Singularity/Apptainer/Docker containers |
| `/datalad-status` | `/datalad status` | `verbs/status.md` | Auto: checking dataset state |
| `/datalad-diff` | `/datalad diff` | `verbs/diff.md` | Auto: comparing dataset versions |
| `/datalad-clone` | `/datalad clone` | `verbs/clone.md` | Auto: obtaining a copy of a dataset |
| `/datalad-get` | `/datalad get` | `verbs/get.md` | Auto: retrieving annexed file content |
| `/datalad-push` | `/datalad push` | `verbs/push.md` | Auto: pushing dataset to a sibling |
| `/datalad-update` | `/datalad update` | `verbs/update.md` | Auto: updating from a sibling |
| `/datalad-siblings` | `/datalad siblings` | `verbs/siblings.md` | Auto: configuring remote siblings |
| `/datalad-subdatasets` | `/datalad subdatasets` | `verbs/subdatasets.md` | Auto: managing nested subdatasets |
| `/datalad-untrack` | `/datalad untrack` | `verbs/untrack.md` | Auto: dropping content or removing files |
| `/datalad-addurls` | `/datalad addurls` | `verbs/addurls.md` | Auto: bulk-adding files from URLs |
| `/datalad-configuration` | `/datalad configuration` | `verbs/configuration.md` | Explicit: dataset configuration |
| `/datalad-export` | `/datalad export` | `verbs/export.md` | Explicit: exporting to archive or Figshare |
| `/datalad-log` | `/datalad log` | `verbs/log.md` | Auto: browsing run history and provenance |
| `/datalad-credentials` | `/datalad credentials` | `verbs/credentials.md` | Auto: setting up authentication credentials |
| `/datalad-fsck` | `/datalad fsck` | `verbs/fsck.md` | Explicit: checking annex integrity |

## Activity history: `dsh-log`

Harness skills record what they did in `DSH-*` lines in the body of the commit that makes the
change. `DSH-Op: <skill>` is required, and `DSH-Stage`, `DSH-Product`, `DSH-Obligation` and
`DSH-Binding` are optional. The lines are not written to the `project.yaml` `log`.
`scripts/dsh-log.sh` reads them back as JSON lines, oldest first:

```bash
plugins/datalad-cli/scripts/dsh-log.sh              # every harness commit
plugins/datalad-cli/scripts/dsh-log.sh -n 20        # extra args go to git log
plugins/datalad-cli/scripts/dsh-log.sh --legacy     # also the old project.yaml log entries
```

It reads commit bodies itself, stopping at DataLad's run-record marker. `git log
--format='%(trailers)'` cannot see these lines on `datalad run` commits, because DataLad appends
its JSON record after the message. The script needs only git, a POSIX shell and awk.

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
/datalad init my-analysis

# 2. Add code, link inputs as subdatasets
# (put scripts in code/, link data via datalad clone)

# 3. Run analysis with provenance
/datalad run python code/analysis.py

# 4. Save code changes
/datalad save "add preprocessing step to analysis script"
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
save rather than commit, record the step with `DSH-*` lines, run with provenance, keep the tree clean before a run, push rather than
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
├── references/                        ← shared background
│   ├── annex-content-states.md
│   ├── global-options.md
│   ├── siblings-and-remotes.md
│   ├── subdataset-patterns.md
│   ├── troubleshooting.md
│   └── yoda-layout.md
├── scripts/
│   └── dsh-log.sh                     ← activity history from DSH-* commit lines
└── skills/
    └── datalad/
        ├── SKILL.md                   ← verb router: /datalad <verb> [args]
        └── references/
            ├── run-command.md
            ├── container-run.md
            └── verbs/                 ← one file per verb (19)
```
