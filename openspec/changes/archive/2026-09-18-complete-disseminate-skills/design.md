## Context

`disseminate/submission-track` landed in `29d1532` without a change behind it. This records the
decisions it encodes, and corrects the three places that still count the plugin's skills as eight.
It is the last of the three retroactive changes; after it, `bench/tasks/routing-lifecycle.yaml`
covers every built planner again.

## Goals / Non-Goals

**Goals:**
- A submission history cannot be destroyed by being updated.
- Nothing in the ledger asserts an outcome that has not happened.
- The plugin's size is stated correctly in all three places that state it.

**Non-Goals:**
- **Modelling the review process.** No reviewer records, no round structure beyond an appended
  entry, no expected-decision date.
- **A venue database or scope matching.** The skill does not suggest where to submit.
- **Folding submission state into `product.status`.** Those are different questions.

## Decisions

- **`submissions[]` is append-only.** A resubmission appends a new entry; the earlier venue and its
  decision stay. A submission history is the part of a project's record most often destroyed by
  being updated, and the destroyed part — where it was rejected first — is what a co-author or a
  funder report actually needs.
- **`product.status` stays `in-progress` through the whole submission cycle.** Submitted, under
  review, rejected and revising are all in-progress; only an actual release makes a product
  `released`. Overloading one field with two lifecycles means a rejection reads as a regression.
- **A decision is quoted, never paraphrased.** If the venue said reject, the field says reject. The
  field's entire value is that it can be quoted into a report without being re-checked.
- **Nothing is inferred from elapsed time.** Three months of silence is not evidence a paper is
  under review, and `revision-requested` is not evidence of eventual acceptance.
- **No reviewer identities, and no pasted reviewer text that names people.** The ledger is committed
  to a dataset that may be published.
