---
name: datalad
description: >
  Use inside a DataLad dataset (.datalad/ present) for any DataLad operation, and instead of
  git add, git commit, git push or git clone there. Trigger on "save my changes", "commit this",
  "run with provenance", "run in a container", "push to the sibling", "get this file", "clone a
  dataset", "add a sibling", "what changed", "show run history", "drop file content", "create a
  DataLad dataset", or /datalad <verb>. Routes by verb to a reference with the steps and
  constraints for that verb. Do NOT trigger in plain git repos without .datalad/ — use git there.
argument-hint: '<verb> [args]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Glob, Grep
---

# Skill: datalad

One entry point for the DataLad toolbox. The always-loaded DataLad rules cover the everyday
pattern. This skill holds the detail for each verb. Read the verb's reference before you build
an operation you are unsure of. Do not improvise the invocation.

## Steps

1. **Pick the verb.** Take it from the first word of the arguments (`/datalad save "msg" code/`).
   Otherwise infer it from the request. If it is still ambiguous, ask.
2. **Read the reference.** Read `${CLAUDE_PLUGIN_ROOT}/skills/datalad/references/verbs/<file>.md`
   from the table below and follow its steps and constraints. Treat the remaining arguments as that
   reference's arguments.
3. **Record harness work.** A save or run made for a harness skill carries the skill's `DSH-*`
   lines in its single `-m` message, as the rules describe. A save the user drives directly needs
   no `DSH-*` lines.

| Verb (DataLad commands) | Reference |
|---|---|
| `init` (`create`) | `verbs/init.md` |
| `save` | `verbs/save.md` |
| `status` | `verbs/status.md` |
| `diff` | `verbs/diff.md` |
| `run` (`run`, `rerun`, `download-url`) | `verbs/run.md` |
| `container-run` (`containers-run`, `containers-add`, `containers-list`, `containers-remove`) | `verbs/container-run.md` |
| `log` (run records, provenance) | `verbs/log.md` |
| `clone` (`clone`, `install`) | `verbs/clone.md` |
| `get` | `verbs/get.md` |
| `untrack` (`drop`, `remove`, `unlock`) | `verbs/untrack.md` |
| `siblings` (`siblings`, `create-sibling-*`) | `verbs/siblings.md` |
| `push` | `verbs/push.md` |
| `update` | `verbs/update.md` |
| `subdatasets` (`subdatasets`, `foreach-dataset`) | `verbs/subdatasets.md` |
| `addurls` | `verbs/addurls.md` |
| `configuration` | `verbs/configuration.md` |
| `export` (`export-archive`, `export-to-figshare`) | `verbs/export.md` |
| `credentials` | `verbs/credentials.md` |
| `fsck` (annex integrity) | `verbs/fsck.md` |

Shared background lives in `${CLAUDE_PLUGIN_ROOT}/references/`. It covers annex content states,
global options, siblings and remotes, subdataset patterns, troubleshooting and the YODA layout.
The verb references say when to load each file.

## Constraints

- Never use `git add`, `git commit`, `git push` or `git annex add` inside a DataLad dataset. The
  DataLad verb handles annexed content and subdatasets. Raw git can corrupt annex state.
- Pass exactly one `-m` to `datalad save` and `datalad run`. DataLad keeps only the last one.
- Confirm with the user before an outward-facing or hard-to-reverse step: creating a sibling,
  pushing, dropping content, or removing a dataset.
- Outside a DataLad dataset, say so and use plain git. Do not create a dataset unasked.
