## ADDED Requirements

### Requirement: The Zenodo path is verifiable against the sandbox

`tests/e2e-smoke.sh` MUST contain a Zenodo sandbox block that runs only when
`DSH_ZENODO_SANDBOX_TOKEN` is set and `curl` is available, and that prints a skip line naming the
missing condition otherwise. It MUST target only `https://sandbox.zenodo.org/api`, and MUST NOT read
`ZENODO_TOKEN`. It MUST run, in order:

- create, upload, set metadata and publish;
- relate: edit, read, merge related identifiers, write, republish and read back;
- a new version of the same record.

Each step MUST carry a comment naming the `zenodo` skill step it mirrors.

The block MUST assert the following:
- each publish returns a DOI with the `10.5072/` prefix;
- the two versions share a concept DOI and have different version DOIs;
- after relate, the record holds its earlier related identifier and the new one, each exactly once.

If any step fails, the block MUST remove its unpublished draft or discard its open edit before the
script exits. The token MUST pass through a header file and MUST NOT appear in any output.

#### Scenario: No sandbox token

- **WHEN** the suite runs without `DSH_ZENODO_SANDBOX_TOKEN`
- **THEN** the block prints a skip line, makes no network call, and the rest of the suite runs

#### Scenario: A full sandbox run

- **WHEN** the suite runs with a valid sandbox token
- **THEN** a record is published, related, and given a second version, and every assertion above
  holds

#### Scenario: A step fails after the deposition is created

- **WHEN** the upload or the metadata call fails
- **THEN** the unpublished deposition is deleted from the sandbox account before the script exits,
  and the failure output does not contain the token

#### Scenario: A production token is in the environment

- **WHEN** `ZENODO_TOKEN` is set and `DSH_ZENODO_SANDBOX_TOKEN` is not
- **THEN** the sandbox block is skipped and nothing is sent to any Zenodo endpoint

### Requirement: Sandbox verification states what it proves

`docs/testing/archive-sandbox.md` MUST explain how to obtain a sandbox.zenodo.org token with the
`deposit:write` and `deposit:actions` scopes, and how to export `DSH_ZENODO_SANDBOX_TOKEN` and run
the suite in the conda `datalad` environment. It MUST state that a pass shows the calls the `zenodo`
skill prescribes, and the response fields it reads, work against the sandbox. It MUST also state
what a pass does not show:

- that a production DOI is minted or resolves; sandbox `10.5072` DOIs resolve nowhere public;
- that a production deposit succeeds;
- that the OSF or DataCite paths work;
- that the archive doer, an agent prompt, follows the skill.

It MUST record the date and outcome of the last run. Project documentation MUST NOT describe the
archive path as verified beyond what that record shows.

#### Scenario: The sandbox run passes

- **WHEN** a sandbox run passes and its result is recorded
- **THEN** the README may say the Zenodo deposit path has run against the sandbox, and still says
  production Zenodo, OSF and DataCite are unexercised

### Requirement: The OSF readiness gate is asserted offline

`tests/e2e-smoke.sh` MUST assert `check-readiness.sh osf` without network access, as it does for
`zenodo`. With no OSF credentials it exits 1 and names `OSF_TOKEN`. `OSF_USERNAME` without
`OSF_PASSWORD` still names `OSF_TOKEN`. A sentinel credential value is never printed. The result
with a sentinel token depends on whether the `datalad-osf` extension is importable, and the
assertion MUST account for both cases. The OSF and DataCite live deposits MUST appear as skip lines
that give the reason they are not run.

#### Scenario: No OSF credentials

- **WHEN** the check runs for `osf` with no `OSF_TOKEN`, `OSF_USERNAME` or `OSF_PASSWORD`
- **THEN** it exits 1 and prints `missing: OSF_TOKEN`, and the suite asserts both

#### Scenario: A token without the extension

- **WHEN** `OSF_TOKEN` is set and `datalad_osf` cannot be imported
- **THEN** the check exits 1 naming only the extension, and the token's value is not in its output

### Requirement: A later version is deposited as a new version of the same record

When a product that already holds a Zenodo DOI is deposited again, the `zenodo` skill SHALL create
a new version of that record through the deposit API's `actions/newversion`, and SHALL NOT create
an unrelated deposition. The confirmation before publishing SHALL apply as for a first deposit. The
skill SHALL report the new version DOI and the unchanged concept DOI.

#### Scenario: Releasing v0.2.0 of a deposited product

- **WHEN** a product whose `dois` include a Zenodo DOI for `v0.1.0` is deposited at `v0.2.0`
- **THEN** the new record is a version of the same concept, and its DOI is returned from the
  publish response, never constructed
