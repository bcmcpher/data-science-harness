## Context

Two `curate` planners landed in `29d1532` without a change behind them. This records the decisions
they encode, against skills that already exist.

## Goals / Non-Goals

**Goals:**
- A merge cannot be reported as successful without the arithmetic that would expose a silent failure.
- A data dictionary's gaps are part of its output rather than an absence.
- `bench/tasks/routing-lifecycle.yaml` covers both.

**Non-Goals:**
- **Fuzzy or probabilistic matching.** Not a defaulted behaviour and not a fallback. If the keys do
  not overlap, that is the finding.
- **A value-precedence rule for conflicting sources.** Disagreement between two sources about a
  participant's age is a data-quality finding for the user, not a rule for the harness to apply.
- **Imputation of any kind.**
- **Controlled-term lookup here.** `gen-data-dict` delegates that to the `annotate` doer and
  inherits its refusal to recall a code.

## Decisions

- **The join key is supplied, never inferred.** A column called `id`, `subject` or `participant_id`
  in two files is not evidence that they mean the same thing — one may be a scanner id and the other
  a study id. The cost is one question; the alternative is a table that is wrong in a way nothing
  downstream can detect.
- **Key overlap is checked before the merge, and a zero or near-zero overlap stops it.** This is
  almost always an identifier-format mismatch (zero-padding, a prefix, a type). Merging anyway
  produces an empty or tiny table that will be mistaken for a real one.
- **The row and column arithmetic is part of the report, not a debug detail.** Rows in, rows out,
  keys matched, keys dropped per side. It is the only way a silent drop or a silent multiplication
  becomes visible, and both produce a file that looks correct.
- **A column-name collision is named, never resolved by picking a side.**
- **`gen-data-dict` derives the skeleton and refuses to fill it.** Column names, dtypes and observed
  levels come from the data; what a column *means* does not. `1 = male` and `1 = female` are both
  common, so a guess is a coin flip written into a file that reads as documentation.
- **Restating a column name as its Description is banned.** It adds no information and hides the
  gap, which is worse than leaving the entry out — an undescribed column that looks described will
  never be revisited.
- **The undescribed list is a required part of the report**, the same contract `stamped-assess` uses
  with `unassessed` and `annotate` with `unannotated`. Silence reads as completeness.
