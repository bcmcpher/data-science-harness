## Context

`plugins/archive/agents/archive-doer.md` already has a backend table and a five-step procedure. The
procedure is sound and stays; what moves out is the per-backend detail — which endpoint, which
credential, which response field carries the identifier — so each backend can be described, read,
and tested on its own.

`tests/e2e-smoke.sh` already exercises `dataset-release` and `link-outputs` against the ledger; it
does not exercise minting, because minting needs credentials the test cannot assume.

## Goals / Non-Goals

**Goals:**
- One skill per backend, each independently readable and independently invocable.
- A real `RelatedIdentifier` implementation rather than prose in a planner body.
- An e2e assertion that covers both branches of the credential gate.

**Non-Goals:**
- Changing when or what the harness deposits — that stays with `disseminate/dataset-release`.
- Supporting additional archives. Three backends are already named in planner bodies; adding a
  fourth is a separate change.
- Automating credential provisioning.

## Decisions

- **The `unminted` contract is load-bearing and does not move.** It stays in the doer, not the
  toolbox, because it is a policy about the harness's honesty rather than a property of any backend.
- **Confirmation before irreversible publish stays in the doer** for the same reason.
- **The standalone skills carry the same two safeguards.** A user who invokes a backend skill
  directly bypasses the doer, so each skill also shows the publishing call, confirms before any
  irreversible step, and reports only identifiers the backend returned. The doer's rules stay
  authoritative when a planner delegates.
- **Relations are written to the archive that owns the source DOI** (decided 2026-09-15). DataCite's
  API accepts updates only for DOIs under the caller's own prefix, and most users' DOIs are minted
  by Zenodo or OSF under those platforms' prefixes. So the `datacite` skill writes own-prefix DOIs,
  the `zenodo` skill writes `related_identifiers` on a Zenodo record, and any other owner answers
  `ledger-only`. `relationType` values stay DataCite's, which is what `project.schema.json`'s
  `relation` already references. Lookup goes through DataCite's public REST API for all three,
  because Zenodo and OSF DOIs are DataCite DOIs.
- **An unresolvable external target is recorded and flagged** (decided 2026-09-15). Refusing it
  would block linking offline, where resolution fails for reasons unrelated to the identifier. The
  ledger's `relation` object has `additionalProperties: false`, so the flag goes in the log entry's
  note and the report rather than a new schema field.
- **The e2e assertion tests the gate, not the network, through a script** (decided 2026-09-15).
  `tests/e2e-smoke.sh` runs the commands a doer would run and cannot observe an agent, so readiness
  lives in `plugins/archive-cli/scripts/check-readiness.sh`, which the skills, the doer, and the test
  all call. It checks presence only and never contacts the network. The credentialed branch runs
  only when `DSH_ZENODO_SANDBOX_TOKEN` is set, against the Zenodo sandbox.

## Risks / Trade-offs

- **Splitting a working procedure risks drift** between the doer's steps and the skills' detail. The
  lint's prose-versus-`delegates_to` check does not cover doer-to-toolbox references, so this has to
  be maintained by reading rather than by tooling.
- **A published record cannot be withdrawn.** Any test that exercises the credentialed path against a
  real archive creates a permanent artifact; the assertion must use a sandbox endpoint or stay
  manual.

Verified against the live APIs on 2026-09-15:

- **Zenodo's deposit API is a legacy layer.** `/api/deposit/depositions` still works on Zenodo's
  InvenioRDM backend and is still documented, but it was announced for deprecation. The `zenodo`
  skill names the native `/api/records` equivalent, so a migration is a skill edit rather than a doer
  change.
- **Remote relation writes replace rather than append.** DataCite's `PUT /dois/{doi}` replaces
  `relatedIdentifiers` wholesale and creates the DOI if it does not exist, and Zenodo's edit flow
  republishes the record. Both skills read, merge, then write, and confirm before the republish.
- **OSF DOI minting needs a public node** and may be restricted to registrations, which answer HTTP
  405 "no longer available" for a plain project. The `osf` skill reports that reason and points at
  registrations rather than retrying.
- **Sandbox DOIs do not resolve.** The Zenodo sandbox issues `10.5072` test-prefix DOIs that neither
  doi.org nor `api.datacite.org` knows, so the credentialed e2e branch asserts the prefix, and lookup
  of a test DOI goes to `api.test.datacite.org`.
- **A stored OSF credential is invisible to an offline check.** `check-readiness.sh` sees `OSF_TOKEN`
  or `OSF_USERNAME`/`OSF_PASSWORD` in the environment, not a credential saved with
  `datalad osf-credentials`, so it can report `unminted` for a user who could in fact deposit. That
  errs toward refusal, which is the safe direction.
