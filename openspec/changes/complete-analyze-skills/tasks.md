## Status

Complete as of 2026-09-18. All tasks checked. Ready to archive.

## 0. Minimal working core

All of it. Four planner skills over the `datalad` doer, which exists, so there is no capability half
to defer. `plot` reaches execution through `analyze/run-comparison` rather than the containers doer,
so nothing here points at a capability that is not there.

Deliberately **not** here: a plotting library or project theme, a power-analysis calculator, an
assumption-checking step, and `analyze/literature-search`. The first three are analyses in their own
right and belong to the researcher; the fourth needs a literature capability plane and keeps its
*(planned)* marker.

## 1. The skills

- [x] 1.1 `plugins/analyze/skills/plan-analysis/SKILL.md` — `stamped: [T, A]`, `delegates_to:
      [datalad]`. Establishes the design from the user, reads the data's **shape** and not its
      values, names one approach plus at most two alternatives, and lists the assumptions as items
      to be checked with a 🔧 marker. Routes confirmatory work to `govern/preregister` rather than
      growing a second freezing path — a recommendation is not a commitment.
- [x] 1.2 `plugins/analyze/skills/scaffold-analysis/SKILL.md` — `stamped: [A, T, P, E]`,
      `delegates_to: [datalad]`. Writes the script's edges and a placeholder that raises. The
      result-writing code sits **after** the placeholder, so the stub states its output shape while
      remaining unable to produce one. It also emits the exact `run-comparison` invocation, so the
      contract the stub encodes and the contract the run records are the same one.
- [x] 1.3 `plugins/analyze/skills/plot/SKILL.md` — `stamped: [A, M]`, `delegates_to: [datalad]`.
      Writes a figure script and routes execution through `analyze/run-comparison`, so a figure gets
      the same provenance as an analysis instead of a parallel, weaker path. Asks what the error
      bars are rather than choosing: SD, SE and a 95% CI look identical and mean different things.
- [x] 1.4 `plugins/analyze/skills/gen-report/SKILL.md` — `stamped: [A, M, T]`, `delegates_to:
      [datalad]`. Reads every value from an output file, asks the datalad doer for the commit behind
      each one, and carries a **required gaps section**. Scoped as the internal report; the paper is
      `disseminate/draft-manuscript`.
- [x] 1.5 Register all four in `plugins/analyze/.claude-plugin/plugin.json`, in lifecycle order;
      version 0.1.0 → 0.2.0, description and keywords rewritten.

## 2. The refusals

These are the substance of the change. `analyze` is the plugin where a fabricated answer is least
distinguishable from a real one, because the output is a number rather than a claim.

- [x] 2.1 `plan-analysis` **never asserts that an assumption holds.** It lists what the approach
      requires; the data have not been analyzed yet, so "the outcome is approximately normal" would
      be a claim about data nobody has looked at.
- [x] 2.2 `plan-analysis` **reports no statistic** — no p-value, effect size, confidence interval,
      power figure or correlation, computed or recalled. A number that arrives before the analysis
      will be quoted afterwards as if it had come from one.
- [x] 2.3 `plan-analysis` never infers the dependence structure from column names. `session`,
      `visit` and `run` suggest repeated measures and often are not; the dependence structure is the
      thing most likely to be wrong and least likely to be noticed.
- [x] 2.4 `scaffold-analysis` **writes no analysis logic** — no model fitting, no test call, no
      feature engineering, no estimator or hyperparameter choice, not "a reasonable default to get
      started". The scientific content has one author and it is not the harness.
- [x] 2.5 `scaffold-analysis`'s placeholder **fails loudly**. Never a constant, a random draw, a
      simulated result or an empty dataframe. A stub that runs to completion writes a file that
      looks like a result, and that file will be plotted, reported and believed.
- [x] 2.6 `scaffold-analysis` never invents input paths, and the stub writes nothing outside its
      declared output directory — a run whose outputs are not where it declared them breaks the
      provenance record it was built for.
- [x] 2.7 `plot` draws **only values read from produced output files**, and produces no mock-up,
      sample or placeholder figure. A plausible-looking chart is indistinguishable from a real one at
      a glance. No significance star, n or effect size appears unless the analysis wrote it to a file.
- [x] 2.8 `gen-report` reports **no number that was not read from a produced output**, and reports a
      missing result as `not reported` / `not run` / `failed` rather than omitting the row. An absent
      row reads as a pass — the same failure `stamped-assess` avoids with `unassessed`.
- [x] 2.9 `gen-report` never states that a result is significant, robust, replicated or
      publication-ready, and never reports an assumption as checked because the plan listed it.
- [x] 2.10 None of the four interprets a result, and none repairs or re-runs an analysis to fill a
      gap. The gap is the finding.

## 3. Wire them into the surrounding documents

- [x] 3.1 `README.md` — four *(planned)* markers dropped, each entry rewritten to name its refusal.
      `analyze/literature-search` keeps its marker, deliberately.
- [x] 3.2 `README.md`'s **Built skills** table was stale in *every* row, not just `analyze` — it
      predates `deidentify`, the four govern planners and the six skills from `29d1532`. Reconciled
      wholesale here rather than left wrong in four places, so the "22 planner skills across the
      six" claim (also at the closing status section) could be corrected to **37**. The three
      umbrella changes that follow inherit a correct table.
- [x] 3.3 `.claude-plugin/marketplace.json` — the `analyze` description now names all eight skills
      and their refusals.
- [x] 3.4 `docs/end-to-end-workflow.md` — Stage 3 now lists five steps in lifecycle order rather
      than three. **Two ⚠️ scaffolding-gap callouts are closed and replaced rather than deleted**:
      the Stage-3 "no analysis-script scaffold and no plotting/visualization skill" callout becomes
      a 🔧 marking assumption checking as the researcher's, and the Stage-8 publication-figure
      callout narrows to the `agent-bundle` structuring problem that remains. The consolidated gap
      list drops its top two entries and gains assumption checking / sensitivity analyses as an
      explicit open gap, because `plan-analysis` narrows it without closing it.
- [x] 3.5 `docs/motivation.md` — banner 63 → 67 skills; the plane table now states 37 planner skills
      and names the one deliberate omission.
- [x] 3.6 Four routing tasks in `bench/tasks/routing-lifecycle.yaml`, keeping the suite's "one task
      per built planner skill" claim true for `analyze`. 32 → 36 tasks. Two carry near-miss notes:
      `analyze-plan` (routing to `propose-comparison` opens a branch before the approach is settled)
      and `analyze-scaffold` ("I'll write the model myself" is the whole contract, so producing a
      working analysis is a failure rather than partial credit).

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 63 → 67 skills.
- [x] 4.2 `python3 tests/check-bench-fixtures.py` — clean at 36 tasks; every new
      `expected_delegates_to` resolves to an agent-providing plugin.
- [x] 4.3 `npm run spec:validate` — 24/24 with this change present.
- [x] 4.4 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.5 `python3 schemas/validate-ledger.py examples/project.yaml` — valid; no schema change here.
- [x] 4.6 `bash tests/e2e-smoke.sh` — unchanged; these are planner skills with no script and no new
      assertion. Stated rather than left implicit: **this change adds no test coverage.** Four
      skills' operating procedures are prose, and nothing in the suite exercises them. The refusal
      that matters most — a stub that raises — is a property of text the model is asked to follow,
      not of code that can be tested here.
- [x] 4.7 OpenCode install rewrite — the four skills survive the frontmatter rewrite.
