# DataLad rules

This project is managed with DataLad. Treat it as you treat git, with these differences.

- **Save, don't commit.** Record changes with `datalad save -m "<what> — <why>" [paths]`, never
  `git commit`. Use one `-m`: DataLad keeps only the last. Put a body after a blank line inside
  that one message.
- **Run with provenance.** A command that reads inputs and writes outputs runs as
  `datalad run -m "<why>" -i <inputs> -o <outputs> "<command>"`, or `datalad containers-run -n
  <container>` when it needs a container. Running an analysis bare and saving afterwards loses
  the record of how the results were made.
- **Keep the tree clean before a run.** `datalad run` refuses a dirty tree. Save or explain
  pending changes first; do not reach for `--explicit` to get around it.
- **Push, don't `git push`.** `datalad push --to <sibling>` sends annexed content with the
  history. A bare `git push` sends only pointers.
- **Get before you read.** An annexed file may have no local content. Run `datalad get <path>`
  first, and `datalad drop` only content a sibling still holds.
- **Keep output quiet.** For `get`, `push` and `clone`, pass `--result-renderer disabled` or
  `-f json`, then summarize in one line.
- **Know the state.** A DataLad status block is normally in context at session start. If not,
  run `bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/dsh-status.sh` before changing anything.
- **Ask before you publish.** Pushing to or creating a sibling, and dropping content, are
  outward-facing or hard to reverse. Confirm with the user first.

A guard blocks `git commit` and `git push` inside a dataset and names the DataLad command to use.
When a turn ends with unsaved changes you are reminded once to save them meaningfully. Either
save, or tell the user why they stay unsaved.
