---
name: scaffold-analysis
description: >
  Emit a runnable analysis script stub for a comparison — argument parsing, input loading, output
  paths and a failing placeholder where the model goes — wired for a provenanced datalad run.
  Trigger on "scaffold the analysis", "give me a script stub", "set up the analysis script",
  "boilerplate for this comparison", "how do I wire this script for provenance". Do NOT trigger to
  choose the test (analyze/plan-analysis), to execute the script (analyze/run-comparison), or to
  write the analysis itself — this skill never does that.
plane: workflow
stamped: [A, T, P, E]
---

# Skill: scaffold-analysis

Write the **edges** of an analysis script — where its inputs come from, where its outputs go, and
how it will be invoked under provenance — and leave the middle deliberately empty and failing.

> 🔧 **Do-it-yourself:** the model is yours. Feature engineering, the estimator, hyperparameters,
> contrasts, and every line that turns data into a result are written by you, in the placeholder
> this skill leaves. The stub raises until you do.

## When to use
- A comparison branch exists (`analyze/propose-comparison`) and the script that will run on it does
  not.
- An existing script needs to be wired for a provenanced run: explicit inputs, explicit outputs, no
  hidden writes outside its output directory.
- Do NOT use to decide the statistical approach (`analyze/plan-analysis`), to execute the script
  (`analyze/run-comparison`), or for a one-off command that produces no output files.

## Steps

1. **Confirm the comparison** — its `cmp/<slug>` branch and what the analysis is supposed to
   produce. If no branch exists, route to `analyze/propose-comparison` first. If the approach is
   unsettled, route to `analyze/plan-analysis`; a stub built around the wrong design is worse than
   none, because its shape will be kept.
2. **Fix the contract** with the user, and write it into the stub as literal paths:
   - `inputs` — the files or globs the script reads, dataset-relative
   - `outputs` — a single directory, by convention `derivatives/cmp-<slug>/`
   - `command` — exactly how it will be invoked, e.g. `python code/cmp-<slug>.py`
   - language and the libraries it may assume, checked against the project's environment manifests
     (`project/env-check` reports what is actually declared)
3. **Write the stub** to `code/cmp-<slug>.<ext>`. It contains, and contains only:
   - argument parsing for the input and output paths, defaulted to the agreed contract
   - input loading, with an explicit failure if an input is missing
   - output directory creation
   - a single clearly-marked placeholder — `raise NotImplementedError("analysis not written")`
     in Python, `stop("analysis not written")` in R, `exit 1` in a shell script — where the analysis
     goes
   - result-writing code *after* the placeholder, so the output shape is stated but unreachable
   - a header comment naming the comparison, the planned approach, and that the analysis is unwritten
4. **State the run command** the user will hand to `analyze/run-comparison`, with its `-i`, `-o` and
   `-m` arguments filled in from the contract. Do not run it; the stub is designed to fail.
5. **Save** — run it yourself:
   ```bash
   datalad save -m "$(printf 'scaffold-analysis: stub for cmp/<slug> (analysis unwritten)\n\nDSH-Op: scaffold-analysis\nDSH-Stage: analyze')" code/cmp-<slug>.<ext>
   ```
6. **Report** — the stub path, the contract it encodes, the placeholder the user must replace, and
   the exact `analyze/run-comparison` invocation for when they have.

## Constraints

- **Never write analysis logic.** No model fitting, no test call, no feature engineering, no
  estimator or hyperparameter choice, not even "a reasonable default to get started". The whole
  point of a stub is that the scientific content has a single author and it is not this harness.
- **The placeholder must fail loudly.** Never return a constant, a random draw, a simulated result
  or an empty dataframe in place of the analysis. A stub that runs to completion produces a file
  that looks like a result, and that file will be plotted, reported and believed.
- **Never invent the inputs.** Paths come from the user or from a file that exists; a stub that
  reads a plausible-sounding path fails at run time in a way that looks like a data problem.
- **Write nothing outside the agreed output directory**, and no writes back into raw data. A run
  whose outputs are not where it declared them breaks the provenance record it was built for.
- Do not execute the stub, and do not commit a result alongside it.
- Run the save yourself; never append to `project.yaml` `log`.
