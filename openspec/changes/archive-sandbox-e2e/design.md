## Context

`tests/e2e-smoke.sh` has two archive sections:

- **Readiness gate, always run** (lines 410-426). It asserts `check-readiness.sh zenodo` exits 1
  and names `ZENODO_TOKEN` when the token is absent, exits 0 when a sentinel token is present,
  never prints that sentinel, and that an unknown backend exits 2.
- **Sandbox deposit, gated** (lines 428-466). It runs only when `DSH_ZENODO_SANDBOX_TOKEN` is set
  and `curl` is on `PATH`. The endpoint is hard-coded to `https://sandbox.zenodo.org/api`, and the
  token is written to a mode-600 header file in `$WORKDIR`, so a failing `step` cannot echo it. It
  runs create, upload, metadata and publish, and asserts the DOI starts with `10.5072/`.

The sandbox token variable is deliberately not `ZENODO_TOKEN`, so a production token in the user's
environment can never reach this block.

Failures inside the block go through `step` (lines 66-81), which prints the failing command and
calls `exit 1`. The script's only EXIT trap is `cleanup` (lines 51-52), which deletes `$WORKDIR`. So
today a failure after create leaves an unpublished draft in the sandbox account.

The `zenodo` skill (`plugins/archive-cli/skills/zenodo/SKILL.md`) has these operations: check
(step 1), deposit (steps 4-8), relate (step 9) and lookup (step 10). Deposit always starts with
`POST /deposit/depositions`. There is no new-version path. `archive-doer.md` lists `deposit`,
`mint-doi`, `lookup-doi`, `relate` and `lookup-relations`, also with no new version. The ledger
keeps a product's DOIs as a flat list (`products[].dois`, `schemas/project.schema.json` line 64).

## Goals / Non-Goals

**Goals:**
- One command, given a sandbox token, exercises every Zenodo call the harness makes and asserts
  what Zenodo returned.
- A failed run leaves no unpublished draft behind.
- The OSF readiness gate is asserted offline, like Zenodo's.
- The documentation says plainly what a pass does and does not establish.

**Non-Goals:**
- Exercising the archive *doer*. The doer is an agent prompt; this tests the calls its skill
  prescribes, as the rest of `e2e-smoke.sh` tests the DataLad commands the planners prescribe.
- Production Zenodo, OSF (live) and DataCite (live). There is no account for the last two, and a
  production publish is permanent.
- Running the sandbox block in CI.

## Decisions

**D1. The test duplicates the skill's curl sequence, and each step names the step it mirrors.**
Each sandbox `step` gets a comment such as `# mirrors zenodo skill step 9 (relate): edit`. When
the skill changes, a reviewer can find the test lines to change by searching for the step number.

*Alternative (rejected): a shared `plugins/archive-cli/scripts/zenodo.sh` called by both the skill
and the test.* The test and the skill could then not drift. But it changes the toolbox's shape:
toolbox skills are prompts that show the calls, and the only script in `archive-cli/scripts/` is
the offline readiness check. A deposit script would move publishing logic, including the
irreversible publish, out of the prompt where the confirmation rule sits, and every backend would
then be expected to have one.

**D2. Add a new-version step to the zenodo skill in this change.** When the product being
deposited already has a Zenodo DOI in `products[].dois`, deposit does the following:

- `POST /deposit/depositions/<record id>/actions/newversion` on the latest published version;
- read the new draft from `links.latest_draft`;
- upload the new archive to the draft's bucket, and delete files carried over from the previous
  version that the new archive replaces;
- PUT the full metadata and publish, with the same confirmation as step 8.

The new `doi` is appended to `products[].dois`, and the `conceptdoi` is unchanged. The archive doer
routes such a deposit through this step. Without it, the test would assert behaviour no skill
prescribes, and a second release of a product would get an unrelated concept DOI.

*Alternative: leave new version out of the test.* That keeps this change to tests and docs. But
then the gap would stay invisible, and dataset releases are versioned by design
(`disseminate/dataset-release` tags `v<version>`).

**D3. Relate is tested for merge, not just for write.** The first deposit's metadata includes one
`related_identifiers` entry. Relate adds a second entry, `isSupplementTo` the DataLad JOSS paper
(`10.21105/joss.03262`, a stable public DOI). The merge is run twice with the same entry. A GET
after republishing must show both entries, each exactly once, and `relation` in lowerCamelCase.
This checks the skill's "do not drop existing ones, do not duplicate an identical one" rule against
what Zenodo stores.

*Alternative: relate the first version to the second.* Zenodo already links versions itself
through the concept record, so an explicit relation between them would test nothing extra.

**D4. Cleanup runs from the existing EXIT trap.** The block records its state in variables: the id
of an unpublished deposition, and the id of a published record that is open for edit. `cleanup`
calls a `zenodo_cleanup` function *before* it removes `$WORKDIR`, because the header file lives
there. The function deletes an unpublished deposition (`DELETE /deposit/depositions/<id>`) or
discards an open edit (`POST …/actions/discard`), ignores errors, and never prints the token. On
success, both variables are empty and the function does nothing.

*Alternative: an ERR trap or per-step `|| cleanup`.* `step` exits directly, so an ERR trap would
not see those failures, and per-step handling would repeat itself at every call.

**D5. OSF and DataCite live blocks are visible skips.** Each prints
`SKIP: <backend> live deposit — no test account; not exercised by this suite`. It does not look at
credentials. Even with OSF credentials set, the block must not run against production. The skill
says `datalad-osf` has not been verified against `api.test.osf.io`.

## Risks / Trade-offs

- [The test drifts from the skill] → D1's step comments; tasks add a line to the skill's
  constraints saying that `tests/e2e-smoke.sh` mirrors these steps.
- [Sandbox behaviour differs from production: DOI prefix, rate limits, the InvenioRDM migration] →
  The doc and the spec say a pass shows that the calls and parsing work against the sandbox. It
  does not show that a production DOI resolves.
- [The new-version draft carries the previous files, or rejects a publish with identical files] →
  The test uploads a file whose content differs, under a new name, so either behaviour passes. Which
  one the sandbox has is recorded after the first run.
- [Each run leaves published records in the sandbox account] → Unavoidable, since published
  records cannot be deleted, and harmless on the sandbox. The doc says so.
- [The token leaks through a failure message] → It stays in the header file. `zenodo_cleanup` uses
  the same file, and `step`'s command echo shows `-H @<file>`, not the value.

## Migration Plan

Test, skill and doc additions. Rollback means reverting them. The new-version step changes deposit
behaviour only for a product that already holds a Zenodo DOI, and no live deposit has ever been
made, so no existing record is affected.

## Open Questions

- **Is the new-version skill step in scope?** Default: **yes (D2).** Otherwise the test covers
  create through relate only, and the gap is recorded as a follow-up.
- **Where does the run's result live?** Default: in `docs/testing/archive-sandbox.md` under "Last
  run" (date, pass count, the two sandbox DOIs), with the README and motivation caveats narrowed to
  point at it.
- **Should the sandbox block run in CI from a repository secret?** Default: **no**, for now. It
  publishes records on every run, and `workflow_dispatch` runs are rare. Revisit once a manual run
  has passed.
