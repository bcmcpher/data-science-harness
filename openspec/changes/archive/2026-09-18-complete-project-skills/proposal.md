## Why

The three skills exist. They landed in `29d1532` — registered, lint-clean, with README's *(planned)*
markers dropped — in a pass that deliberately stopped short of the paperwork and said so in its
commit message. This change is that paperwork: the spec delta, the routing fixtures, and the record
of why each skill refuses what it refuses.

Writing it after the fact is not ideal, and the reason to write it anyway is that the spec is what
survives. The SKILL.md files state their refusals, but a refusal stated only in the prose an
optimizer is about to rewrite is not a constraint — it is a suggestion. `openspec/specs/` is the
half that does not get rewritten to improve a score.

One discovery from that pass needs recording somewhere durable, because it contradicts a README
sentence that stood for months: **there is no `requires:` field.** `grep -rn '^requires:' plugins/`
returns nothing. README described `project/env-check` as verifying the dependencies each plugin
declares in `requires:`, which was unbuildable as specified. Introducing the field would take a
`skill-format` spec change plus `tests/lint-plugins.py` and its selftest. `env-check` reads the
committed manifests and each capability's own gate script instead, and README was corrected.

## What Changes

- **`track-milestone`** — deadlines become `kind: milestone` obligations in the existing
  `obligations[]` registry rather than a parallel list, so "what's due" has one answer. A moved date
  updates `due` and logs the old value with the reason.
- **`env-check`** — reports *declared-but-absent* and *present-but-undeclared* as the two different
  defects they are, and runs each toolbox's own gate script rather than re-implementing its check.
- **`claude-config`** — writes the project's assistant configuration from verified facts only.

No new skills, no new registration, no code. This change adds the spec delta, three routing tasks,
and the reasoning.

## Capabilities

### Modified Capabilities

- `project-mgmt`: gains three planner skills — milestone tracking in the obligations registry,
  environment reporting that separates undeclared from absent, and assistant configuration written
  only from sourceable facts.

## Impact

- Modified: `openspec/specs/project-mgmt/spec.md` (via this change's delta),
  `bench/tasks/routing-lifecycle.yaml`, `docs/end-to-end-workflow.md`
- Already on disk from `29d1532`: `plugins/project/skills/{track-milestone,env-check,claude-config}/`,
  their registration in `plugins/project/.claude-plugin/plugin.json`, and README's entries
- No schema change: `extend-ledger-for-planned-skills` already added `kind: milestone` and
  `resolved_by`
- Routing fixtures 36 → 39
