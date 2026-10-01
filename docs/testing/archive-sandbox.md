# Testing the archive path against the Zenodo sandbox

The archive toolbox (`plugins/archive-cli`) was written against the real OSF, Zenodo and DataCite
APIs. `tests/e2e-smoke.sh` has a gated block that runs every Zenodo call the `zenodo` skill makes
against **sandbox.zenodo.org**, and asserts what the sandbox returns. This page says how to run it,
what a pass shows, and when it last ran.

## Running it

1. Create an account on [sandbox.zenodo.org](https://sandbox.zenodo.org). Sandbox accounts are
   separate from zenodo.org accounts, even when you sign in the same way.
2. In the sandbox, open **Account → Applications → Personal access tokens** and create a token with
   the `deposit:write` and `deposit:actions` scopes.
3. Export it under the sandbox-only name:
   ```bash
   export DSH_ZENODO_SANDBOX_TOKEN=…   # a sandbox token, never a zenodo.org one
   ```
   The block reads only `DSH_ZENODO_SANDBOX_TOKEN`, never `ZENODO_TOKEN`, so a production token in
   your environment cannot reach it. Its endpoint is hard-coded to `https://sandbox.zenodo.org/api`.
4. Run the suite in an environment with DataLad and git-annex, such as the conda env from
   `environment.yml` or an existing `datalad` env:
   ```bash
   source ~/miniconda3/etc/profile.d/conda.sh && conda activate datalad
   bash tests/e2e-smoke.sh
   ```

Without the token, the block prints `SKIP: Zenodo sandbox deposit` and makes no network call. CI
sets no token, so it always skips there.

## What the block does

Each step carries a comment naming the `zenodo` skill step it mirrors
(`plugins/archive-cli/skills/zenodo/SKILL.md`):

| Skill step | Calls | Asserted |
|---|---|---|
| 6-8, deposit | create a deposition, upload through its bucket, `PUT` the full metadata (with one related identifier), publish | `doi` starts with `10.5072/`; a `conceptdoi` is returned |
| 9, relate | `actions/edit`, `GET`, merge `isSupplementTo 10.21105/joss.03262` twice, `PUT`, publish, `GET` | the new relation is present exactly once, as `isSupplementTo`; the earlier relation is kept, exactly once |
| 6, new-version branch | `actions/newversion`, `GET links.latest_draft`, upload a changed file under a new name, `PUT` metadata with `version: v0.2.0`, publish | a new `10.5072/` `doi`, different from the first; the same `conceptdoi` |

The token is written to a mode-600 header file and passed as `-H @file`, so a failing step's
command echo shows the file name, not the value.

**If a step fails**, the script's exit trap deletes the unpublished deposition (or new-version
draft), or discards an open edit of a published record, before it removes its working directory.

**Every passing run leaves two published records in your sandbox account.** Published records
cannot be deleted, even on the sandbox. That is harmless there, but the account fills up over time.

## What a pass shows, and what it does not

A pass shows that the calls the `zenodo` skill prescribes, and the response fields it reads (`id`,
`links.bucket`, `doi`, `conceptdoi`, `links.latest_draft`, `metadata.related_identifiers`), work
against the sandbox.

It does **not** show:

- that a production DOI is minted or resolves. Sandbox `10.5072` DOIs resolve nowhere public;
- that a production deposit succeeds;
- that the OSF or DataCite paths work. Neither has run live (see below);
- that the archive doer, an agent prompt, follows the skill. The test runs the skill's calls, not
  the doer.

## Not yet exercised

The suite prints a SKIP line for each of these. Neither block looks at credentials, because any OSF
or DataCite credential in the environment is a production one.

**OSF live deposit.** Checked 2026-09-29:
- The OSF test server's API (`https://api.test.osf.io/v2/`) answers anonymous reads.
- An anonymous `POST /v2/nodes/` returns 401.
- test.osf.io accounts are separate from osf.io accounts.

A live block would need:

- **An account and token.** A verified test.osf.io account, and a personal access token from it,
  exported under a sandbox-only name such as `DSH_OSF_TEST_TOKEN`.
- **The test endpoint.** Confirmation that `datalad-osf` (through `osfclient`) can be pointed at
  `api.test.osf.io`. The `osf` skill has not verified this, so the first run is itself the
  experiment.
- **Cleanup.** A node deleted at the end. OSF projects, unlike Zenodo records, can be deleted while
  they are unregistered.

**DataCite live mint.** From DataCite's public documentation, checked 2026-09-29:

- **Access.** DataCite gives test accounts free to developers building DOI registration
  integrations, on request to `support@datacite.org`
  ([test accounts policy](https://support.datacite.org/docs/test-accounts-policy)). No paid
  membership is needed. An account issued to a prospective member is active for six months.
- **Endpoints.** The test instance is separate from production, with different credentials and a
  different prefix: Fabrica at `https://doi.test.datacite.org`, the REST API at
  `https://api.test.datacite.org`. Test DOIs resolve through `https://handle.test.datacite.org/`,
  not doi.org.
- **Authentication and records.** The REST API uses HTTP basic auth with the repository ID and
  password. `POST /dois` takes a JSON:API body (`data.type: "dois"`). With no `event` it creates a
  draft. `event: "publish"` makes the DOI findable, which requires creators, titles, publisher,
  publicationYear, `types.resourceTypeGeneral` and a `url`.
- **Deletion.** Only a *draft* DOI can be deleted. Registered and findable DOIs are permanent, even
  on the test instance.

A live block would export sandbox-only names (for example `DSH_DATACITE_TEST_REPOSITORY_ID`,
`DSH_DATACITE_TEST_PASSWORD` and `DSH_DATACITE_TEST_PREFIX`), and hard-code
`https://api.test.datacite.org`. It would then:

1. Create a draft and assert the returned DOI's prefix.
2. Update its `relatedIdentifiers` and read them back, to test the `datacite` skill's relate
   merge.
3. Delete the draft.

A findable test DOI would exercise `publish`, but it is permanent, so make it opt-in.

## Last run

**2026-10-01** — `bash tests/e2e-smoke.sh` with `DSH_ZENODO_SANDBOX_TOKEN` set: **149 passed, 0
failed**. The token appeared nowhere in the output.

- Record `10.5072/zenodo.612395`, concept DOI `10.5072/zenodo.612394`.
- Relate added `isSupplementTo 10.21105/joss.03262` once, kept the earlier `isDocumentedBy`
  entry once, and the record kept its DOI.
- New version `10.5072/zenodo.612396`, same concept DOI. The draft carried the previous file
  (`deposit.txt`) forward.
- Forced failure (bucket URL broken after create): the trap printed `cleanup: deleted unpublished
  sandbox deposition 612385`, and a `GET` on that deposition then returned 404.

The first live attempt failed at the relate republish, with HTTP 400 on `pids.doi`: "The prefix
'10.5072' is managed by Zenodo. Please supply an external DOI…". Writing the read-back metadata
unchanged sends the minted `doi` back, and Zenodo reads a supplied `doi` as an external one. The
`zenodo` skill's step 9 and the test now drop `doi` and `prereserve_doi` before the `PUT`. The
offline suite could not have caught this.

Production Zenodo, OSF and DataCite remain unexercised.
