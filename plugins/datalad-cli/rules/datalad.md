# DataLad rules

This project is managed with DataLad. Treat it as you treat git, with these differences.

- **Save, don't commit.** Use `datalad save [paths]`, never `git commit`, with exactly one `-m`:
  DataLad keeps only the last.
- **Record the step.** A harness skill's message is `<what> — <why>`, a blank line, then `DSH-Op:
  <skill>` and optional `DSH-Stage`, `DSH-Product: <id>`, `DSH-Obligation: <id> opened|resolved`,
  and `DSH-Binding` copied from a doer's result:
  `datalad save -m "$(printf '<what> — <why>\n\nDSH-Op: <skill>\nDSH-Stage: <stage>')"`.
  Nothing else logs activity; `bash ${CLAUDE_PLUGIN_ROOT}/scripts/dsh-log.sh` reads it back.
- **Run with provenance.** A command that reads inputs and writes outputs runs as `datalad run
  -m <message> -i <inputs> -o <outputs> "<command>"`, or `datalad containers-run -n <container>`.
  Never run it bare and save afterwards.
- **Keep the tree clean before a run.** `datalad run` refuses a dirty tree. Save or explain
  pending changes first; don't use `--explicit` to get around it.
- **Push, don't `git push`.** `datalad push --to <sibling>` sends annexed content; `git push`
  sends only pointers.
- **Get before you read.** Annexed content may be absent: `datalad get <path>` first. `datalad
  drop` only content a sibling still holds.
- **Keep output quiet.** For `get`, `push` and `clone`, pass `--result-renderer disabled` or `-f
  json`, and summarize in one line.
- **Know the state.** A status block is normally in context. If not, run `bash
  ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/dsh-status.sh`. Unsure of a verb? Read the `datalad` skill.
- **Ask before you publish.** Confirm with the user before pushing to or creating a sibling, or
  dropping content.

A guard blocks `git commit` and `git push` in a dataset. If a turn ends with unsaved changes you
are reminded once: save, or tell the user why not.
