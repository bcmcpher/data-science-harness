## ADDED Requirements

### Requirement: A heudiconv doer and toolbox exist as a separate capability

The harness SHALL provide a `heudiconv` doer plugin (`plugins/heudiconv/agents/heudiconv-doer.md`)
and a `heudiconv-cli` toolbox plugin with one skill per pass: inspect, heuristic and convert. It
SHALL also provide an offline check for `heudiconv` and `dcm2niix`. The doer SHALL NOT pin a
`model:`, because it writes files. BIDS validation SHALL stay with the read-only bids doer.

#### Scenario: The lint reads the new plugins

- **WHEN** `tests/lint-plugins.py --strict` runs after this change
- **THEN** it reports no errors, and `heudiconv` is listed among the delegation targets

### Requirement: The first pass inspects DICOMs without writing into the dataset

The doer SHALL run HeuDiConv's first pass (`-c none`) itself, with its output directory outside
the dataset, and SHALL build its series table from the resulting `dicominfo` file. It SHALL NOT
write the first pass into the dataset. When DICOM content is annexed and absent, it SHALL report
the missing paths instead of fetching them.

#### Scenario: Inspecting a session

- **WHEN** the doer is asked to inspect `inputs/dicom/` for one subject
- **THEN** it returns the series with their protocol names, and `datalad status` in the dataset
  is unchanged

#### Scenario: Content is not present

- **WHEN** the DICOM files are annex pointers without content
- **THEN** the doer returns `result: failed` naming the paths for the planner to `datalad get`

### Requirement: ReproIn is selected when every series follows the convention

The doer SHALL select HeuDiConv's built-in `reproin` heuristic when every non-derived series'
protocol name parses as ReproIn. It SHALL return the series table with the BIDS name each series
will receive. When any series does not parse, it SHALL NOT select `reproin`.

#### Scenario: ReproIn-named phantom data

- **WHEN** the series are named `anat-scout` and `fmap_acq-3mm`
- **THEN** the doer selects `reproin` and returns both series with their target names

#### Scenario: One series is named freely

- **WHEN** one non-derived series is named `t1_mprage_sag`
- **THEN** the doer does not select `reproin` and scaffolds a custom heuristic instead

### Requirement: A custom heuristic is scaffolded in the dataset's code for confirmation

When `reproin` is not selected, the doer SHALL write a heuristic scaffold to
`code/heuristics/<name>.py`. The scaffold SHALL have one key per series it can place, and it SHALL
list the series it could not place. The doer SHALL return `result: needs-confirmation` with
`save_via: planner`, and SHALL NOT construct the conversion command until the planner asks again
after the user has confirmed.

#### Scenario: A scaffold is written

- **WHEN** a dataset's series do not follow ReproIn
- **THEN** `code/heuristics/<name>.py` exists, the result lists unplaced series, and no conversion
  command is returned

### Requirement: The conversion command is constructed for the planner's datalad run

The doer SHALL construct the second-pass command and SHALL NOT execute it. The command SHALL
write BIDS output at the dataset root with an explicit empty locator, and SHALL NOT use
`--datalad`. The doer SHALL return the command's inputs (the DICOM source, and the heuristic file
when custom) and outputs, with `run_via: planner`. It SHALL also return bindings for heudiconv and
dcm2niix, read from the installed tools. The doer SHALL NOT commit.

#### Scenario: A ReproIn conversion is requested

- **WHEN** the planner asks for the conversion command after a ReproIn inspection
- **THEN** the result has a command naming `reproin` and `-l ''`, declared inputs and outputs,
  `run_via: planner`, and bindings `heudiconv/heudiconv@<version>` and
  `heudiconv/dcm2niix@<version>`

#### Scenario: A template input is used

- **WHEN** the command uses a `-d` template with `{subject}`
- **THEN** the braces are doubled, because `datalad run` formats the command string

### Requirement: HeuDiConv's info directory is annexed

Before the first conversion in a dataset, the toolbox SHALL have the planner add a
`.gitattributes` rule annexing `.heudiconv/` and save it, because `dicominfo` holds patient
identifiers.

#### Scenario: First conversion

- **WHEN** a conversion completes in a dataset that had no such rule
- **THEN** the files under `.heudiconv/` are annexed, not stored as git blobs
