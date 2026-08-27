## Why

`model:` is the field nothing in this repo knows about. No agent declares it. The lint's
`check_agent` ignores it entirely, so a typo would be silent. `templates/skill/SKILL.md` documents
`plane`, `stamped`, and `delegates_to` but not `model`. And `bin/install.sh`'s OpenCode path strips
`name:` and `tools:` and inserts `mode: subagent`, but passes `model:` through verbatim — OpenCode
expects provider-prefixed identifiers, so a bare `haiku` would install and then fail to resolve.

`docs/writing/SPEC.md:72` already declares a symbolic `model: strong-writing` for an agent that was
never built, which is what an undocumented, unvalidated field produces.

There is a real reason to want the field: `bids-doer` and `coordinator` are read-only. They read
state and report; they do not need a frontier model. Pinning them is a straightforward cost
reduction. But pinning anything before the field is validated and translated would ship an
unverified value into every install.

This is cross-cutting and cheap, and it is worth doing early for exactly that reason — every
`model:` added before it lands is unvalidated.

## What Changes

- `tests/lint-plugins.py` validates `model:` against an allowed set.
- `bin/install.sh` translates or strips `model:` on the OpenCode path.
- `templates/skill/SKILL.md` and the README's Universal Skill Format section document the field.
- Only then: pin `model:` on the read-only doers (`bids-doer`, `coordinator`). Mutating doers
  (`datalad`, `archive`, `containers`, `nipoppy`) stay unpinned.

## Capabilities

### Modified Capabilities
- `skill-format`: `model:` becomes a documented, defined optional field rather than an unknown one.
- `structural-lint`: gains validation of `model:`, so a typo fails rather than passing silently.
- `harness-distribution`: the OpenCode translation handles `model:` instead of passing it through.

## Impact

- Modified: `tests/lint-plugins.py`, `tests/lint-plugins-selftest.py`, `bin/install.sh`,
  `templates/skill/SKILL.md`, `README.md`, `plugins/bids/agents/bids-doer.md`,
  `plugins/project/agents/coordinator.md`
- Ordering matters: validation and translation land before any agent declares the field.
