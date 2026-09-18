## Why

Fifteen planned workflow-plane skills are about to land, grouped into five changes by owning plugin.
Four of them write to `project.yaml`, and `schemas/project.schema.json` is
`additionalProperties: false` at every level — the top-level object and each of `$defs/product`,
`$defs/obligation`, `$defs/contributor`, `$defs/logEntry`. A closed schema is the right choice, and
it means any skill that needs a field the schema lacks cannot land without editing the schema.

The repository holds two conventions that pull against each other here. `openspec/README.md` says
**Ledger-first — formalize the schema before the skills that write to it**;
`add-deidentify-skill` task 2.2 says the schema grows **in the same commit** as the skill that
writes to it. The second is the right rule for one skill in isolation. Applied to five concurrent
changes it means five separate edits to one closed schema, each designing its own corner of it, with
the conflicts discovered at merge time rather than at design time. Ledger-first wins for this pass.

Auditing what the fifteen skills actually need turned out to be a smaller job than expected, because
most of the shape is already there:

- `$defs/obligation.kind` already enumerates `dmp` and `ethics`, so `govern/dmp` and
  `govern/ethics-track` register obligations with no schema change at all.
- `$defs/logEntry.op` has **no enum**, so any skill can append an activity entry freely. That covers
  `stamped-assess`, `plan-analysis`, `plot`, `gen-report`, `merge-data` and `claude-config` entirely.

What is genuinely missing is three things, and one of them is a question this repository has already
run into and deferred.

## What Changes

- **`obligation.kind` gains `milestone`**, so `project/track-milestone` records a deadline as a
  first-class commitment rather than as `kind: other` with the meaning carried in prose.
- **`product` gains `submissions[]`**, so `disseminate/submission-track` records where a product was
  sent and what came back. Submission state is *not* folded into `product.status`: a submitted paper
  is still `in-progress`, a rejected one is still `in-progress`, and collapsing the two would make
  `status` mean two things and lose the history of a resubmission.
- **`obligation` gains `resolved_by`**, and an obligation at `status: met` MUST carry it. This
  settles the question `add-deidentify-skill` task 2.2 blocks on: how an obligation is resolved by
  pointing at a recorded action rather than by assertion. `ref` is documented as an *external*
  reference and stays that way; a commit SHA or a log timestamp is internal evidence, and the
  distinction matters to whoever later has to check the claim.

## Capabilities

### Modified Capabilities

- `project-ledger`: obligations gain a milestone kind and a required resolution reference; products
  gain a submission history.

## Impact

- Modified: `schemas/project.schema.json`, `examples/project.yaml`, `docs/project-ledger.md`
- `schemas/validate-ledger.py` is unchanged — it is a thin driver over the schema, so the new
  conditional requirement is enforced without touching the script.
- Additive for every ledger on disk. The one conditional requirement (`met` implies `resolved_by`)
  can in principle reject an existing ledger, but nothing in the repository has a `met` obligation,
  and the alternative is a status flip that records nothing about why.
- No skill is written here. This change only makes the five skill changes that follow
  independent of one another.
