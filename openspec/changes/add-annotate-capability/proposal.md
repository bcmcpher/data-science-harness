## Why

`curate/annotate` is the harness's STAMPED Metadata and Actionability step, and it is the planner
that names the most tooling it cannot reach. Its body already refers to a "future annotate doer";
today it declares `delegates_to: [datalad]`, so its only real capability is committing whatever the
assistant wrote by hand. The tools it names — `bagel-cli` (2 mentions across planner bodies),
`pynidm` (2), `reproschema` (4), SNOMED (4), `neurobagel` (5) — have no doer and no toolbox skill
anywhere in the repo.

This is the keystone gap. Controlled-term annotation is what makes a dataset machine-queryable
rather than merely documented, and it is the precondition for the Neurobagel graph push that
`disseminate/publish` describes. It is also the capability whose absence is most likely to produce
plausible-looking but wrong output, because an assistant asked for a SNOMED code with no lookup tool
will produce something that has the shape of one.

## What Changes

- A new `annotate` capability plugin with a doer that owns metadata-enrichment mechanics.
- An `annotate-cli` toolbox following the `datalad-cli` reference shape — one skill per tool, each
  `user-invocable: true` with `allowed-tools` scoped to that tool.
- `curate/annotate` rewired to `delegates_to: [annotate, datalad]`. Its prose already anticipates
  this, so the body needs no rewrite beyond naming the doer concretely.
- An assertion in `tests/e2e-smoke.sh`: a scaffolded dataset gains a validated `participants.json`
  with controlled terms, gated to skip when the tools are absent.

## Capabilities

### New Capabilities
- `annotate`: metadata enrichment — data dictionaries, sidecar completion, and controlled-term
  lookup against Neurobagel, SNOMED, ReproSchema, and NIDM vocabularies.

### Modified Capabilities
- `curate`: `curate/annotate` gains a real delegation target, so controlled-term coverage becomes
  a tool result rather than model recall.

## Impact

- New: `plugins/annotate/`, `plugins/annotate-cli/`
- Modified: `plugins/curate/skills/annotate/SKILL.md`, `.claude-plugin/marketplace.json`,
  `tests/e2e-smoke.sh`
- No change to `project.yaml` schema; annotation writes BIDS metadata files, not ledger keys.
