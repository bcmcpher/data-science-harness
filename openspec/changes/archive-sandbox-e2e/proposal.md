## Why

The archive toolbox was written against the real OSF, Zenodo and DataCite APIs, and no deposit has
been made through it. `README.md` says so (lines 253-258), and so does `docs/motivation.md`. The
only live test is a gated block in `tests/e2e-smoke.sh` (lines 428-466). When
`DSH_ZENODO_SANDBOX_TOKEN` is set, it creates a sandbox deposition, uploads a file, sets metadata,
publishes, and asserts a `10.5072/` DOI. It has never been run.

Even a passing run of that block would leave most of the Zenodo skill untested:

- **Relate** (`zenodo` skill step 9: `actions/edit`, merge `related_identifiers`, republish) is
  how `disseminate/link-outputs` writes a relation. It is untested.
- **A later version of the same product** has no path at all. The skill's deposit steps (4-8)
  always create a new deposition, so a second release would get an unrelated record and a new
  concept DOI. Zenodo's `actions/newversion` is not mentioned in the skill or in the archive doer.
- **Failure cleanup** does not exist: a failing `step` exits the script and leaves an unpublished
  draft in the sandbox account.
- **The OSF readiness gate** is not asserted, although `check-readiness.sh osf` has its own logic
  (the `datalad-osf` extension, plus `OSF_TOKEN` or `OSF_USERNAME` and `OSF_PASSWORD`). Only the
  Zenodo gate and the unknown-backend usage error are asserted (lines 410-426).

The user has a Zenodo sandbox account and no OSF test or DataCite test account. The Zenodo path is
therefore the one that can be exercised now.

## What Changes

- **The gated Zenodo block runs the full cycle.** In order: create, upload, set metadata, publish,
  relate, new version. Relate is `actions/edit`, then GET the record, merge a new entry into
  `metadata.related_identifiers`, PUT, publish, and GET again to verify. New version is
  `actions/newversion`, then upload a changed file to the new draft, set metadata and publish. Each
  test step carries a comment naming the `zenodo` skill step it mirrors.
- **Assertions on what came back.** Both publishes return a `10.5072/` DOI. The two versions share
  one `conceptdoi` and have different `doi`s. After relate, the record holds the pre-existing
  related identifier and the new one, each once, with Zenodo's lowerCamelCase `relation`.
- **Cleanup on failure.** If any step fails, the unpublished draft is removed before the script
  exits: an unpublished deposition is deleted, and an open edit of a published record is
  discarded. Published sandbox records cannot be deleted and are left in place.
- **The zenodo skill gains a new-version step.** When the product already has a Zenodo DOI, deposit
  creates a new version of that record through `actions/newversion` rather than a new deposition.
  The test mirrors this step, so the skill needs it first (design D2).
- **OSF readiness assertions**, all offline and matching the Zenodo ones: exit 1 and
  `missing: OSF_TOKEN` with no credentials; `OSF_USERNAME` without `OSF_PASSWORD` still missing;
  the credential value is never printed. Whether a sentinel token reaches `result: ready` depends on
  whether `datalad_osf` is importable, and the assertion branches on that.
- **OSF and DataCite live blocks are named and skipped** with the stated reason (no test account),
  so the log shows what was not run.
- **`docs/testing/archive-sandbox.md`**: how to get a sandbox.zenodo.org token with the
  `deposit:write` and `deposit:actions` scopes, export `DSH_ZENODO_SANDBOX_TOKEN`, and run the
  e2e suite in the conda `datalad` env. It also says what a pass proves and what it does not.
- **After the user's run**, the result is recorded: the date, the pass count and the sandbox DOIs
  in the doc, and the README and motivation caveats narrowed to what remains unexercised.

**Not in this change:** a production deposit, OSF or DataCite live tests, running the sandbox block
in CI (it would need a repository secret), and migrating the skill from the deposit API to the
InvenioRDM records API.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `archive`: sandbox verification of the Zenodo path and what it proves; OSF readiness asserted;
  the zenodo skill deposits a later version as a new version of the same record.

## Impact

- `tests/e2e-smoke.sh` (the archive readiness gate and the sandbox block, lines 410-466; the
  `cleanup` EXIT trap at line 52 gains the draft cleanup)
- `plugins/archive-cli/skills/zenodo/SKILL.md` (a new-version branch of deposit)
- `plugins/archive/agents/archive-doer.md` (deposit of a product that already has a Zenodo DOI
  follows the new-version step)
- New `docs/testing/archive-sandbox.md`
- After the run: `README.md` (lines 253-258), `docs/motivation.md` (capability-plane row),
  `README.md` Status line.
- No change to `check-readiness.sh`: the new assertions test its existing behaviour.
- CI is unaffected: the `e2e` job runs only on manual dispatch and sets no sandbox token, so the
  block self-skips there as it does today.
