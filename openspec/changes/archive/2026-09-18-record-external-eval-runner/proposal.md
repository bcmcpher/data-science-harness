## Why

`docs/evaluation.md` and `bench/README.md` both end on the same sentence: there is no runner, and
building one is deferred until the probe set is settled. That was written when no runner existed
anywhere. One is now being built outside this repository — `wikiskill`, a separate project whose
third roadmap step, `add-dsh-pilot`, runs this repository's `bench/tasks/routing-lifecycle.yaml`
and states, twice, that it touches nothing here.

So the deferral is stale in a way that matters. Read literally, the two documents still describe
work this repository owes, and `docs/funding/catalyst-fit.md` lists "a probe runner" first among its
deliverables and says "the remaining work is one runner". A reader — including a funder — would
conclude that the measurement is blocked on code that has to be written here. It is not. What is
missing is a *run*, not a runner, and the two are different asks.

The second thing this change records is the consequence of an external consumer. `wikiskill`'s task
suites carry fields these fixtures do not: a `split` per task, and near-miss distractors between a
planner and a toolbox skill. The temptation is to add them here. That would be a mistake, and the
reason is the property the routing probe rests on: ground truth is *derived from this repository*,
because `expected_delegates_to` is checked against each planner's declared `delegates_to` by
`tests/check-bench-fixtures.py`. A fixture edited to fit one runner's schema is no longer derived
from anything — it is hand-maintained, which is the failure the probe was designed to avoid. The
adapter adapts; the fixtures do not.

Neither point changes what has been measured. Nothing here has been run, and every statement to that
effect stays exactly as it is.

## What Changes

- Two requirements added to `evaluation-protocol`: the runner may live outside this repository and
  MUST be named, and `bench/` MUST stay consumable without modification, with ground truth derived
  from this repository's own checks.
- `docs/evaluation.md` and `bench/README.md` stop describing a runner as this repository's deferred
  work and name the external instrument instead.
- `docs/funding/catalyst-fit.md` — the feasibility row, the deliverables list and the budget row
  stop being sized around building a runner. The stale fixture count (27) is corrected to 42.
- `paper/sections/04-evaluation.md` — the same stale count, and a drafting note that the section is
  not blocked on building a runner.
- Three drift fixes found while checking these claims: `README.md` lists four open changes, one of
  which was archived on 2026-09-17; its **Planned** capability table is a header with no rows while
  the prose beneath still points at it; and `docs/motivation.md`'s evaluation row names no
  instrument.

## Capabilities

### Modified Capabilities

- `evaluation-protocol`: gains two requirements about where the runner may live and what the
  fixtures guarantee to a consumer. The existing seven are untouched — in particular, "The four
  probes are routing, provenance, reproducibility, and cost" already says *at least* these four, so
  a refinement probe can be added later without rewriting it.

## Impact

- Modified: `openspec/specs/evaluation-protocol/spec.md` (on archive), `docs/evaluation.md`,
  `bench/README.md`, `docs/funding/catalyst-fit.md`, `docs/motivation.md`, `README.md`,
  `paper/sections/04-evaluation.md`
- **No change to `bench/`.** That is the point of the second requirement.
- No plugin, skill, agent, schema or test changes. Counts do not move: 21 plugins, 67 skills, 42
  routing tasks.
