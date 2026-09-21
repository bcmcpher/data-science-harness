## Why

`bids` and `nipoppy` are both real capabilities with working doers, but they are shallow in
different ways. `bids` has no toolbox at all, so `bids-validator` is a detail buried inside the
doer's procedure rather than something a user can invoke or a test can target. `nipoppy` has exactly
one toolbox skill covering the entire CLI, so the doer carries per-command knowledge that
`datalad-cli` would have distributed across verbs.

This change originally carried a third strand — bundling EQUATOR and COBIDAS reference text so
`disseminate/reporting-checklist` and `govern/qc-review` could cite fixed items rather than recall
them. That strand is now `add-guideline-references`, for the reason this change's own task list
predicted: it is a references change bundled into a toolbox change, and it grew once the guidelines'
redistribution terms were actually checked.

## What Changes

- A `bids-cli` toolbox making `bids-validator` a first-class skill.
- `nipoppy-cli` extended toward the `datalad-cli` shape — one skill per command class rather than one
  skill for the CLI.

## Capabilities

### Modified Capabilities
- `bids`: gains a toolbox; validation becomes independently invocable and testable.
- `nipoppy`: gains per-command skills so the doer stops carrying invocation detail.


## Impact

- New: `plugins/bids-cli/`, four `plugins/nipoppy-cli/skills/` in place of one
- Modified: `plugins/bids/agents/bids-doer.md`, `plugins/nipoppy/agents/nipoppy-doer.md`,
  `plugins/nipoppy-cli/README.md`, `.claude-plugin/marketplace.json`, `tests/e2e-smoke.sh`
- Independent of the other capability changes; can be picked up at any time.
