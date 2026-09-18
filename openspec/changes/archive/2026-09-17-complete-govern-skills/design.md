## Context

Four `govern` planners have been documented and unbuilt since the retrofit, and other parts of the
repository already instruct the reader to use two of them. This change builds all four. They are
planner skills over existing doers, so the work is operating procedure, ledger shape, and — mostly —
refusals.

## Goals / Non-Goals

**Goals:**
- Nothing in `govern` is marked *(planned)* any more.
- `add-deidentify-skill` task 3.3 closes with a real link rather than a recorded intention.
- Every fact these skills write came from a document or the user, never from recall.
- `unassessed` is a first-class answer, distinct from a zero.

**Non-Goals:**
- **A LinkML STAMPED schema.** The paper mentions one; scoring against the requirement ids in
  `docs/stamped.md` is what is enforceable today, and a schema is a separate change.
- **Modelling consent scope or data-use restrictions.** The ledger does not carry them. These skills
  note them in `log:` prose and say the schema does not model them, rather than implying a structured
  guarantee. Botes (2026) asks for machine-decidable consent and that remains out of reach.
- **Any compliance determination.** Named as a non-goal because it is the thing users will ask for.
- **Funder-template bundling.** No funder DMP templates ship here; the skill works from what the
  user supplies.

## Decisions

- **`init-ledger` is the brownfield entry point, not a subroutine of `new-project`.** README described
  it as "called by / extends `project/new-project`", which would make it a duplicate — `new-project`
  already writes the ledger. The non-overlapping job is a dataset that already exists, possibly with
  years of history, adopting the ledger now. That is also how another group adopts the harness, which
  is the framing `docs/funding/catalyst-fit.md` holds. Scoped that way, it is the only skill here
  whose first step is a refusal: if `project.yaml` exists, stop.

- **`init-ledger` never backfills the log.** Its first entry records where the record begins. An
  append-only log whose early entries were reconstructed is indistinguishable from one that was kept,
  and the honest gap is what makes the rest of it trustworthy.

- **Ethics protocol data is an obligation plus log entries.** Settled in
  `extend-ledger-for-planned-skills` and documented as `docs/project-ledger.md` convention 5, so
  this change implements rather than re-decides it: `kind: ethics`, expiry in `due`, protocol number
  in `ref`, approval date and amendments appended to `log:`. An amendment is a new entry, never an
  edit — the history of what was approved when is what an audit asks for.

- **`ethics-track` never computes an expiry.** Approval terms differ by board, protocol type and
  jurisdiction. A wrong expiry is worse than a missing one: it produces a renewal reminder that fires
  after the approval lapsed, which is a silent failure of the one thing the skill is for.

- **`stamped-assess` reports seven answers and no total.** `docs/stamped.md` treats each principle as
  a spectrum and sets no pass mark, so a composite implies one. The same rule already governs the
  provenance probe in `docs/evaluation.md`; this keeps the two consistent.

- **`unassessed` is not zero.** The contract `annotate` established for `unavailable` versus
  `unannotated`, applied to scoring. A zero claims the requirement was checked and failed. Collapsing
  them biases the report toward making the project look worse than it is, and the reader cannot tell
  which happened. This is added to the spec's existing STAMPED-spectrum requirement rather than
  stated only in the skill.

- **`stamped-assess` writes no score into the ledger's structured fields.** There is no schema field
  for one, an assessment is an observation at a moment rather than a commitment, and inventing prose
  that reads structured is worse than a `log:` entry.

- **`plugins/govern/references/stamped.md` duplicates the requirement ids deliberately.** An
  installed plugin has no access to the repository's `docs/` tree, so a skill citing `docs/stamped.md`
  would work in the source layout and break once installed. The file names `docs/stamped.md` as
  canonical and says that if they disagree, the copy is the bug.

## Risks / Trade-offs

- **`dmp` is the most likely to be asked for a recalled fact.** Funder requirements are specific,
  change between calls, and a plausible wrong answer goes into a document someone signs. Mitigated
  by refusing to fill an unsourced section and by making the list of sections the user must complete
  a required part of the report — but this is the skill to watch in review.
- **`stamped-assess` overlaps `qc-review`.** `qc-review` already carries `stamped: [S]` and does a
  STAMPED self-assessment as part of a pre-move review. The split: `qc-review` is a gate before data
  moves downstream and leads with BIDS conformance; `stamped-assess` is a full seven-dimension
  readout with evidence, for a release or a funder question. If that distinction does not survive
  use, merging them is a later change — two skills doing one job is a real cost.
- **Duplicated STAMPED requirements can drift.** The reference file names the canonical source and
  declares itself the bug on disagreement. Nothing enforces it, which is a known gap: the lint
  checks STAMPED *letters* against a closed set but not requirement-id text.
- **Four skills at once is wide.** Justified by the amended convention — all four sit over doers that
  exist — but it means four sets of prose reviewed together rather than separately.
