# Evaluation protocol

> **Status: nothing here has been run.** This document specifies *how* the harness would be
> evaluated. No probe has been executed, no result exists, and no number in this repository or in
> [`paper/`](../paper) comes from a measurement. When that changes, this banner is the first thing to
> update.
>
> The protocol is written before the capabilities it would measure deliberately. Botes (2026)'s
> observation that "what gets benchmarked gets built" cuts both ways: an evaluation designed after
> the fact tends to measure whatever was convenient to build.

## What is being claimed

The harness's claim is that an assistant working inside it produces research artifacts that are
*better governed* than one working without it — reachable through a provenance chain, described by a
complete ledger, re-executable by a third party — at an acceptable cost, and that it routes work to
the right tool more often.

That decomposes into four independent measurements. They are deliberately separable: which of them
appears in any given report depends on what integrations are in scope, and that is not yet settled.

| Probe | Question | Instrument |
|---|---|---|
| [`routing`](../bench/probes/routing.yaml) | Given a research request, does the model reach the right planner skill and delegate to the right doer? | Task suite + `delegates_to` ground truth |
| [`provenance`](../bench/probes/provenance.yaml) | Is the produced artifact reachable, described, and complete? | `schemas/validate-ledger.py` + DataLad history + rubric |
| [`reproducibility`](../bench/probes/reproducibility.yaml) | Can a third party rebuild it from scratch and get the same result? | `tests/e2e-smoke.sh` distributability path, extended |
| [`cost`](../bench/probes/cost.yaml) | What does it cost in tokens, time, and human interventions? | Existing cost-priced transcript analyzer |

## Design constraints

**Probes are independent.** Each is defined by its own fixture declaring its metrics, its required
capabilities, and its control condition. Adding or removing a probe changes no other probe. A probe
whose required capability is absent from the installation is **skipped with a stated reason**, never
reported as a failure or a zero — the same contract `tests/lint-plugins.py` uses when PyYAML is
missing (exit 2) and `tests/e2e-smoke.sh` uses for its container block.

**Fixtures are data, not code.** Probes, task suites, and rubrics are YAML under
[`bench/`](../bench). Contributing a task is adding an entry, not editing shared logic. This is what
keeps the configuration composable while the paper's scope is undecided.

**Every probe declares a control.** A probe that cannot say what it is measured against measures
nothing. Three forms are permitted: a *harness-off* condition (the same task, same model, no harness
installed), a *recorded baseline* (a previous run of the same fixture), or an *absolute criterion*
(a property that is either present or not, such as a `datalad rerun` succeeding).

**Reuse the instruments that exist.** Three of the four probes measure things this repository already
checks. Specifying new measurement code for them would create a second source of truth that drifts
from the first.

---

## Probe: routing

**Question.** Given a plain-language research request, does the assistant select the correct planner
skill, and does that planner delegate to the correct capability doer?

**Why this shape.** It mirrors the tool-selection benchmark in Chen et al. (2026), which reported
first-choice accuracy rising from 23.3% to 93.6% across seven models on 60 tool-calling tasks. The
metric names below are theirs, adopted deliberately: measuring the same thing under a different name
would make the two sets of numbers incomparable, and comparability is the main reason to run this at
all. It is *not* a claim that the results would be directly comparable — the task suites differ, the
tool registries differ enormously in richness, and any report must say so.

**Metrics.**

| Metric | Definition |
|---|---|
| `route@1` | Fraction of tasks where the first selected planner skill is the expected one. |
| `route@k` | Fraction where the expected planner appears in the first *k* selections. |
| `capability@k` | Graded coverage: the fraction of the expected `delegates_to` set that the selected route would actually reach. Partial credit, because a planner reaching `datalad` but not `annotate` is better than one reaching neither and worse than one reaching both. |
| `handoff@k` | Executable sufficiency: whether the delegation carries enough parameters for the doer to act without asking back. Scored against the doer's stated required parameters. |

**Ground truth.** Derived from the repository, not hand-labelled. Each task declares
`expected_skill` and `expected_delegates_to`; the latter must resolve to plugins that actually
provide an agent, by the same rule `tests/lint-plugins.py` applies at `check_skill`. This is what
keeps the suite correct as capabilities land: when a planner's `delegates_to` grows, the affected
fixtures must be updated, and the diff is visible in review.

**Control.** Harness-off. The same task, the same model, no harness plugins installed. Both
conditions must be recorded in the same run.

**Judging.** `route@k` and `capability@k` are exact-match against the fixture and need no judge.
`handoff@k` requires judgement about parameter sufficiency; use a majority vote of independent
judges, following Chen et al.'s three-judge procedure, and record per-judge labels rather than only
the majority.

**What would invalidate a result.**
- Task prompts that name a skill, a plugin, or a CLI. The probe measures selection; a prompt that
  contains the answer measures nothing.
- A fixture whose `expected_delegates_to` no longer resolves — the ground truth has gone stale.
- Running the harness-on condition with prior conversation context that the harness-off condition
  lacked.
