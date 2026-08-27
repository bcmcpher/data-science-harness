## Why

`archive` is one of three capabilities whose doer is the entire surface — it carries OSF, Zenodo and
DataCite handling inline, in a single agent file. That works, but it makes the shortest path to a
visible end-to-end outcome (a real DOI on a real product) harder to test and harder to extend: each
backend has different credentials, different failure modes, and a different notion of what
"published" means, and all three are currently interleaved in one procedure.

`datacite` is named 7 times across planner bodies and `osf` 10 times, with no skill either can be
pointed at. `disseminate/link-outputs` describes DataCite `RelatedIdentifier` handling in prose that
nothing implements.

This is the shortest phase with a demonstrable result, and it does not depend on anything else.

## What Changes

- An `archive-cli` toolbox with one skill per backend: `osf`, `zenodo`, `datacite`.
- DataCite `RelatedIdentifier` handling promoted out of `disseminate/link-outputs` prose into the
  `datacite` toolbox skill.
- The archive doer slimmed to the operating procedure and its refusal rules, consulting the toolbox
  for per-backend invocation detail — the same relationship `datalad-doer` has with `datalad-cli`.
- An e2e assertion: a DOI mint reports `unminted` without credentials, and succeeds with them.

## Capabilities

### Modified Capabilities
- `archive`: gains a toolbox; the per-backend requirements become testable independently of the doer.
- `disseminate`: `link-outputs` delegates relation handling instead of describing it.

## Impact

- New: `plugins/archive-cli/`
- Modified: `plugins/archive/agents/archive-doer.md`,
  `plugins/disseminate/skills/link-outputs/SKILL.md`, `.claude-plugin/marketplace.json`,
  `tests/e2e-smoke.sh`
- The doer's external contract is unchanged: same structured result, same `unminted` semantics.
