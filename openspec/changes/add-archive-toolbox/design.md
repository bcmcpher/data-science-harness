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
- **`RelatedIdentifier` lives in the `datacite` skill**, even though OSF and Zenodo also expose
  relation fields, because DataCite's `relationType` vocabulary is what `project.schema.json`'s
  `relation` already references.
- **The e2e assertion tests the gate, not the network.** Asserting `unminted` without credentials is
  cheap and deterministic; the credentialed branch is gated and skipped by default.

## Risks / Trade-offs

- **Splitting a working procedure risks drift** between the doer's steps and the skills' detail. The
  lint's prose-versus-`delegates_to` check does not cover doer-to-toolbox references, so this has to
  be maintained by reading rather than by tooling.
- **A published record cannot be withdrawn.** Any test that exercises the credentialed path against a
  real archive creates a permanent artifact; the assertion must use a sandbox endpoint or stay
  manual.
