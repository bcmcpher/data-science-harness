# analyze

## Purpose

The workflow-plane plugin implementing the comparison model — the harness's answer to the fact that
real papers are a series of small analyses introduced in unpredictable order, not a rigid pipeline.
A comparison is one lightweight, addable unit realized as a DataLad branch plus a provenanced run.
It sits on a rigor spectrum: an exploratory query has zero ledger footprint and can be discarded
freely, while a confirmatory one is frozen by `govern/preregister` first. Kept comparisons are
grouped into products. Provides `plan-analysis`, `propose-comparison`, `scaffold-analysis`,
`run-comparison`, `plot`, `checkpoint`, `manage-product` and `gen-report`.

Its recurring problem is that the wrong answer here is a number, and a number is not obviously
wrong. So `plan-analysis` states assumptions without asserting them and reports no statistic,
`scaffold-analysis` raises where the model goes rather than returning a plausible value, `plot`
draws only what an output file contains, and `gen-report` reports a missing result as missing.

## Requirements
### Requirement: A comparison is a branch plus a record, not a pipeline stage

`analyze/propose-comparison` MUST capture what is being compared and why, its inputs and expected
outputs, and its rigor mode, then create a clearly named `cmp/*` branch through the datalad doer.
A comparison MUST be introducible at any point in the project.

#### Scenario: A new analysis is proposed

- **WHEN** a user asks to look at one variable against another
- **THEN** a `cmp/*` branch exists for it and the proposal is recorded

#### Scenario: The bar to propose is low

- **WHEN** the user gives only a one-line description of an exploratory query
- **THEN** the comparison is created without demanding a full analysis plan

### Requirement: Exploratory comparisons have no ledger footprint

An exploratory comparison MUST live only as a branch and its run. It MUST NOT be written into
`project.yaml` `products[]` unless and until it is promoted.

#### Scenario: An exploratory query is discarded

- **WHEN** a quick comparison does not tell the story
- **THEN** the branch can be pruned and the ledger is unchanged by its existence

#### Scenario: An exploratory query is kept

- **WHEN** a comparison is worth publishing
- **THEN** it touches the ledger for the first time by being grouped into a product

### Requirement: Confirmatory comparisons are checked against their frozen spec

A comparison whose rigor mode is confirmatory MUST have been registered by `govern/preregister`
before execution, and its result MUST be checked against the registered spec.

#### Scenario: A registered comparison is executed

- **WHEN** a confirmatory comparison completes
- **THEN** its corresponding obligation moves to met, and any deviation from the frozen spec is
  recorded and reportable

### Requirement: Comparisons execute with full provenance inside the project container

`analyze/run-comparison` MUST confirm it is on the comparison's branch, gather the run's inputs,
outputs, and message, ensure the container image exists via the containers doer, and delegate
execution to the datalad doer as a `container-run`.

#### Scenario: A comparison is run

- **WHEN** the analysis script for a `cmp/*` branch is executed
- **THEN** the commit records the command, inputs, outputs, and the container image's annex key

#### Scenario: The container image is missing

- **WHEN** no built image exists for the project's recipe
- **THEN** the containers doer builds it and the datalad doer registers it before the run, rather
  than the analysis falling back to the host environment

### Requirement: Products group kept comparisons into deliverables

`analyze/manage-product` MUST verify that each named comparison exists and is complete before adding
it, then upsert a product into `products[]` rather than appending a duplicate.

#### Scenario: Grouping comparisons into a paper

- **WHEN** several kept comparisons are grouped
- **THEN** one product entry lists them, and re-running the skill with an additional comparison
  updates that entry instead of creating a second one

#### Scenario: A named comparison does not exist

- **WHEN** a comparison branch cannot be found
- **THEN** the skill reports it and does not record the product as if the comparison were present

### Requirement: Checkpoint leaves the tracking chain unbroken

`analyze/checkpoint` MUST inspect state, compose a descriptive message, save through the datalad
doer, and log the checkpoint. It MUST NOT use an empty or placeholder message.

#### Scenario: Ending a work session

