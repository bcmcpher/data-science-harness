## Why

Three merges landed in two days — `add-compendium-capability`, `add-containers-toolbox`, and the
merge of `openspec-and-paper` into `main`. The structure moved; the prose describing it did not.
The README now contradicts itself inside a single file:

- `README.md:5` says **"Every capability now has a toolbox"**; the `openspec/` section said the
  capability plane's "remaining hole (`containers` has no toolbox) has no change proposing one yet",
  three lines after a table listing `containers-cli` with three skills.
- Two links point at `openspec/changes/add-compendium-capability`, archived the day before, and the
  sentences around them still describe `jupyter-book`, `repo2data` and the MCP scaffold as unbuilt —
  all three shipped, and `agent-bundle` already delegates to the `compendium` doer.
- The `compendium-cli` row claims **"1 skill + offline tool check"**; there are four.
- `.claude-plugin/marketplace.json` enumerates six capability-plane doers; eight ship. Its status
  sentence still reads "the capability plane is uneven".
- `plugins/containers/.claude-plugin/plugin.json` still describes the capability the way the spec
  says was backwards — an Apptainer build that converts *from* a recipe, rather than
  Dockerfile → OCI → `.sif` across several named environments.
- `docs/motivation.md` and `docs/funding/catalyst-fit.md` state "74 skills" and "21 plugins".
- `docs/end-to-end-workflow.md` directs readers to `openspec/changes/` as "the authoritative list of
  what is being built". It is empty. The same file names `containers` skills `build-container` and
  `run-container`, neither of which exists.
- `plugins/analyze/skills/checkpoint/SKILL.md` says an automatic session-end `Stop` hook is
  "intentionally deferred". `plugins/datalad-cli/hooks/hooks.json` ships exactly that hook, and it
  fires once per *turn*.

None of this was caught, and that is the more interesting half. `tests/lint-plugins.py --strict`
returned 0/0 across every one of these. `check_doc_claims` verifies the repo-wide plugin count,
which stayed correct while an individual plugin's row went stale; it reads no links; and
`check_marketplace_claims` reads the description's planner *count* but not the doer names it
enumerates. The drift lived precisely in the gaps between the existing checks.

## What Changes

- **Extend the lint first**, so the fixes are verified rather than asserted: per-plugin skill counts
  in README tables, links into `openspec/changes/`, and the marketplace's enumerated doer list. Each
  new rule was run against the unfixed tree and observed to fail before anything was corrected.
- Correct every claim above against disk.
- **Collapse Stage 4 — Checkpoint.** Checkpointing is not a lifecycle stage. `datalad-cli` ships a
  `Stop` hook that saves any dirty tree once per turn; `examples/project.yaml` has always logged
  `{ op: checkpoint, stage: analyze }` — an action *inside* a stage; and the walkthrough itself
  conceded "analysis is iterative — loop Stage 3 ↔ 4". Checkpointing moves to the Manage & Comply
  lane, where the hook already put it, and the lifecycle renumbers 0–7. **The `checkpoint` skill
  stays**: the hook writes a mechanical message, the skill writes a described one and a ledger entry.
- Narrow one claim that is true but reads wider than it is: `containers` is the exception among the
  *gated* capabilities, not the only real-tool path in the repository — `datalad` is a hard
  precondition of the e2e suite and runs unconditionally.

## Capabilities

### Modified Capabilities
- `structural-lint`: the doc-claims check gains per-plugin skill counts and change-link resolution;
  the marketplace check gains the enumerated doer list.

## Impact

- Modified: `tests/lint-plugins.py`, `tests/lint-plugins-selftest.py`, `README.md`,
  `.claude-plugin/marketplace.json`, `plugins/containers/.claude-plugin/plugin.json`,
  `plugins/compendium/.claude-plugin/plugin.json`,
  `plugins/analyze/skills/checkpoint/SKILL.md`, `docs/motivation.md`,
  `docs/funding/catalyst-fit.md`, `docs/end-to-end-workflow.md`,
  `openspec/specs/govern/spec.md`, `openspec/specs/disseminate/spec.md`
- The stage renumber touches no machinery: `schemas/project.schema.json` types `stage` as a free
  string, and `examples/project.yaml` and `bench/tasks/routing-lifecycle.yaml` key on stage and
  skill *names*, never numbers.
- Blocks nothing. The paper outline and the slide deck both draw on this prose, so it goes first.
