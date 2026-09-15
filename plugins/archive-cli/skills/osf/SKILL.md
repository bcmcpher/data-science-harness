---
name: osf
description: >
  Auto-invoke when the user wants to deposit a tagged DataLad dataset to the Open Science Framework,
  create an OSF project for a dataset, mint an OSF DOI, or check whether OSF is usable. Trigger on
  "deposit to OSF", "publish on OSF", "create an OSF project", "mint an OSF DOI", "OSF sibling for
  this release", or /osf. Do NOT trigger for adding OSF as ordinary storage without a release (use
  datalad-siblings), or for a DOI minted by another archive.
argument-hint: '[check|deposit|mint|lookup] [--version <tag>] [--mode annex|export|exportonly|gitonly]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep
---

# Skill: osf

Deposit an already-tagged DataLad dataset to an OSF project through the `datalad-osf` extension,
then mint the project's DOI through the OSF API. Two steps are irreversible in practice: a DOI
requires the project to be **public**, and a minted DOI cannot be withdrawn.

## Steps

1. **Check readiness** — run the toolbox's offline presence check:
   ```bash
   plugins/archive-cli/scripts/check-readiness.sh osf
   ```
   Exit 1 prints `result: unminted` and what is missing (the extension, a token, or both). Stop and
   report it with the `enable:` hint. Minting in step 7 calls the OSF API directly and needs
   `OSF_TOKEN` specifically; with only `OSF_USERNAME`/`OSF_PASSWORD`, the deposit can proceed but
   the mint reports `unminted` naming `OSF_TOKEN`.

2. **Choose the endpoint** — `OSF_API` defaults to `https://api.osf.io/v2`. The test server is
   `https://api.test.osf.io/v2` with separate accounts; whether `datalad-osf` can target it has not
   been verified, so test the API steps there and the sibling steps only against a disposable
   project. Pass the token through a header file, never on a command line:
   ```bash
   OAUTH="$(mktemp)"; ( umask 077; printf 'Authorization: Bearer %s\n' "$OSF_TOKEN" > "$OAUTH" )
   ```

3. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): step 1 only.
   - **deposit**: steps 4-6, then offer step 7.
   - **mint**: step 7 for a project that already holds the deposit.
   - **lookup**: step 8.

4. **Confirm the version is releasable** — the tag must exist, HEAD must be exactly that tag, and the
   tree must be clean:
   ```bash
   git tag -l "<tag>"
   git describe --tags --exact-match HEAD
   datalad status
   ```
   If not, stop and ask. Never create or move a tag.

5. **Create the OSF sibling** — the sibling mechanics are in
   `plugins/datalad-cli/skills/datalad-siblings/SKILL.md`. Choose the mode with the user:
   - `annex` (default): git-annex keys; the project is a DataLad remote, not a browsable release.
   - `export`: a human-readable file tree plus the annex remote — usually right for a release.
   - `exportonly`: the readable tree without git history.
   - `gitonly`: history only, no file content.
   ```bash
   datalad create-sibling-osf --title "<title>" -s osf --mode export \
     [--description "<description>"] [--category data] [--tag <keyword>]
   ```
   Do not pass `--public` here; visibility is decided at step 7. `--existing skip` reuses a sibling
   of the same name. Report the project URL `create-sibling-osf` prints; the node id is the short id
   at the end of it.

6. **Push the tagged state** — follow `plugins/datalad-cli/skills/datalad-push/SKILL.md`:
   ```bash
   datalad push --to osf --data anything
   ```

7. **Mint the DOI (irreversible)** — OSF mints a DOI only for a public node. Show the user both
   consequences, then ask:
   > "Minting requires project `<node_id>` to be public, and the DOI is permanent. Make it public and
   > mint?"

   Only after confirmation, make the node public (on the OSF project page, or
   `PATCH $OSF_API/nodes/<node_id>/` with `"public": true`), then:
   ```bash
   curl -fsS -X POST -H @"$OAUTH" -H 'Content-Type: application/vnd.api+json' \
        -d '{"data": {"type": "identifiers", "attributes": {"category": "doi"}}}' \
        "$OSF_API/nodes/<node_id>/identifiers/"
   ```
   The DOI is `data.attributes.value` (prefix `10.17605/OSF.IO/`). Answers to handle:
   - **403** — the node is not public. Nothing was minted.
   - **400** "A DOI already exists" — read it with `GET $OSF_API/nodes/<node_id>/identifiers/`
     instead of minting again.
   - **405** "This action is no longer available" — OSF has restricted DOIs to registrations. Report
     this as the reason; a registration is minted through
     `$OSF_API/registrations/<registration_id>/identifiers/` or the OSF web interface, and creating
     one is a separate, permanent step the user must choose.

8. **Lookup** — no token needed. OSF DOIs are DataCite DOIs, so metadata comes from DataCite's
   public API:
   ```bash
   curl -fsS "https://api.datacite.org/dois/<doi>"   # HTTP 404 = not a DataCite DOI
   ```

## Relations

OSF offers no API to write related identifiers onto the DataCite record behind its DOIs. A relation
whose source DOI is an OSF DOI is **ledger-only**; report it that way rather than as a failure.

## Constraints

- Run the readiness check first. Without the extension or a token, report `result: unminted`.
- A DOI appears in a report only when the OSF API returned it. Never construct one from a node id.
- Never make a project public, or mint, without showing the consequence and getting confirmation.
- Deposit only a tagged, clean state. Never create, move, or delete a tag.
- Never echo or commit `OSF_TOKEN` or `OSF_PASSWORD`; pass the token through a header file.
- On an HTTP error, surface OSF's message and stop. Do not retry a mint that may have succeeded;
  list the node's identifiers first.
