# annotate

## Purpose

The capability-plane wrapper over controlled-vocabulary tooling — Neurobagel (`bagel-cli`), NIDM
(`pynidm`), ReproSchema, and whichever licensed SNOMED CT source the user configures. It builds and
validates the machine-readable metadata that turns a directory of TSVs into a queryable research
object: `participants.json` data dictionaries, BIDS sidecars, and the term identifiers a federated
query can resolve. It advances STAMPED Metadata and Actionability.

Its defining property is refusal to recall. A controlled-term identifier is short, structured, and
unverifiable by eye, so a fabricated one is indistinguishable from a real one in the output and
survives into every downstream consumer. The doer therefore reports a variable as `unannotated` with
a reason rather than emitting a term no source returned, and reports a backend it could not reach as
`unavailable` — which is not the same finding as "no term matched", and leads the user to a different
action. Most of the toolbox validates terms rather than finding them: only a SNOMED query and an
interactive `pynidm` session resolve a new identifier.

It writes metadata files and never commits them; the planner saves them with `datalad save`, so
annotation joins the same provenance chain as the data it describes.
## Requirements
### Requirement: The annotate doer owns metadata-enrichment mechanics

The annotate doer MUST own all controlled-term lookup and metadata-file generation. Planner skills
MUST NOT call `bagel-cli`, `pynidm`, `reproschema`, or a terminology service directly.

#### Scenario: A planner needs a data dictionary

- **WHEN** `curate/annotate` needs `participants.json` generated from `participants.tsv`
- **THEN** it delegates to the annotate doer, which constructs and runs the tool invocation

### Requirement: Controlled terms are looked up, never recalled

The annotate doer MUST obtain every controlled-term identifier from a tool or terminology source it
actually queried. It MUST NOT emit an identifier produced from model knowledge.

#### Scenario: A term is found

- **WHEN** a variable maps to a controlled term
- **THEN** the doer reports the identifier together with the source it came from

#### Scenario: No lookup source is available

- **WHEN** the terminology tool or credential is absent
- **THEN** the doer reports the variable as unannotated with the reason, and emits no identifier

### Requirement: Backend availability degrades per tool

The annotate doer MUST check each backend independently and report which are available, so a dataset
can gain annotation from one vocabulary while another stays empty.

#### Scenario: One of several backends is installed

- **WHEN** `bagel-cli` is present but no SNOMED source is configured
- **THEN** Neurobagel annotation proceeds and SNOMED coverage is reported as unavailable, not as zero
  matches

### Requirement: The doer writes metadata but does not commit

The annotate doer MUST write metadata files into the dataset and MUST NOT commit them. The calling
planner MUST save them itself with `datalad save`.

#### Scenario: Annotation completes

- **WHEN** the doer finishes writing `participants.json` and sidecars
- **THEN** the files are on disk uncommitted, and the doer reports what it wrote for the planner to save

### Requirement: The toolbox provides one skill per tool

`plugins/annotate-cli/` MUST provide a `user-invocable: true` skill per supported tool, each with an
`argument-hint` and `allowed-tools` scoped to that tool, following the `datalad-cli` shape.

#### Scenario: A user drives a tool directly

- **WHEN** a user invokes an `annotate-cli` skill without a planner
- **THEN** the skill runs standalone

### Requirement: Every operation returns a structured result

The annotate doer MUST report the operation, the tool and version used, `result`, the files written,
per-variable coverage, and notes naming any unavailable backend.

#### Scenario: Partial coverage

- **WHEN** some variables are annotated and others are not
- **THEN** the report distinguishes them and states why each unannotated variable was skipped

### Requirement: Each annotate backend tool is checked against the real CLI

`tests/e2e-smoke.sh` MUST run each installable annotate backend from its own environment under
`tests/envs/`:

- `bagel pheno` on a fixture dictionary with sourced Neurobagel annotations;
- `bidsmri2nidm` on a one-subject BIDS fixture;
- `reproschema validate` on a minimal protocol fixture.

Each check MUST run whenever its environment is present and in sync with its lock. Otherwise it MUST
skip, naming `bin/test-envs sync <tool>`, with one exception: when the bagel environment is not
ready but a `bagel` command is on `PATH`, the bagel check MUST run that install instead and print a
`NOTE:` line naming its path. `bagel pheno` and `reproschema validate` cannot run
offline, so those two MUST also skip unless `DSH_NET=1`, saying so, and every live call MUST run
under a timeout. Inside each environment, the backend's
`check-backends.sh` answer MUST be `available`.

#### Scenario: bagel is synced

- **WHEN** `tests/envs/bagel` is synced and the e2e runs
- **THEN** `bagel pheno` produces a graph file from the annotated fixture, and the gate reports
  `bagel` available

#### Scenario: No network opt-in

- **WHEN** the bagel and reproschema environments are synced but `DSH_NET` is unset
- **THEN** both checks print one `SKIP:` line naming `DSH_NET=1`, and the pynidm check still runs

#### Scenario: No environments are synced

- **WHEN** none of the annotate environments exist and no `bagel` is on `PATH`
- **THEN** each live check prints one `SKIP:` line with its sync command, and the rest of the
  annotate section still passes

#### Scenario: bagel installed outside the harness

- **WHEN** `tests/envs/bagel` is missing, `bagel` is on `PATH`, and `DSH_NET=1`
- **THEN** the bagel check prints a `NOTE:` line naming that `bagel`, asserts it reports a version,
  and runs the same accept and reject assertions against it

### Requirement: A refusal is asserted for its reason, not only its exit code

A live check that asserts a tool rejects bad input MUST also assert that the rejection names the
defect under test. An exit code alone MUST NOT be accepted, because a usage error for a wrong flag
exits non-zero too.

#### Scenario: An unannotated dictionary

- **WHEN** `bagel pheno` is run on a dictionary with no `Annotations`
- **THEN** the check asserts a non-zero exit and an error about the missing annotations, and fails
  if the error is about an unrecognised option

### Requirement: Annotation fixtures carry no recalled identifiers

A fixture carrying controlled-term identifiers MUST be copied from a published source, and the
source and licence MUST be recorded beside it. A test MUST NOT hand-write a term identifier.

#### Scenario: Adding an annotated fixture

- **WHEN** a live check needs an annotated data dictionary
- **THEN** the fixture comes from Neurobagel's published example data, with a README naming where
  it came from

