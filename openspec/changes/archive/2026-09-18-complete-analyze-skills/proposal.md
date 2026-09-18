## Why

`README.md` has marked four `analyze` skills *(planned)* since the brownfield retrofit —
`plan-analysis`, `scaffold-analysis`, `plot`, `gen-report` — and none had an OpenSpec change. They
are the last unbuilt planners in the workflow plane apart from `literature-search`, which is
deferred on purpose.

They also sit over the harness's largest admitted hole. `docs/end-to-end-workflow.md` says it in two
places: *"there is no analysis-script scaffold and no plotting/visualization skill. The jump from
`plan-analysis` (choose a test) to `gen-report` (report results) skips the largest part of the work"*
(`:102`), and *"publication-figure preparation is again unscaffolded"* (`:162`). Both callouts name
skills that did not exist, so the document described the gap between two absences.

`analyze` is the plugin where fabrication is cheapest and most damaging. Every other planner records
something a person decided; these four sit next to the data and are asked, in order, which test to
run, what the script should do, what the figure shows and what the results were. Each of those has a
plausible wrong answer that is indistinguishable from a right one on inspection — a recalled
p-value, a stub that returns a constant, an illustrative figure, a filled-in table cell. The
refusals are therefore the substance of the change, exactly as they were for `govern`.

The division of labour is the same one the rest of the harness keeps: the harness owns the edges of
the work — the branch, the contract, the provenance, the record of what was produced — and the
researcher owns the science. `scaffold-analysis` is that division made literal: it writes everything
around the model and raises where the model goes.

## What Changes

- **`plan-analysis`** — recommend a statistical approach from the design and the data's shape, and
  list the assumptions it rests on as things *to be checked*. It states assumptions; it never
  asserts they hold, and it reports no statistic of any kind.
- **`scaffold-analysis`** — emit a runnable script stub wired for a provenanced run: argument
  parsing, declared inputs, a single output directory, and a `NotImplementedError` where the
  analysis goes. It never writes analysis logic, and the placeholder fails loudly rather than
  returning a plausible number.
- **`plot`** — build exploratory or publication figures from produced outputs, as a script run
  through `run-comparison` so the figure carries the same record as the analysis. Every value on a
  figure comes from an output file.
- **`gen-report`** — assemble results tables, QC metrics, figures and their provenance into one
  internal report, with a mandatory **gaps section**: assumptions never checked, comparisons never
  run, outputs produced outside a recorded run. Missing is reported as missing.

## Capabilities

### Modified Capabilities

- `analyze`: gains four planner skills covering the span from choosing an approach to reporting what
  a comparison produced. The capability's existing requirements are untouched.

## Impact

- New: `plugins/analyze/skills/{plan-analysis,scaffold-analysis,plot,gen-report}/SKILL.md`
- Modified: `plugins/analyze/.claude-plugin/plugin.json` (four registrations, description,
  0.1.0 → 0.2.0), `.claude-plugin/marketplace.json`, `README.md`,
  `docs/end-to-end-workflow.md`, `docs/motivation.md`, `bench/tasks/routing-lifecycle.yaml`
- No new capability plugin, no new doer, no schema change. All four are planners over the `datalad`
  doer, which already exists; `plot` routes execution through `analyze/run-comparison` rather than
  reaching the containers doer itself.
- 63 → 67 skills. Routing fixtures 32 → 36.
