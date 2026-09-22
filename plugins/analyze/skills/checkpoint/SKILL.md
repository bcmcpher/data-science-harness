---
name: checkpoint
description: >
  Save the current dataset state with a structured DataLad commit so the Tracking chain is never
  left broken between work sessions. Trigger on "checkpoint", "save my work", "commit the current
  state", "wrap up this session", or at the end of a working session before switching context.
plane: workflow
stamped: [T]
delegates_to: [datalad]
---

# Skill: checkpoint

Take a clean, described snapshot of the dataset. This keeps the provenance chain continuous (a
dirty working tree produces misleading run records downstream). You delegate the save to the
**datalad doer**.

> **The hook raises unsaved work; this skill describes it.** `datalad-cli` ships a `Stop` hook
> (`hooks/scripts/datalad-checkpoint.sh`) that, once per distinct dirty state, reminds the
> assistant to save with a message stating what and why. It does not commit unless the user set
> `DATALAD_AUTOSAVE=1`, which restores a silent `Auto-checkpoint <ts>: <files>` save.
>
> What this skill adds is a *described* snapshot and a ledger entry: it composes a message saying
> what changed and appends to `project.yaml`. Reach for it when the state is worth describing.
>
> Because the hook runs continuously, checkpointing is **not a lifecycle stage** — it belongs to
> the Manage & Comply lane, alongside `project/log-decision`.

## When to use
- The user is pausing/ending a session, or wants intermediate state recorded.
- Do NOT use to record a provenanced *computation* — that is `analyze/run-comparison`
  (`container-run`), which already commits its own outputs. Checkpoint captures hand edits,
  notes, and other loose changes.

## Steps
1. **Inspect state** — delegate to the datalad doer:
   > "status: report modified/untracked files in this dataset and the current branch."
   If nothing is unsaved, tell the user there is nothing to checkpoint and stop.
2. **Compose a message** — summarize what changed since the last save into a meaningful `-m`
   (e.g. "checkpoint: draft stats.py + participant notes"). Ask the user if the change set is
   ambiguous.
3. **Save** — delegate to the datalad doer:
   > "save: `datalad save -m '<message>'` on the current branch."
4. **Log it** — append to `project.yaml`:
   `{ ts, op: checkpoint, stage: <current-stage>, note: "<message>", branch: <branch> }`.
5. **Report** — the commit sha and current branch.

## Constraints
- Delegate status and save to the datalad doer; never call datalad directly.
- Always use a meaningful message — never "wip"/"save"/placeholder.
- Keep `project.yaml` append-only.
- Do not force-save over a comparison mid-run; if a `container-run` is in progress, let it finish
  (it commits its own outputs).
