## Why

Both skills exist. They landed in `29d1532` with their OpenSpec change deliberately deferred. This
change is the deferred half: the spec delta, two routing fixtures, and the reasoning behind the
refusals.

The two skills share a failure mode that makes the spec worth having. Neither of them fails loudly
when it is wrong. A wrong join does not raise — it produces a table. Joining on a mistyped id
silently drops every row; joining on a non-unique key silently multiplies them; and both outcomes
are a file of the expected shape that analysis will proceed on. A guessed level coding does not
raise either — it produces a `participants.json` that reads as authoritative documentation, and
`1 = male` and `1 = female` are both common enough that a guess is a coin flip someone will later
cite.

So the requirements here are mostly about what must be *reported* alongside the output: the row and
column arithmetic that makes a silent drop visible, and the list of columns that remain undescribed.

## What Changes

- **`merge-data`** — the join key is supplied rather than inferred, key overlap is checked before
  the merge runs, and every report carries rows in / rows out / keys matched / keys dropped per
  side. No silent value reconciliation, no imputation, no in-place edit of a source table.
- **`gen-data-dict`** — the skeleton is derived from the data, the meanings come from the user or
  the `annotate` doer, and an undescribed column gets no entry and appears in the report. Restating
  a column's name as its Description is refused because it hides the gap.

No new skills, no new registration, no code.

## Capabilities

### Modified Capabilities

- `curate`: gains tabular merging whose arithmetic is part of its output, and data-dictionary
  generation that refuses to supply a meaning it was not given.

## Impact

- Modified: `openspec/specs/curate/spec.md` (via this change's delta),
  `bench/tasks/routing-lifecycle.yaml`, `docs/end-to-end-workflow.md`
- Already on disk from `29d1532`: `plugins/curate/skills/{merge-data,gen-data-dict}/` and their
  registration
- No schema change; both write files in the dataset rather than ledger structure
- Routing fixtures 39 → 41
