## ADDED Requirements

### Requirement: Raw-to-BIDS routes by dataset layout

`curate/raw-to-bids` SHALL route to the nipoppy doer when the dataset has `config.json` and
`manifest.tsv`, and to the heudiconv doer otherwise. It SHALL declare
`delegates_to: [nipoppy, heudiconv]`, SHALL state the route in its report, and SHALL phrase both
requests in words, quoting no converter command line.

#### Scenario: A YODA dataset with DICOMs

- **WHEN** a dataset created by `project/new-project` has DICOMs under `inputs/` and no nipoppy
  files
- **THEN** the planner delegates to the heudiconv doer

#### Scenario: A nipoppy dataset

- **WHEN** the dataset has `config.json` and `manifest.tsv`
- **THEN** the planner delegates to the nipoppy doer as before, even if nipoppy's configured
  converter is HeuDiConv

### Requirement: A scaffolded heuristic is confirmed and saved before conversion

When the heudiconv doer returns `result: needs-confirmation`, `curate/raw-to-bids` SHALL show the
series-to-BIDS mapping to the user and SHALL wait for confirmation or edits. It SHALL save the
heuristic with `datalad save`, carrying `DSH-Op: raw-to-bids`, before asking for the conversion
command. The saved heuristic SHALL be a declared input of the conversion run.

#### Scenario: The user edits a mapping

- **WHEN** the user renames one series' target in the scaffold
- **THEN** the edited file is saved in its own commit, and the conversion run lists it as an input

## MODIFIED Requirements

### Requirement: Raw-to-BIDS conversion is provenanced

`curate/raw-to-bids` MUST have the routed doer (nipoppy or heudiconv) construct the converter
invocation, MUST ensure a clean tree, and MUST execute the returned command itself under
`datalad run` with explicit inputs and outputs. It MUST NOT run the converter outside the
provenance chain. The run commit MUST carry every `DSH-Binding` the doer returned.

#### Scenario: DICOMs are converted

- **WHEN** raw imaging data is converted with a named converter and version
- **THEN** the resulting commit records the command, inputs, and outputs, and the BIDS tree is
  reachable through that run

#### Scenario: The tree is dirty

- **WHEN** uncommitted changes exist at conversion time
- **THEN** the skill resolves that with `datalad save` before running, because `datalad run`
  requires a clean tree

#### Scenario: A HeuDiConv conversion

- **WHEN** the heudiconv doer returns a conversion with heudiconv and dcm2niix bindings
- **THEN** the run commit carries both `DSH-Binding` lines

### Requirement: Curation status is recorded after conversion

After a successful conversion on the nipoppy route, `curate/raw-to-bids` MUST update nipoppy's
curation status and save it in a commit whose message names the converter, its version, and the
scope converted, and carries `DSH-Op: raw-to-bids` and `DSH-Stage` lines, with a `DSH-Binding`
line for the converter named in the nipoppy doer's result. On the heudiconv route there is no
curation-status file, and the run commit is the record.

#### Scenario: Conversion completes

- **WHEN** the run succeeds on the nipoppy route
- **THEN** curation status is updated and saved, and that commit's message records what was
  converted together with its `DSH-Op`, `DSH-Stage` and `DSH-Binding` lines

#### Scenario: HeuDiConv conversion completes

- **WHEN** the run succeeds on the heudiconv route
- **THEN** no curation-status commit is made, and the report points to the run commit
