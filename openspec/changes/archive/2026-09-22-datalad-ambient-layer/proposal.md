## Why

The harness means to manage a data project with DataLad as natively as an assistant handles git.
Today it does not. The assistant starts a session with no knowledge of the dataset's state. Every
DataLad operation is routed through a subagent. Nothing stops a bare `git commit` or `git push` in
an annexed dataset, and a bare `git push` sends the history without the content. The only ambient
piece is a Stop hook, and it silently commits after every turn with a file-list message. That
floods the provenance record the harness exists to protect. It also never runs under OpenCode,
because `bin/install.sh` installs no hooks for that harness.

Claude Code gets git right with three things: a status snapshot in context at session start,
git knowledge in the main thread, and guardrails on tool calls. This change gives DataLad the
same three, on both supported harnesses, without yet touching the planners. That work is
`native-datalad-planners`.

## What Changes

- **Always-loaded DataLad rules.** A short rules file (`plugins/datalad-cli/rules/datalad.md`)
  lives in the main thread:
  - save, don't commit;
  - run with provenance, don't run bare;
  - push, don't `git push`;
  - clean tree before a run;
  - quiet output flags for `get`/`push`.

  Claude Code loads it through the SessionStart hook. OpenCode loads it as a configured
  instructions file.
- **Session-start status.** A new `dsh-status.sh` finds an enclosing dataset and prints a compact
  block: root, branch, clean or dirty, subdatasets, siblings and whether each is ahead or behind,
  and the ledger's stage and open obligations. Outside a dataset it prints nothing.
- **Command guard.** A new `dsh-guard.sh` runs before shell commands inside a dataset:
  - blocks `git commit` and redirects to `datalad save`;
  - blocks `git push` and redirects to `datalad push`;
  - warns on content-changing `git annex` verbs;
  - can be switched off with `DSH_GUARD=0`.
- **Stop behaviour reworked.** **BREAKING** (behaviour, not API). The Stop hook no longer saves by
  default. When the tree is dirty, it reminds the assistant once per distinct dirty state to save
  with a meaningful message. Silent auto-save becomes opt-in with `DATALAD_AUTOSAVE=1`. The old
  opt-out `DATALAD_AUTOSAVE=0` is still honoured, and also turns off the reminder.
- **OpenCode parity.** The installer translates a plugin's `hooks/hooks.json` into a generated
  OpenCode plugin that calls the same scripts:
  - SessionStart → `session.created`
  - PreToolUse(Bash) → `tool.execute.before`
  - Stop → `session.idle`

  It also registers the rules file in OpenCode's `instructions`. No OpenCode-specific file is
  committed to the repository.
- **Documented.** The README and `plugins/datalad-cli/README.md` state exactly what each hook
  does, when it fires, and how to turn it off.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `datalad`: add requirements for the rules file, session status, the command guard, and the
  reminder-first Stop behaviour.
- `harness-distribution`: the installer carries hooks and always-loaded rules to OpenCode.

## Impact

- `plugins/datalad-cli/hooks/` (`hooks.json`, and new and reworked scripts under `scripts/`), new
  `plugins/datalad-cli/rules/datalad.md`, `plugins/datalad-cli/README.md`
- `bin/install.sh`: hook translation and instructions registration for OpenCode
- `tests/`: script unit tests (hook JSON in, exit code and stdout out) and a dry-run check of the
  installer
- `README.md` hooks section
- No planner, doer or schema changes.
