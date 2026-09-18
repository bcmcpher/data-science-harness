## ADDED Requirements

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