- Reporting an aggregate across models without per-model figures. A mean over seven models can hide
  one model carrying the result.

---

## Probe: provenance

**Question.** Is a produced artifact reachable, described, and administratively complete?

**Instrument.** `schemas/validate-ledger.py` against `project.yaml`, plus the DataLad history, scored
against [`bench/rubrics/provenance-completeness.yaml`](../bench/rubrics/provenance-completeness.yaml).

**Dimensions.**

| Dimension | Evidence |
|---|---|
| Reachability | Fraction of published outputs reachable through a `datalad run` chain from raw inputs. An output with no producing run scores zero regardless of how good it is. |
| Replayability | Fraction of run commits that `datalad rerun` reproduces. |
| Environment pinning | Fraction of runs executed inside a registered container with the image's annex key recorded. |
| Ledger validity | `project.yaml` validates against the schema. Binary. |
| Ledger completeness | Products declared, obligations discharged or explained, contributors carrying identifiers. |
| Distributability | A fresh clone can `datalad get` the published content. Binary. |

**Control.** Absolute criteria. Each dimension is a property the artifact has or does not; there is
no harness-off condition, because an artifact produced without the harness has no ledger to score.
That asymmetry is itself worth reporting, but it is not a comparison.

**Reporting.** Per-dimension, **not as a single score.** STAMPED treats each principle as a spectrum
rather than a pass/fail gate (`docs/stamped.md`), and collapsing six dimensions into one number
implies a pass mark the framework declines to set. This is a real tension between wanting a headline
figure and being faithful to the framework the harness is built on; the framework wins.

**What would invalidate a result.**
- Scoring an artifact the harness itself produced end-to-end without a human-authored analysis. It
  would measure the smoke test, not the harness.
- Counting a run as replayable without executing `datalad rerun`.

---

## Probe: reproducibility

**Question.** Can a third party, given only the published identifier, rebuild the artifact and obtain
the same results?

**Instrument.** The distributability path already in `tests/e2e-smoke.sh` — push to a sibling, clone
independently, `datalad get` — extended through container rebuild and figure regeneration.

**Procedure.** From a clean machine: resolve the published identifier, clone, `datalad get` the
inputs, rebuild the container from its recipe, re-execute the recorded runs, and diff the regenerated
outputs against the published ones.

**Metrics.** Fraction of published figures and tables regenerated; byte-level or
tolerance-qualified agreement; wall-clock to first rebuilt figure; number of manual interventions
required.

**Control.** Absolute criterion — it rebuilds or it does not.

**What would invalidate a result.**
- Rebuilding on the machine that produced the artifact, or with any cached state.
- Counting a rebuild as successful when the tolerance was chosen after seeing the difference.
- Reporting the fraction of figures regenerated without reporting the manual interventions needed.

---

## Probe: cost

**Question.** What does a lifecycle stage cost with the harness versus without it?

**Instrument.** The existing cost-priced transcript analyzer
(`~/.claude/scripts/model-usage.mjs`). Do not write a second one.

**Metrics.** Input, output, and cache tokens; priced cost; wall-clock; number of human interventions
(clarifying questions asked, corrections issued, manual fixes applied) — per completed lifecycle
stage.

**Control.** Harness-off, matched on task and model.

**Known confound, stated up front.** The harness adds skill and agent definitions to context, so the
harness-on condition starts with a token overhead before doing any work. A fair comparison has to
report that overhead separately from the work, and has to count human interventions — a cheaper run
that required three corrections is not cheaper.

**What would invalidate a result.**
- Comparing runs on different models or with different context-window states.
- Reporting token counts without the intervention count.
- Attributing a cost difference to the harness when it is attributable to conversation length.

---

## Fixture format

See [`bench/README.md`](../bench/README.md) for how to add a probe, task, or rubric. In summary:

```
bench/
├── probes/<probe>.yaml     id, question, metrics, requires, control, judging, invalidators
├── tasks/<suite>.yaml      probe, tasks[]: {id, prompt, expected_skill, expected_delegates_to, ...}
└── rubrics/<name>.yaml     dimensions[]: {id, evidence, anchors}
```

There is no runner. The fixtures specify what a runner would consume; building one is deferred until
the probe set is settled.

## Open questions

- **Which integrations are in scope.** The probe set is deliberately larger than any single report
  needs. Which appear in the preprint is undecided, which is why the fixtures are composable.
- **How many tasks the routing suite needs to discriminate.** Chen et al. used 60. Whether that is
  the right order of magnitude here is unknown, and cannot be known without a pilot.
- **Whether a harness-off control is meaningful for provenance.** An assistant without the harness
  produces no ledger, so the comparison is degenerate. It may be more honest to compare against a
  careful manual workflow, which is expensive to obtain.
- **Who judges `handoff@k`.** Model judges are cheap and correlate imperfectly; human judges are the
  standard and do not scale.
