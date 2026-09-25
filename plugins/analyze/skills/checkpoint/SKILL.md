---
name: checkpoint
description: >
  Save the current dataset state with a structured DataLad commit so the Tracking chain is never
  left broken between work sessions. Trigger on "checkpoint", "save my work", "commit the current
  state", "wrap up this session", or at the end of a working session before switching context.
plane: workflow
stamped: [T]
---

# Skill: checkpoint

Take a clean, described snapshot of the dataset. This keeps the provenance chain continuous (a
dirty working tree produces misleading run records downstream). DataLad is native, so you run the
save yourself.

> **The hook raises unsaved work; this skill describes it.** `datalad-cli` ships a `Stop` hook
> (`hooks/scripts/datalad-checkpoint.sh`) that, once per distinct dirty state, reminds the
> assistant to save with a message stating what and why. It does not commit unless the user set
> `DATALAD_AUTOSAVE=1`, which restores a silent `Auto-checkpoint <ts>: <files>` save.
>
> What this skill adds is a *described* snapshot: it composes a message saying what changed and
> saves it with `DSH-Op: checkpoint`, so the checkpoint is in the history `dsh-log` reads. Reach
> for it when the state is worth describing.
>
> Because the hook runs continuously, checkpointing is **not a lifecycle stage** — it belongs to
> the Manage & Comply lane, alongside `project/log-decision`.

## When to use
- The user is pausing/ending a session, or wants intermediate state recorded.
- Do NOT use to record a provenanced *computation* — that is `analyze/run-comparison`
  (`container-run`), which already commits its own outputs. Checkpoint captures hand edits,
  notes, and other loose changes.

## Steps
1. **Inspect state** — run `datalad status` (or read the status block already in context) for
   modified/untracked files and the current branch. If nothing is unsaved, tell the user there is
   nothing to checkpoint and stop.
2. **Compose a message** — summarize what changed since the last save into a meaningful subject
   (e.g. "checkpoint: draft stats.py + participant notes"). Ask the user if the change set is
   ambiguous.
3. **Save** — run it yourself, with exactly one `-m`:
   ```bash
   datalad save -m "$(printf '<message>\n\nDSH-Op: checkpoint\nDSH-Stage: <current-stage>')"
   ```
4. **Report** — the commit sha and current branch.

## Constraints
- Run DataLad yourself; it is native, not a doer.
- Always use a meaningful message — never "wip"/"save"/placeholder.
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`.
- Do not force-save over a comparison mid-run; if a `container-run` is in progress, let it finish
  (it commits its own outputs).
