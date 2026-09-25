---
name: zenodo
description: >
  Auto-invoke when the user wants to deposit a tagged dataset or product version to Zenodo, mint a
  Zenodo DOI, publish or edit a Zenodo record, add related identifiers to a Zenodo record, or check
  whether Zenodo is usable. Trigger on "deposit to Zenodo", "mint a Zenodo DOI", "publish on
  Zenodo", "upload to the Zenodo sandbox", "link this Zenodo record", or /zenodo. Do NOT trigger for
  a DOI minted by another archive, or for pushing to a DataLad sibling (use /datalad push).
argument-hint: '[check|deposit|relate|lookup] [--version <tag>] [--sandbox]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep
---

# Skill: zenodo

Deposit an already-tagged dataset or product version to Zenodo, publish it, and read back the DOI
Zenodo assigns — or add related identifiers to a record Zenodo already holds. Publishing is
irreversible: a published record and its DOI cannot be withdrawn.

This skill uses Zenodo's deposit API (`/api/deposit/depositions`). It still works on Zenodo's
InvenioRDM backend and is still documented, but it was announced for deprecation; the native
equivalents are listed under **Reference** so a migration changes this skill and nothing else.

## Steps

1. **Check readiness** — run the toolbox's offline presence check:
   ```bash
   plugins/archive-cli/scripts/check-readiness.sh zenodo
   ```
   Exit 1 prints `result: unminted` and the missing item. Stop there and report it, with the
   `enable:` hint. Never continue on a guessed or placeholder token.

2. **Choose the endpoint** — `ZENODO_API` defaults to `https://zenodo.org/api`. For anything that is
   a test, use the sandbox: `ZENODO_API=https://sandbox.zenodo.org/api` with a token from a separate
   sandbox.zenodo.org account. Sandbox DOIs carry the `10.5072` test prefix and resolve nowhere
   public. Every call below sends `Authorization: Bearer $ZENODO_TOKEN`, read from a header file
   rather than written into a command line:
   ```bash
   ZAUTH="$(mktemp)"; ( umask 077; printf 'Authorization: Bearer %s\n' "$ZENODO_TOKEN" > "$ZAUTH" )
   ```

3. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): step 1 only.
   - **deposit**: steps 4-8.
   - **relate**: step 9.
   - **lookup**: step 10.

4. **Confirm the version is releasable** — the tag must exist and the checkout must be exactly that
   tag, with a clean tree:
   ```bash
   git tag -l "<tag>"
   git describe --tags --exact-match HEAD
   datalad status
   ```
   If the tag is missing, or HEAD is not at it, stop and ask. Never create or move a tag.

5. **Package the tagged state** — export it with `datalad export-archive`, which includes annexed
   content that is locally present (see `plugins/datalad-cli/skills/datalad/references/verbs/export.md`). Run
   `datalad get` first for any annexed file the deposit must contain.

6. **Create the deposition and upload** — create an empty deposition, then upload through its bucket
   (the multipart `/files` endpoint is deprecated and capped at 100 MB):
   ```bash
   curl -fsS -X POST -H @"$ZAUTH" -H 'Content-Type: application/json' -d '{}' \
        "$ZENODO_API/deposit/depositions" > deposition.json
   # read `id` and `links.bucket` from deposition.json
   curl -fsS -X PUT -H @"$ZAUTH" --upload-file <archive> "<links.bucket>/<filename>"
   ```
   Ignore `metadata.prereserve_doi` in the response: it is always present, and its `10.5281` prefix
   is wrong on the sandbox. The DOI is read after publishing.

7. **Set metadata** — `PUT` replaces the whole metadata block, so send the complete object:
   ```bash
   curl -fsS -X PUT -H @"$ZAUTH" -H 'Content-Type: application/json' --data @metadata.json \
        "$ZENODO_API/deposit/depositions/<id>"
   ```
   `metadata.json` holds `{"metadata": {...}}` with at least `upload_type`, `title`,
   `creators` (`[{"name": "Family, Given", "orcid": "..."}]`), `description`, `access_right`, and
   `license`. Take these from the ledger's product and `contributors[]`; ask for anything missing.

8. **Publish (irreversible)** — show the exact call and the record it will publish, then ask:
   > "Publishing makes this record and its DOI permanent. Publish deposition `<id>` to
   > `<ZENODO_API>`?"

   Only after confirmation:
   ```bash
   curl -fsS -X POST -H @"$ZAUTH" "$ZENODO_API/deposit/depositions/<id>/actions/publish" > published.json
   ```
   Read `doi` (this version) and `conceptdoi` (all versions) from the response. Report the `doi`,
   and the record URL from `links.html`.

9. **Relate** — add related identifiers to a record Zenodo owns. A published record is edited,
   updated, and republished:
   ```bash
   curl -fsS -X POST -H @"$ZAUTH" "$ZENODO_API/deposit/depositions/<id>/actions/edit"
   curl -fsS -H @"$ZAUTH" "$ZENODO_API/deposit/depositions/<id>" > current.json
   ```
   Merge the new entries into the existing `metadata.related_identifiers` (do not drop existing ones,
   do not duplicate an identical one), `PUT` the full metadata as in step 7, confirm as in step 8,
   then `actions/publish`. To abandon an edit, `POST .../actions/discard`. Each entry is:
   ```json
   {"identifier": "10.x/y", "relation": "isSupplementTo", "resource_type": "dataset"}
   ```
   Zenodo spells `relation` in lowerCamelCase: DataCite's `IsSupplementTo` is Zenodo's
   `isSupplementTo`. There is no scheme field; Zenodo detects it from the identifier. If the source
   DOI is not a Zenodo DOI (`10.5281/zenodo.*`, or `10.5072/zenodo.*` on the sandbox), this skill
   cannot write it — report that the relation is ledger-only.

10. **Lookup** — no token needed. A production DOI's metadata and relations come from DataCite's
    public REST API, and a sandbox DOI from its test API:
    ```bash
    curl -fsS "https://api.datacite.org/dois/<doi>"        # HTTP 404 = not a DataCite DOI
    curl -fsS "https://api.test.datacite.org/dois/<doi>"   # 10.5072 sandbox DOIs
    ```
    Relations are in `data.attributes.relatedIdentifiers`.

## Reference

Native InvenioRDM equivalents, for when the deposit API is retired: create a draft with
`POST /api/records`; upload with `POST /api/records/<id>/draft/files`, then
`PUT .../files/<key>/content` and `POST .../files/<key>/commit`; publish with
`POST /api/records/<id>/draft/actions/publish`; edit a published record with
`POST /api/records/<id>/draft`, then `PUT` and publish. The DOI is at `pids.doi.identifier`, and a
related identifier is `{"identifier": ..., "scheme": "doi", "relation_type": {"id": "issupplementto"}}`.

Load `plugins/disseminate/references/datacite-relations.md` for valid `relationType` terms and their
inverses.

## Constraints

- Run the readiness check first. Without a token, report `result: unminted` — never a placeholder.
- A DOI appears in a report only when Zenodo returned it in a publish response. Never report
  `prereserve_doi` as a minted DOI, and never construct one from a record id.
- Show the exact call and confirm before `actions/publish`, including a republish after an edit.
- Deposit only a tagged, clean state. Never create, move, or delete a tag, and never modify the
  dataset to make a deposit fit.
- Use the sandbox for every test. A production publish is permanent.
- Never echo, log, or commit the token: pass it through a header file, and do not put it in a
  command line, a saved file inside the dataset, or a report.
- On an HTTP error, surface Zenodo's message and stop. Do not retry a publish that may have
  succeeded; read the deposition's state first.
