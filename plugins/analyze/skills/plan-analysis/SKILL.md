---
name: plan-analysis
description: >
  Choose a statistical approach for a comparison from the data's shape and the question being asked,
  and state the assumptions that choice rests on. Trigger on "what test should I use", "plan the
  analysis", "how should I analyze this", "which model fits this design", "is this paired or
  unpaired", "help me choose a statistical test". Do NOT trigger to create the comparison branch
  (analyze/propose-comparison), to write the script (analyze/scaffold-analysis), to run it
  (analyze/run-comparison), or to freeze a plan for pre-registration (govern/preregister).
plane: workflow
stamped: [T, A]
delegates_to: [datalad]
---

# Skill: plan-analysis

Turn a research question plus a dataset into a **named statistical approach with its assumptions
written down**, recorded in the ledger so the choice is auditable later.

> 🔧 **Do-it-yourself:** checking whether the assumptions hold is yours. This skill names the test
> the design implies and lists what that test requires; it does not test for normality, inspect
> residuals, or tell you the data are suitable. Those are analyses in their own right, and they run
> through `analyze/propose-comparison` and `analyze/run-comparison` like any other.

## When to use
- A comparison is being designed and the statistical approach is not yet settled.
- The design changed (a covariate added, repeated measures discovered) and the approach should be
  revisited before more work is built on it.
- Do NOT use to run anything, to interpret a result, or to decide whether a finding is real. For a
  confirmatory comparison, plan here and then freeze the plan with `govern/preregister` — this skill
  records a recommendation, not a commitment.

## Steps

1. **Establish the question and the design** — from the user, not from the data alone:
   - the outcome and the predictor(s), and which is which
   - the unit of observation, and whether observations are independent, paired, or nested
     (repeated sessions, multiple runs per subject, sites)
   - the outcome's type: continuous, count, binary, ordinal, time-to-event
   - covariates that must be adjusted for, and why each one is in the model
   - whether the comparison is exploratory or confirmatory
   If the design is ambiguous, ask. A within-subject design analyzed as between-subject is a wrong
   answer that looks like a right one.
2. **Look at the data's shape, not its values** — column names, dtypes, level counts, group sizes,
   and missingness per column. Read the data dictionary if one exists
   (`curate/gen-data-dict` writes it). Report the group sizes you found; if a cell is small, say so.
3. **Name one recommended approach and at most two alternatives.** For each: what it estimates, the
   design feature that motivates it, and what would make it the wrong choice. Prefer the simplest
   model that answers the question as asked.
4. **List the assumptions explicitly**, one line each, as things *to be checked* — independence,
   distributional form, homogeneity of variance, linearity, proportional hazards, whatever the
   approach requires. State how each could be checked, and mark the whole list 🔧.
5. **State the multiple-comparison situation** — how many tests the plan implies and what would need
   correcting. Do not pick a correction silently.
6. **Log it** — append one entry to `project.yaml`:
   `{ ts, op: plan-analysis, stage: analyze, note: "recommended <approach> for <question>;
   assumptions unchecked", branch }`.
7. **Save** — delegate to the **datalad doer**:
   > "save: `datalad save -m 'plan-analysis: <approach> for <question>'`."
8. **Report** — the approach, the alternatives, the assumption list, the multiple-comparison note,
   and the next step: `analyze/propose-comparison` to open the branch (then `govern/preregister`
   first if confirmatory), and `analyze/scaffold-analysis` to get a runnable stub.

## Constraints

- **Never assert that an assumption holds.** This skill lists what the approach requires; it does
  not verify it. "The outcome is approximately normal" is a claim about the data, and the data have
  not been analyzed yet.
- **Never report a statistic.** No p-value, effect size, confidence interval, power figure or
  correlation appears in the output of this skill, whether computed or recalled. A number that
  arrives before the analysis will be quoted as if it came from one.
- **Never infer the design from column names.** `session`, `visit` or `run` suggest repeated
  measures and may not be; ask rather than guess, because the dependence structure is the thing most
  likely to be wrong and least likely to be noticed.
- **Do not compute a required sample size and present it as the study's power.** If the user asks,
  say what a power calculation needs as input and that it is a separate analysis.
- Do not select a multiple-comparison correction on the user's behalf; name the situation and the
  options.
- A recommendation is not a pre-registration. Only `govern/preregister` freezes a plan, and only the
  user decides the plan is final.
- Keep `log:` append-only and the ledger schema-valid; delegate the save to the datalad doer.
