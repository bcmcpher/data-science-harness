# Evaluation protocol

:::{important} No results are reported in this section.
At the time of writing, **no probe described below has been executed.** This section specifies how
the harness would be evaluated. It contains no measurements, and no number elsewhere in this paper
comes from one.

We state the protocol before running it deliberately. As @botes2026lawinsidemachine puts it, "what
gets benchmarked gets built" — an evaluation designed after the fact tends to measure whatever was
convenient to build.
:::

<!--
SKELETON. Full protocol: docs/evaluation.md. Fixtures: bench/.

DRAFTING RULE: every sentence in this section is either a definition or a stated absence. If a
sentence could be read as reporting an outcome, rewrite it.
-->

## What is being claimed

<!--
The harness's claim: an assistant working inside it produces artifacts that are better governed —
reachable through a provenance chain, described by a complete ledger, re-executable by a third party
— at acceptable cost, and routes work to the right tool more often.

Four independent measurements. Say why they are separable: which appear in any given report depends
on which integrations are in scope, and the fixture format is composable for that reason.
-->

## Probe: routing

<!--
bench/probes/routing.yaml

Question: given a plain-language request, does the assistant select the correct planner and delegate
to the correct doer?

Metrics: route@1, route@k, capability@k (graded — partial credit for reaching some of the expected
delegation set), handoff@k (judged — does the delegation carry enough for the doer to act).

Control: harness-off, same task, same model, matched context state.

Ground truth from the repository: each task declares expected_skill and expected_delegates_to, and
the latter must resolve to a plugin providing an agent — the same rule tests/lint-plugins.py applies
to skills. Ground truth is checkable rather than hand-maintained, so it cannot quietly go stale as
capabilities land.

TWO THINGS TO STATE EXPLICITLY, BOTH SLIGHTLY UNCOMFORTABLE:

  1. The metric names are taken from @chen2026brainresearcher so the measurements are comparable in
     kind. They are NOT comparable in value: different task suites, and a tool registry there that
     is far richer than `delegates_to`. Any reader who sees route@1 next to their 93.6% will make
     the comparison whether we invite it or not; better to bound it ourselves.
  2. The current suite (bench/tasks/routing-lifecycle.yaml, 42 tasks — one per built planner plus
     near-miss discriminators) is a worked example, not a validated instrument. Whether 42 tasks
     discriminate between conditions is unknown and cannot be known without a pilot.
     @chen2026brainresearcher used 60.

  RUNNER: the runner is external (wikiskill), so this section is not blocked on building one. State
  that the instrument exists and that no probe has been executed through it — those are two separate
  facts and the second is the one that matters here.

Table: metric definitions. Lift from bench/probes/routing.yaml.
-->

## Probe: provenance completeness

<!--
bench/probes/provenance.yaml, bench/rubrics/provenance-completeness.yaml

Six dimensions: reachability, replayability, environment pinning, ledger validity, ledger
completeness, distributability. Instruments already exist — schemas/validate-ledger.py, the DataLad
history, tests/e2e-smoke.sh's distributability path.

Control: absolute criteria. Note the asymmetry rather than hiding it — an artifact produced WITHOUT
the harness has no ledger to score, so there is no meaningful harness-off condition here. That
asymmetry is itself informative but it is not a comparison, and presenting it as one would be a
sleight of hand.

REPORTED PER DIMENSION, NOT AS A COMPOSITE. STAMPED treats each principle as a spectrum rather than
a pass/fail gate [@macdonald2026stamped]; a single completeness score implies a pass mark the
framework declines to set. This is a genuine tension — a headline number would be rhetorically
useful — and we resolve it in favour of the framework. Say that out loud; it is the kind of choice
reviewers reward.
-->

## Probe: end-to-end reproducibility

<!--
bench/probes/reproducibility.yaml

From a clean machine with no cached state: resolve the identifier, clone, `datalad get`, rebuild the
container, re-execute, diff.

Metrics: fraction of figures regenerated; output agreement within a tolerance declared BEFORE the
diff was inspected; time to first rebuilt figure; manual interventions.

Manual interventions are reported alongside the regeneration fraction, always. A rebuild that
"worked" after four undocumented fixes did not work.

This is the most expensive probe and the strongest evidence. Say both.
-->

## Probe: cost

<!--
bench/probes/cost.yaml

Tokens, priced cost, wall-clock, and human interventions per completed lifecycle stage, with and
without the harness. Instrument is an existing cost-priced transcript analyzer.

State the confound up front rather than in a footnote: the harness adds skill and agent definitions
to context, so the harness-on condition starts with a token overhead before doing any work. A fair
comparison reports that overhead separately, and counts interventions — a cheaper run that needed
three corrections is not cheaper.
-->

## Threats to validity

<!--
Lift the `invalidators` blocks from the four probe fixtures. The ones a reviewer will raise first:

  - Task prompts that leak the answer by naming a skill, plugin, or CLI. The suite's prompt rule
    exists for this; state it.
  - Ground truth going stale as capabilities land and planners are rewired.
  - Scoring an artifact the harness produced end-to-end with no human analysis — that measures the
    smoke test.
  - Choosing an agreement tolerance after seeing the difference.
  - Attributing cost differences to the harness rather than to conversation length.
  - Aggregating across models and hiding a single model carrying the result.

Then the one that is not in any fixture, because it is about this paper rather than the probes: a
protocol nobody has run may not survive contact with execution. The routing probe is partly
protected — its ground truth is derived from the repository — but the other three are unvalidated
until someone runs them. Name that as the primary limitation and carry it into section 05.
-->
