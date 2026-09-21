---
name: gen-report
description: >
  Assemble an analysis report for a comparison or product — results tables, QC metrics, figures and
  the provenance behind them — from files that were actually produced. Trigger on "write up the
  results", "results report", "analysis report", "summarize the findings", "QC report", "what did
  the analysis produce". Do NOT trigger to write the paper (disseminate/draft-manuscript), to check
  reporting-guideline coverage (disseminate/reporting-checklist), or to score reproducibility
  (govern/stamped-assess).
plane: workflow
stamped: [A, M, T]
delegates_to: [datalad]
---

# Skill: gen-report

Collect what a comparison produced into one readable document — numbers, figures, QC, and the commit
each came from — so the results can be reviewed without re-running anything.

> This is the internal report, not the manuscript. `disseminate/draft-manuscript` writes the paper
> and may draw on this; the difference is audience and obligation. A report may say "unclear" and
> "not run"; that is the most useful thing it does.

## When to use
- A comparison has run and its results need reviewing, circulating, or carrying into a lab meeting.
- A product groups several comparisons (`analyze/manage-product`) and needs one document across them.
- Do NOT use before the analysis has run, to interpret the findings, or to decide what is
  publication-ready.

## Steps

1. **Fix the scope** — one comparison branch, or the comparisons of one product from `products[]`.
   Name it explicitly; a report that silently spans whatever was lying around cannot be reproduced.
2. **Gather the produced outputs** — the result files, figures and QC outputs under
   `derivatives/cmp-<slug>/`. For each, record the commit that produced it. Delegate the history
   lookup to the **datalad doer**:
   > "for each of `<the output paths>`, report the commit that last modified it and whether that
   > commit is a recorded run."
   An output with no run behind it is reported as such — it was produced by hand.
3. **Extract the numbers by reading the files.** Every table cell is read from an output; where a
   value is not in any output, the cell says `not reported`, never a computed-on-the-fly figure.
4. **Assemble the report** — write to `derivatives/cmp-<slug>/report.md` (or the product's directory):
   - what was compared, and the approach as recorded by `analyze/plan-analysis`
   - the results tables, each cell traceable to a file
   - the figures from `analyze/plot`, by path
   - QC metrics, if QC outputs exist
   - **a gaps section**: assumptions never checked, comparisons that failed or were not run, outputs
     produced outside a recorded run, and anything the plan promised that the results do not contain
   - provenance: branch, commits, container image if the runs were containerized
5. **Log it** — append one entry to `project.yaml`:
   `{ ts, op: gen-report, stage: analyze, note: "report <path> over <comparisons>", branch }`.
6. **Save** — delegate to the **datalad doer**:
   > "save: `datalad save -m 'gen-report: <scope>'`."
7. **Report** — the report path, what it covers, and the gaps section verbatim, because that is the
   part a reader skips and the part that determines what the results mean.

## Constraints

- **No number appears that was not read from a produced output.** Not recomputed from memory of the
  data, not rounded up from a figure, not carried over from an earlier version of the analysis. A
  number in a report is quoted downstream as if it had been checked.
- **A missing result is reported as missing.** `not reported`, `not run`, `failed` — never omitted,
  never filled with a plausible value, never left implicit. An absent row reads as a pass.
- **Never state that a result is significant, robust, replicated, or publication-ready**, and never
  add an interpretation the outputs do not contain. Report what was produced; the researcher decides
  what it means.
- **Never report an assumption as checked** because `analyze/plan-analysis` listed it. The plan lists
  assumptions; the gaps section says which were tested, and the honest answer is usually none.
- Do not run, re-run or repair an analysis to fill a gap in the report — the gap is the finding.
- Keep `log:` append-only and the ledger schema-valid; delegate every history lookup and the save to
  the datalad doer.
