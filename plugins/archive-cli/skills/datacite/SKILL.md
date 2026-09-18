---
name: datacite
description: >
  Auto-invoke when the user wants to mint a DOI under their own DataCite prefix, add or read
  RelatedIdentifier relations on a DataCite DOI, look up any DOI's DataCite metadata, or check
  whether an identifier resolves. Trigger on "mint a DataCite DOI", "register a DOI under our
  prefix", "add a related identifier", "what does this DOI link to", "does this DOI resolve", or
  /datacite. Do NOT trigger for minting through Zenodo or OSF (use the zenodo or osf skill).
argument-hint: '[check|mint|relate|lookup|resolve] [<doi>] [--test]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep
---

# Skill: datacite

Mint DOIs under the user's own registered DataCite prefix, write `RelatedIdentifier` relations onto
those DOIs, and look up or resolve any DOI. Minting and writing need a DataCite repository account;
lookup and resolution need nothing.

DataCite accepts writes only from the repository that minted a DOI. A Zenodo DOI (`10.5281/zenodo.*`)
or an OSF DOI (`10.17605/OSF.IO/*`) cannot be changed here, even though both are DataCite DOIs:
relations on a Zenodo DOI go through the `zenodo` skill, and relations on an OSF DOI are
ledger-only.

## Steps

1. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): step 2 only.
   - **mint**: steps 2-5.
   - **relate**: steps 2-3, then 6.
   - **lookup**: step 7. No credentials.
   - **resolve**: step 8. No credentials.

2. **Check readiness** — for mint and relate only:
   ```bash
   plugins/archive-cli/scripts/check-readiness.sh datacite
   ```
   Exit 1 prints `result: unminted` and the missing variables (`DATACITE_REPOSITORY_ID`,
   `DATACITE_PASSWORD`, `DATACITE_PREFIX`). Stop and report it.

3. **Choose the endpoint and pass credentials safely** — `DATACITE_API` defaults to
   `https://api.datacite.org`; use `https://api.test.datacite.org` with a test account for anything
   that is a test. Basic auth goes through a netrc file, never `-u` on a command line:
   ```bash
   NETRC="$(mktemp)"
   ( umask 077; printf 'machine %s login %s password %s\n' \
       "$(printf '%s' "${DATACITE_API:-https://api.datacite.org}" | sed 's#^https://##; s#/.*##')" \
       "$DATACITE_REPOSITORY_ID" "$DATACITE_PASSWORD" > "$NETRC" )
   ```
   Every write below uses `--netrc-file "$NETRC" -H 'Content-Type: application/vnd.api+json'`.

4. **Create a draft DOI** — a draft is not public and can be deleted. Omit `event` to create one,
   and give `prefix` to let DataCite assign the suffix:
   ```bash
   curl -fsS -X POST --netrc-file "$NETRC" -H 'Content-Type: application/vnd.api+json' \
        --data @doi.json "$DATACITE_API/dois"
   ```
   `doi.json` is `{"data": {"type": "dois", "attributes": {...}}}` with `prefix`, `creators`,
   `titles`, `publisher`, `publicationYear`, `types.resourceTypeGeneral`, and `url`. Take them from
   the ledger's product and `contributors[]`. `url` must be a landing page that exists and that the
   user controls; ask for it, never invent one. The DOI is `data.id`.

5. **Publish (irreversible)** — a findable DOI cannot be deleted. Show the draft's metadata and the
   call, then ask:
   > "Publishing makes `<doi>` permanent and findable. Publish?"

   Only after confirmation, `PUT $DATACITE_API/dois/<doi>` with
   `{"data": {"type": "dois", "attributes": {"event": "publish"}}}`. Report the DOI only when the
   response carries `"state": "findable"`.

6. **Relate** — only for a DOI that starts with `$DATACITE_PREFIX/`. Two traps shape the steps:
   `PUT` replaces `relatedIdentifiers` wholesale, and `PUT` *creates* a DOI that does not exist.
   ```bash
   curl -fsS --netrc-file "$NETRC" "$DATACITE_API/dois/<doi>" > current.json   # must be HTTP 200
   ```
   If the GET is not 200, stop: never `PUT` a DOI that is not already there. Merge the new entries
   into `data.attributes.relatedIdentifiers` (keep existing ones, skip an identical one), show the
   merged list, confirm, then `PUT` it back as `{"data": {"type": "dois", "attributes":
   {"relatedIdentifiers": [...]}}}`. Each entry is:
   ```json
   {"relatedIdentifier": "10.x/y", "relatedIdentifierType": "DOI",
    "relationType": "IsSupplementTo", "resourceTypeGeneral": "Dataset"}
   ```
   `relationType` is PascalCase, as in `plugins/disseminate/references/datacite-relations.md`. For a
   target that is a URL rather than a DOI, `relatedIdentifierType` is `URL`.

7. **Lookup** — any DataCite DOI, including Zenodo and OSF DOIs, with no credentials:
   ```bash
   curl -sS -o lookup.json -w '%{http_code}\n' "https://api.datacite.org/dois/<doi>"
   ```
   200 returns the record; relations are `data.attributes.relatedIdentifiers`. 404 means DataCite
   does not know it. A `10.5072` test DOI is looked up at `https://api.test.datacite.org` instead.
   Draft DOIs are probably not visible anonymously.

8. **Resolve** — check that an identifier is registered with the DOI system, whoever minted it:
   ```bash
   curl -sS "https://doi.org/api/handles/<doi>"
   ```
   `"responseCode": 1` means registered; the `URL`-typed entry in `values` is the landing page.
   `"responseCode": 100` (HTTP 404) means not found. Treat anything else, including HTTP 200 with a
   different code, as unresolved. A network failure is **unresolved, not invalid** — say which.
   Test-prefix `10.5072` DOIs never resolve here.

## Constraints

- Run the readiness check before mint or relate. Without credentials, report `result: unminted`.
- A DOI appears in a report only when DataCite returned it and its state is `findable`.
- Write only DOIs under `$DATACITE_PREFIX`. For any other DOI, report which skill owns it or that
  the relation is ledger-only.
- Never `PUT` without a successful GET of the same DOI first, and never drop existing
  `relatedIdentifiers`.
- Show the exact call and confirm before publishing or changing a findable DOI.
- Never put the repository password on a command line, in a file inside the dataset, or in a report.
- On an HTTP error, surface DataCite's `errors[].title` and stop.
