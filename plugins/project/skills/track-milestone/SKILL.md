---
name: track-milestone
description: >
  Add or update a project milestone or deadline in the ledger as a kind: milestone obligation, so it
  is surfaced alongside every other outstanding commitment. Trigger on "add a milestone", "track this
  deadline", "when is the paper due", "project timeline", "milestones", "push back the deadline",
  "what's coming up". Do NOT trigger for a pre-registration or ethics commitment (govern/preregister,
  govern/ethics-track) or to resolve an obligation (govern/obligations).
plane: workflow
stamped: [T]
---

# Skill: track-milestone

Keep the project's dates in the same registry as its promises, so "what's due" has one answer rather
than two.

> Ledger shape, settled in `extend-ledger-for-planned-skills`: a milestone is an `obligations[]`
> entry with `kind: milestone` and a `due` date — not a parallel registry. A milestone *is* a
> commitment with a date, and a second list would duplicate `id`/`description`/`due`/`status` and
> force `govern/obligations` to read two places.

## When to use
- A deadline exists and should be tracked: a submission target, a funder report date, a cohort
  hand-off, a conference abstract.
- A date has moved and the record should say so.
- Do NOT use for a pre-registration (`govern/preregister`), an ethics expiry (`govern/ethics-track`)
  or a DMP promise (`govern/dmp`) — those have their own `kind` and their own owning skill. Use this
  for project-management dates that belong to no other kind.

## Steps

1. **Read what is already tracked** — the `obligations[]` entries, not just the milestones. A new
   deadline often duplicates a commitment another skill already recorded under a different `kind`,
   and two entries for one obligation is how one of them goes stale.
2. **Get the date from the user.** Ask for it rather than deriving it from a conference name, a
   funder's usual cycle, or a typical review period.
3. **Add or update**:
   - **Add** — append `{ id, kind: milestone, description, due, status: pending }` with a unique id.
   - **Move a date** — update `due` on the existing entry. The commit message records what changed
     and why; that is where the slip is visible.
   - **Resolve** — do not. `govern/obligations` closes obligations, and the schema requires
     `resolved_by` naming the action that met it.
4. **Validate.**
   ```bash
   python3 schemas/validate-ledger.py project.yaml
   ```
5. **Save and record in one step.** For a new milestone:
   ```bash
   datalad save -m "$(printf 'track-milestone: add <id>\n\nDSH-Op: track-milestone\nDSH-Stage: govern\nDSH-Obligation: <id> opened')" project.yaml
   ```
   For a moved date, the message body carries the old date, the new one, and the reason:
   ```bash
   datalad save -m "$(printf 'track-milestone: move <id> due <old> -> <new> — <reason>\n\nDSH-Op: track-milestone\nDSH-Stage: govern')" project.yaml
   ```
6. **Report** the milestone as recorded, and what is due next across **all** obligation kinds, not
   only milestones — the point of using one registry is one answer.

## Constraints

- **Never invent a date.** Not from a conference's usual deadline, not from a funder's typical
  reporting cycle, not from "about three months". Ask. A confidently wrong deadline in a tracking
  system is worse than an absent one, because it will be trusted.
- **Never silently move a date.** A slipped deadline is information: update `due` and record the old
  value, the new value and the reason in the commit message. Overwriting a date without recording
  the slip erases the only evidence that the project's timeline changed.
- **Never delete a milestone.** It is resolved forward like any obligation — `met` or `waived`, with
  the reason in the commit that resolves it — and resolution belongs to `govern/obligations`.
- **Never duplicate a commitment another `kind` already records.** If the deadline is a
  pre-registration, an ethics expiry or a DMP deliverable, point at the owning skill instead of
  adding a second entry.
- Do not mark a milestone `met` here; the schema requires `resolved_by`, and the action that met it
  is recorded by whichever skill performed it.
- Keep the ledger schema-valid. Record activity in the commit's `DSH-*` lines, never in
  `project.yaml` `log`; save with `datalad save` yourself.
