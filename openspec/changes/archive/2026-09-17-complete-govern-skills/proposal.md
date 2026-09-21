## Why

`README.md` marks four `govern` skills *(planned)* — `init-ledger`, `dmp`, `ethics-track`,
`stamped-assess` — and none had an OpenSpec change. They have been described in the README since the
brownfield retrofit, which means a reader cannot tell them apart from the capabilities that are
merely unbuilt-for-now. Worse, three of them are already **depended upon** by things that do exist:

- `docs/end-to-end-workflow.md` tells the researcher that `govern/dmp` and `govern/ethics-track`
  impose the de-identification obligation.
- `add-deidentify-skill` task 3.3 is blocked on `govern/ethics-track` existing, and has been since
  that change was written.
- `docs/end-to-end-workflow.md`'s "Recommended process" step 2 tells the reader to stand up
  governance with `govern/dmp` and `govern/ethics-track` **before data exists**. That is the earliest
  instruction the harness gives, and it names two skills that are not there.

All four are workflow-plane planners over doers that already exist, so this is prose and ledger
shape rather than new capability. The amended depth convention in `openspec/README.md` is what makes
landing them together correct rather than wide-for-its-own-sake: none of them points at a capability
that is missing.

`govern` is also where the harness's governance claim is most exposed. It is the plugin whose skills
are most likely to be asked a question whose honest answer is "a person decides that" — is this
analysis within our approval, does this DMP satisfy the funder, is this dataset compliant. Every
skill here therefore carries a refusal, and those refusals are the substance of the change.

## What Changes

- **`init-ledger`** — create `project.yaml` in a dataset that has none. Scoped deliberately to the
  **brownfield** case, which is how another group adopts the harness; `project/new-project` already
  covers greenfield, and the two would otherwise duplicate.
- **`dmp`** — author or update a Data Management Plan and extract its promises into `kind: dmp`
  obligations, so the plan becomes operative rather than archival.
- **`ethics-track`** — record IRB/IACUC protocol, approval, expiry and amendments, and surface
  renewals. Unblocks `add-deidentify-skill` task 3.3.
- **`stamped-assess`** — score a research object per STAMPED dimension against the requirement ids
  in `docs/stamped.md`, with `unassessed` as a first-class answer.
- **`plugins/govern/references/stamped.md`** — the normative requirement ids (S.1 … D.3) as a
  plugin-local reference. README has claimed this file exists since the retrofit and it did not.

## Capabilities

### Modified Capabilities

- `govern`: gains four planner skills, and the STAMPED-spectrum requirement gains `unassessed` as a
  distinct answer from a zero score.

## Impact

- New: `plugins/govern/skills/{init-ledger,dmp,ethics-track,stamped-assess}/SKILL.md`,
  `plugins/govern/references/stamped.md`
- Modified: `plugins/govern/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `README.md`, `docs/end-to-end-workflow.md`, `bench/tasks/routing-lifecycle.yaml`,
  `openspec/changes/add-deidentify-skill/tasks.md` (task 3.3 closes)
- No new capability plugin, no new doer, no schema change — `extend-ledger-for-planned-skills`
  already added everything these four write, including the `kind: milestone` and `resolved_by`
  fields, and `obligation.kind` already enumerated `dmp` and `ethics`.
