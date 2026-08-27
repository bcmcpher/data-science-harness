## Why

`bids` and `nipoppy` are both real capabilities with working doers, but they are shallow in
different ways. `bids` has no toolbox at all, so `bids-validator` is a detail buried inside the
doer's procedure rather than something a user can invoke or a test can target. `nipoppy` has exactly
one toolbox skill covering the entire CLI, so the doer carries per-command knowledge that
`datalad-cli` would have distributed across verbs.

Separately, `disseminate/reporting-checklist` and `govern/qc-review` cite EQUATOR and COBIDAS by
name with nothing to cite from — `cobidas` appears 3 times and `equator` twice in planner bodies,
and the only EQUATOR material on disk is a single reference file. A reporting checklist assembled
from recall is exactly the failure mode these guidelines exist to prevent.

## What Changes

- A `bids-cli` toolbox making `bids-validator` a first-class skill.
- `nipoppy-cli` extended toward the `datalad-cli` shape — one skill per command class rather than one
  skill for the CLI.
- `references/` sets for EQUATOR and COBIDAS so the two planners cite fixed text.

## Capabilities

### Modified Capabilities
- `bids`: gains a toolbox; validation becomes independently invocable and testable.
- `nipoppy`: gains per-command skills so the doer stops carrying invocation detail.
- `disseminate`: `reporting-checklist` cites bundled guideline text rather than recalling it.

## Impact

- New: `plugins/bids-cli/`, additional `plugins/nipoppy-cli/skills/`,
  `plugins/disseminate/references/cobidas/`, expanded EQUATOR references
- Modified: `plugins/bids/agents/bids-doer.md`, `plugins/nipoppy/agents/nipoppy-doer.md`,
  `plugins/disseminate/skills/reporting-checklist/SKILL.md`,
  `plugins/govern/skills/qc-review/SKILL.md`, `.claude-plugin/marketplace.json`
- Independent of the other capability changes; can be picked up at any time.
