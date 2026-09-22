## Why

The harness exists to keep a data project's standards in sync with its state as the project moves:
DMP, ethics, releases, DOIs, provenance. Two parts of the current design create the drift they are
meant to prevent.

1. **DataLad sits behind a subagent.** Every one of the 37 planners routes saves, runs and pushes
   through the datalad doer, a subagent whose body is mostly a table pointing at the same
   `datalad-cli` skills the main thread could load itself. The provenance substrate is treated as
   one more peripheral tool. The intended design is the opposite: the harness handles DataLad as
   natively as an assistant handles git.
2. **Activity is recorded twice.** Each planner saves with a commit message *and* appends a
   near-duplicate entry to the `project.yaml` `log`. The two can disagree. The coordinator already
   carries a rule for when they do.

This change builds on `datalad-ambient-layer`, which puts the DataLad rules, the session status and
the guardrails in the main thread. It removes the indirection and the duplicate record.

## What Changes

- **BREAKING: the datalad doer is retired.** `plugins/datalad/` is removed. Planners run DataLad
  commands directly, as they would git.
- **The toolbox becomes one skill.** The 21 per-verb `datalad-cli` skills are consolidated into a
  single `datalad` skill, and the per-verb detail moves to `references/verbs/<verb>.md`. The skill
  takes a `<verb> [args]` argument, replacing per-verb slash commands such as `/datalad-save`.
  This breaks from the vendored upstream layout, which is an accepted cost.
- **BREAKING: activity moves from the ledger to commit messages.** Every harness commit carries
  `DSH-*:` lines:
  - `DSH-Op` (required)
  - `DSH-Stage`
  - `DSH-Binding: <doer>/<tool>@<version>`
  - `DSH-Product`
  - `DSH-Obligation`

  A new `dsh-log` script reads them, including from `datalad run` commits. Git's own trailer
  parser cannot read those, because DataLad appends its run record after the message.
  `project.yaml` keeps state only: project, products, obligations and contributors. `log` becomes
  an optional legacy field that no skill writes, and that `dsh-log` still reads.
- **Other doers return commands to the planner.** nipoppy, containers, annotate, archive,
  compendium and liab stop handing work "to the datalad doer". Each returns its command, inputs
  and outputs, or the files it wrote, for the planner to run under `datalad run` or to save.
- **Planners rewritten.** In all 37 planners, the "save" and "log it" steps collapse into one
  `datalad save`/`datalad run` step with `DSH-*` lines, and `datalad` leaves `delegates_to`.
  - `log-decision` writes `docs/decisions/<date>-<slug>.md`.
  - `status-report` and the coordinator read `dsh-log` and state, and write nothing.
- **Lint.** The retired phrase "datalad doer" becomes an error anywhere under `plugins/`. The
  plugin counts drop from 22 to 21.
- **The e2e smoke test** asserts `DSH-*` lines via `dsh-log` instead of `log` entries.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `datalad`: the doer requirements are removed, the toolbox becomes one skill, the main thread
  executes, and `dsh-log` is added.
- `project-ledger`: `log` is no longer required, and activity lives in commit `DSH-*` lines.
  `resolved_by` prefers a commit SHA.
- `skill-format`, `structural-lint`: the retired-doer check and the updated delegation rule.
- `analyze`, `annotate`, `containers`, `curate`, `disseminate`, `govern`, `nipoppy`, `process`,
  `project-mgmt`: the requirement text that names the datalad doer or the ledger log is updated.

## Impact

- **Removed:** `plugins/datalad/`, and its entries in `.claude-plugin/marketplace.json`, the README
  counts and tables, and the paper's "8 doers" statements.
- **Rewritten:** `plugins/datalad-cli/`, which consolidates its skills and gains
  `scripts/dsh-log.sh`.
- **Edited:** all 37 planner `SKILL.md` files, 6 doer agents and `project/agents/coordinator.md`.
- **Schema:** `schemas/project.schema.json`, `examples/project.yaml`, `docs/project-ledger.md`.
- **Tests:** `tests/lint-plugins.py`, `tests/lint-plugins-selftest.py`, `tests/e2e-smoke.sh`.
- **Depends on:** `datalad-ambient-layer`, which must land first.
- **Sequencing:** `planner-intent-delegation` follows and is re-scoped to the non-core tools.
