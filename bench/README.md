# bench — evaluation fixtures

Declarative fixtures for the evaluation protocol in [`docs/evaluation.md`](../docs/evaluation.md).

**There is no runner here, and nothing in this directory has been executed.** These files specify
what a runner consumes. Executing them belongs to
[`wikiskill`](https://github.com/bcmcpher/wikiskill), a separate project; its pilot reads
`tasks/routing-lifecycle.yaml` in place and modifies nothing in this repository. Which probes a
given report carries is still open — see the questions at the end of the protocol.

**Do not add fields to these fixtures to suit a consumer.** Every expected outcome here is derived
from the repository, which is what makes it checkable rather than hand-maintained. A runner that
needs something these files do not declare — a train/validation/test split, a distractor between a
planner and a toolbox skill — supplies it on its own side.

The point of keeping this as data rather than code is composability: which probes and which
integrations appear in a given report is not yet decided, so adding or dropping one must be a fixture
edit, never a code change.

```
bench/
├── probes/<probe>.yaml     what is measured, against what control
├── tasks/<suite>.yaml      the inputs, with expected outcomes
└── rubrics/<name>.yaml     scored dimensions and their anchors
```

## Adding a probe

Create `probes/<id>.yaml`. Required keys:

| Key | Meaning |
|---|---|
| `id` | Matches the filename stem. |
| `question` | One sentence: what this probe answers. |
| `metrics` | Each with `id`, `definition`, and `type` (`exact`, `graded`, `judged`, `binary`, `measured`). |
| `requires` | Capabilities or tools that must be present. Absent → the probe is **skipped with a stated reason**, never failed or scored zero. |
| `control` | `harness_off`, `recorded_baseline`, or `absolute`, with a `description`. A probe with no control is not reportable. |
| `invalidators` | What would make a result from this probe untrustworthy. Not optional — a probe that cannot say how it breaks is not specified. |

Optional: `judging` (required when any metric is `judged`), `instrument`, `notes`.

Probes must not reference each other. If two probes need the same fact, each declares it.

## Adding a task

Append to an existing suite in `tasks/`, or create a new one. A suite declares the `probe` it feeds
and a list of `tasks`.

Every task needs an `id` and a `prompt`. The prompt is what a user would actually say.

> **The prompt must not name a skill, a plugin, or a CLI.** The routing probe measures whether the
> assistant *selects* the right tool; a prompt containing the answer measures nothing. This is the
> single easiest way to produce a meaningless result.

For the routing probe, a task also declares:

- `expected_skill` — the planner skill that should be selected, as `plugin/skill`.
- `expected_delegates_to` — the doer plugins that planner should reach.
- `rigor` — `exploratory` or `confirmatory`, where the task involves a comparison.
- `notes` — anything a reader needs to judge whether the expectation is fair.

**`expected_delegates_to` must name plugins that actually provide an agent**, which is the same rule
`tests/lint-plugins.py` enforces for skills at `check_skill`. A fixture naming a plugin with no doer
is broken ground truth, and it will silently score every model wrong.

When a capability lands and a planner's `delegates_to` grows, the affected tasks must be updated in
the same change. That diff is the review signal that ground truth kept up.

## Adding a rubric

Create `rubrics/<id>.yaml` with `dimensions`, each declaring `id`, `evidence` (what is inspected),
and `anchors` (what each score level means, concretely enough that two people agree).

Rubrics score artifacts, not transcripts.

## Current state

| Fixture | Status |
|---|---|
| `probes/routing.yaml` | specified, not run |
| `probes/provenance.yaml` | specified, not run |
| `probes/reproducibility.yaml` | specified, not run |
| `probes/cost.yaml` | specified, not run |
| `tasks/routing-lifecycle.yaml` | worked example; covers the built planners only |
| `rubrics/provenance-completeness.yaml` | specified, not run |

The routing suite deliberately covers only planners that exist today. Tasks for capabilities still in
`openspec/changes/` belong in that change, not here — a fixture whose expected delegation does not
yet resolve is broken ground truth.