- **WHEN** a user wraps up before switching context
- **THEN** the tree is clean, the snapshot carries a message describing what changed, and the branch
  it ended on is reported

### Requirement: A statistical approach is recommended with its assumptions stated, never asserted

`analyze/plan-analysis` MUST establish the design from the user — outcome, predictors, unit of
observation, dependence structure, covariates and rigor mode — inspect the data's shape rather than
its values, and name one recommended approach with the assumptions it rests on listed as items to be
checked. It MUST NOT assert that any assumption holds, and MUST NOT report any statistic.

#### Scenario: A test is recommended

- **WHEN** a user describes a design and asks what test to run
- **THEN** one approach is recommended with what it estimates and what would make it wrong, and its
  assumptions are listed as unchecked, marked as the researcher's to verify

#### Scenario: The dependence structure is ambiguous

- **WHEN** the data contain a column such as `session` or `run` that may or may not indicate
  repeated measures
- **THEN** the skill asks rather than inferring the design from the column name

#### Scenario: A number is requested before the analysis exists

- **WHEN** the recommendation would be more persuasive with an effect size, a p-value or a power
  figure
- **THEN** none is produced, and the skill states that a power calculation is a separate analysis
  with its own inputs

### Requirement: An analysis stub is scaffolded without its analysis

`analyze/scaffold-analysis` MUST write a script stub containing argument parsing, loading of the
declared inputs, creation of a single declared output directory, and a placeholder where the
analysis goes, together with the exact `analyze/run-comparison` invocation that will execute it. The
placeholder MUST fail loudly when reached. The skill MUST NOT write model specification, feature
engineering, estimator or hyperparameter choices.

#### Scenario: A stub is generated for a comparison

- **WHEN** a comparison branch exists and its script does not
- **THEN** a stub is written to `code/` encoding the agreed inputs, output directory and run
  command, and the analysis section raises

#### Scenario: The stub is executed before the analysis is written

- **WHEN** the stub runs
- **THEN** it fails at the placeholder rather than producing a constant, a simulated result or an
  empty result file

#### Scenario: An input path is not supplied

- **WHEN** the input files are not named by the user and do not exist
- **THEN** the skill asks for them rather than writing a plausible path into the stub

### Requirement: Figures are drawn only from produced outputs, under provenance

`analyze/plot` MUST locate the comparison's produced output files, write a figure script that reads
only those files and writes into the comparison's figure directory, and route execution through
`analyze/run-comparison` so the figure carries a run record. Every value shown MUST come from an
output file.

#### Scenario: A publication figure is requested

- **WHEN** a kept comparison's results are to be plotted for a paper
- **THEN** a figure script is written against the result files and run under provenance, and the
  figure is reported alongside the output file it was drawn from

#### Scenario: The analysis has not been run

- **WHEN** the expected outputs are absent
- **THEN** the skill reports that the analysis has not produced results and draws nothing, rather
  than producing an example or placeholder figure

#### Scenario: An annotation is not in any output

- **WHEN** a significance marker, sample size or effect size would be added to a panel
- **THEN** it appears only if the analysis wrote it to a file

### Requirement: A report states what was produced and what is missing

`analyze/gen-report` MUST assemble, for one comparison or one product's comparisons, the results
tables, figures, QC metrics and the commit behind each output, reading every reported value from a
produced file. It MUST include a gaps section naming assumptions never checked, comparisons not run
or failed, and outputs produced outside a recorded run. It MUST NOT state that a result is
significant, robust, replicated or publication-ready.

#### Scenario: Results are collected for review

- **WHEN** a comparison has run and its results are to be circulated
- **THEN** a report is written whose every value traces to an output file and whose provenance
  section names the commits and container behind them

#### Scenario: A result is absent

- **WHEN** a value the plan promised is in no output file
- **THEN** the cell reads `not reported` and the gap is listed, rather than the row being omitted or
  the value supplied

#### Scenario: An output has no run behind it

- **WHEN** an output file was produced by hand rather than by a recorded run
- **THEN** the report says so, because an output without provenance is a different claim from one
  with it

