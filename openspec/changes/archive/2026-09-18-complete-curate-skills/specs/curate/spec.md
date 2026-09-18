## ADDED Requirements

### Requirement: A merge is reported with the arithmetic that would expose its failure

`curate/merge-data` MUST take the join key from the user rather than inferring it, check key overlap
and uniqueness before merging, and produce the merged table as a provenanced run whose report states
rows in, rows out, keys matched and keys dropped per side. It MUST NOT reconcile conflicting values,
impute missing ones, or modify a source table in place.

#### Scenario: Two tables are combined

- **WHEN** phenotypic sources are merged on a supplied key
- **THEN** a new file is produced through a recorded run and the report carries the row and column
  arithmetic, so a silent drop or multiplication is visible

#### Scenario: The identifiers do not overlap

- **WHEN** key overlap is zero or near zero
- **THEN** the skill reports an identifier-format mismatch and stops, rather than producing an empty
  or tiny table that will be mistaken for a real one

#### Scenario: A join key is not supplied

- **WHEN** both tables contain a plausibly-matching column such as `id` or `participant_id`
- **THEN** the skill asks which key to join on rather than inferring that the columns mean the same
  thing

#### Scenario: Two sources disagree about a value

- **WHEN** the same participant has different values for a column in each source
- **THEN** the disagreement is reported as a data-quality finding and no precedence rule is applied
  silently

### Requirement: A data dictionary describes only what it was told

`curate/gen-data-dict` MUST derive the dictionary's skeleton — columns, types, observed levels —
from the data, and MUST obtain each column's meaning, units and level coding from the user or from
the `annotate` doer. An undescribed column MUST be omitted from the dictionary and named in the
report. The skill MUST NOT restate a column's name as its description, assume a unit, or overwrite
an existing description.

#### Scenario: A dictionary is generated

- **WHEN** a tabular file is documented
- **THEN** described columns get entries and the report names every column still undescribed, so the
  dictionary's completeness is visible rather than assumed

#### Scenario: A level coding is not supplied

- **WHEN** a column contains `0` and `1` and no coding was given
- **THEN** no meaning is written, because `1 = male` and `1 = female` are both common and a guess
  becomes documentation

#### Scenario: A column name suggests its content

- **WHEN** a column is called `age` and nothing states its units
- **THEN** the unit is asked for rather than assumed, since age in years and age in months both
  appear in phenotypic exports and a wrong unit silently rescales an analysis

#### Scenario: A controlled term was not looked up

- **WHEN** the annotate doer returns no identifier for a variable
- **THEN** the free-text description stays and no code is written, inheriting that doer's refusal to
  recall an identifier
