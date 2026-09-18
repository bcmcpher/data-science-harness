## Why

`disseminate/submission-track` exists. It landed in `29d1532` with its OpenSpec change deliberately
deferred. This change is that half: the spec delta, one routing fixture, and the correction of three
documents that still describe the plugin as having eight skills.

The skill's own reason for existing is narrow and worth stating: a submission history is the one
part of a project's record that is routinely destroyed by being updated. The natural implementation
— a `venue`, `status` and `decision` field on the product — loses the first rejection the moment the
paper is sent somewhere else, and that is exactly the information a co-author, a funder report, or a
later reader of the project's process asks for. So the shape settled in
`extend-ledger-for-planned-skills` is an append-only `submissions[]` history, and the requirement
here is that a resubmission appends.

The second half is the refusal. This skill writes into the file a funder report is generated from,
and the tempting entries are the ones that have not happened yet: an anticipated acceptance, a
status inferred from elapsed time, a decision paraphrased into something more favourable.

## What Changes

- **`submission-track`** — venue, date, status and decision recorded as an append-only
  `submissions[]` history on the product. A resubmission appends rather than overwriting,
  `product.status` stays `in-progress` throughout, and no outcome is recorded before it happens.
- Three stale counts corrected: `openspec/specs/disseminate/spec.md` said the plugin provides
  "eight planner skills", and both `README.md`'s table row and the `disseminate` entry in
  `.claude-plugin/marketplace.json` enumerated eight by name, omitting `submission-track`.

No new skills, no new registration, no code.

## Capabilities

### Modified Capabilities

- `disseminate`: gains submission tracking as an append-only history, distinct from the product's
  release status.

## Impact

- Modified: `openspec/specs/disseminate/spec.md` (via this change's delta, plus the Purpose count),
  `README.md`, `.claude-plugin/marketplace.json`, `bench/tasks/routing-lifecycle.yaml`,
  `docs/end-to-end-workflow.md`
- Already on disk from `29d1532`: `plugins/disseminate/skills/submission-track/` and its registration
- No schema change: `extend-ledger-for-planned-skills` added `submissions[]`
- Routing fixtures 41 → 42, which restores the suite's "one task per built planner skill" claim in
  full
