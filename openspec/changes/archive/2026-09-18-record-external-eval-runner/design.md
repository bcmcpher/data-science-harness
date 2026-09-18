## Context

The evaluation protocol was written before the capabilities it measures, deliberately. The runner
was deferred for a stated reason — "until the probe set is settled" — and that reason has not
expired: the probe set is still unsettled, and `docs/evaluation.md`'s four open questions are all
still open.

What changed is who would build it. `wikiskill` is a separate repository implementing the WikiSkill
loop (Tang et al., arXiv 2608.27454) against real harnesses: trace logging, then explicit evaluation
of task suites in isolated headless sessions under OFF / ROUTED / INJECTED conditions, then a wiki of
distilled patterns, then gated skill refinement. Its first collection is this harness. Its step 2,
`add-explicit-eval`, has a working core — suite validation, an OpenCode backend with per-run
isolation and endpoint preflight, the OFF and ROUTED conditions, route metrics and a report. Its step
3 is the pilot that runs these fixtures.

That makes the relationship worth stating precisely, because two repositories now share one
instrument. This repository owns the fixtures and the ground truth; that repository owns the runner,
the conditions and the scoring. The seam is the fixture format.

## Goals / Non-Goals

**Goals:**
- No document in this repository describes a runner as work owed here.
- The fixtures' guarantee to an external consumer is written down, so "we did not add `split:`" is a
  recorded position rather than an omission someone later fixes helpfully.
- The funding matrix's deliverables describe results, not construction.
- Every "nothing has been run" statement survives this change unchanged.

**Non-Goals:**
- **Adding fields to `bench/`.** Not `split`, not toolbox-vs-planner distractors, not `guard` or
  `requires` hints. See the decision below.
- **Running anything.** This change produces no measurement and no result.
- **Depending on `wikiskill`.** Nothing here imports it, installs it, or fails without it. It is
  named as the instrument in the same way the cost probe names the existing transcript analyzer.
- **A fifth probe.** A refinement or cross-model-transfer probe is wikiskill's to specify once its
  shape is known. The existing requirement's "at least these four" leaves the door open without
  guessing at what walks through it.

## Decisions

- **The requirement is "may live outside", not "lives in wikiskill".** Naming the instrument is
  required; naming that particular instrument forever is not. If the runner moves, the spec should
  not need a MODIFIED block — only the document that names it.
- **Ground truth stays derived, and that is what forbids fixture edits.** `expected_delegates_to` is
  checkable against the repository because `tests/check-bench-fixtures.py` checks it. A `split:`
  field is not derivable from anything here — which train/val/test assignment is right depends on
  what is being refined, and that is the consumer's question. Adding it would put a hand-maintained
  field next to a derived one in the same file, and the file's credibility comes from the
  distinction.
- **The near-miss objection, answered rather than dismissed.** wikiskill's design names three
  confusions worth measuring — `datalad-save` vs `checkpoint`, `datalad-push` vs `publish`, `zenodo`
  vs `dataset-release`. Those are real, and the current suite only discriminates planner from
  planner. They are still not added here: a toolbox skill is not a planner, so a task expecting one
  has no `expected_delegates_to` to check, and the fixture would be asserting something this
  repository cannot verify. If the pilot shows those confusions dominate, the right response is a
  requirement change, not a quiet fixture edit.
- **The funding matrix keeps three source values.** `docs/funding/catalyst-fit.md` closes its
  *source* vocabulary at *repo* / *training* / *reference* and says there is no fourth value. An
  external instrument is checkable against a file, so it stays *repo* — the row names which
  repository. Opening a fourth value to accommodate one row would cost more than the row is worth,
  and the closed vocabulary is what keeps that document honest.
- **The deferral's stated reason survives.** "Until the probe set is settled" was never only about
  who writes the code; the open questions about scope, task count, the provenance control and the
  `handoff@k` judge are unchanged. This change moves the runner out of this repository's ledger of
  owed work. It does not claim the protocol is settled.
