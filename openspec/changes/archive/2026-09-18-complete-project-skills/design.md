## Context

Three `project` planners landed in `29d1532` without a change behind them. This one records the
decisions they encode. It is written against skills that already exist, so its tasks are checked on
arrival; what is new here is the spec delta and the routing fixtures.

## Goals / Non-Goals

**Goals:**
- The refusals live in `openspec/specs/`, not only in skill prose.
- The `requires:` correction is recorded where a future reader will find it.
- `bench/tasks/routing-lifecycle.yaml` covers every built planner again.

**Non-Goals:**
- **Adding a `requires:` field.** It would need a `skill-format` spec change, lint work and selftest
  cases, and would duplicate the manifests that already declare these tools.
- **Installing anything from `env-check`.** It reports. Installing a tool to make a check pass
  destroys the finding.
- **A second milestone registry.** Milestones are obligations with a date.
- **Resolving obligations from `track-milestone`.** `govern/obligations` closes them, and the schema
  requires `resolved_by`.

## Decisions

- **A milestone is an `obligations[]` entry with `kind: milestone`, not a parallel `milestones[]`
  list.** Settled in `extend-ledger-for-planned-skills`. A second list would duplicate
  `id`/`description`/`due`/`status` and force `govern/obligations` to read two places, which is how
  one of them goes stale. The cost is that a milestone inherits the obligation lifecycle — it is
  resolved forward, never deleted — and that is the right cost.
- **A moved deadline updates `due` and logs the old value.** Overwriting a date silently erases the
  only evidence the timeline changed, and a slip is information: it is usually the thing a status
  report should lead with.
- **`env-check` reports two defects, not one.** *Declared-but-absent* is a setup step.
  *Present-but-undeclared* is a Portability defect (`P.1`, undocumented host state) that works today
  and breaks for the next person. They have opposite fixes, and merging them tells the user to
  install something when the fix is a manifest line.
- **`env-check` runs each capability's gate script rather than re-implementing the check.** A second
  implementation of "is SNOMED configured" will eventually disagree with the one the doer acts on.
  It also means exit `2` (usage error) is reported as a usage error rather than folded into
  `unavailable` — reporting it as installable promises a path that does not exist.
- **`claude-config` writes nothing it cannot source.** A CLAUDE.md is loaded into every session and
  treated as authoritative, so a stale or invented line is followed rather than questioned. Anything
  unsourceable is a question for the user, and no credential goes into a committed MCP stub.
