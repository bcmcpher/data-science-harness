# The Project Ledger (`project.yaml`)

The ledger is the administrative source of truth for a project — a single YAML file at the dataset
root, sibling to `dataset_description.json`, and **`datalad save`-d like any other artifact** so the
administrative record is provenance-tracked alongside the science. Every planner skill reads and
appends to it; a corruption or a rewrite of prior state is a provenance defect, not just an edit.

Validated against [`schemas/project.schema.json`](../schemas/project.schema.json). Validate a file
with `python3 schemas/validate-ledger.py <path/to/project.yaml>` (needs `pyyaml` + `jsonschema`).

## Structure (additive by roadmap phase)

```yaml
project:            # header — set once by project/new-project
  name: xyz-study
  description: "Effect of X on outcome Y in cohort Z"
  created: 2026-07-20T14:30:00Z
  dataset_root: .
  stack: python     # python | R | other

products:           # named deliverables (Phase 2: analyze/manage-product, disseminate/*)
  - id: main-paper
    kind: paper      # paper | dataset | report | article | agent-bundle | other
    title: "X reduces Y"
    status: in-progress   # planned | in-progress | released
    comparisons: [cmp/group-diff-y, cmp/dose-response]   # cmp/* branches / comparison ids
    outputs: [derivatives/cmp-group-diff-y/, figures/fig1.svg]
    dois: []
    relations:       # DataCite RelatedIdentifier links to other products / external DOIs
      - { relation: IsDocumentedBy, target: preprint }

obligations:        # Manage & Comply lane (Phase 3: govern/*)
  - id: prereg-h1
    kind: preregistration   # preregistration | confirmatory-comparison | dmp | ethics | funder-report | other
    description: "H1 frozen before data lock"
    due: 2026-09-01
    status: pending         # pending | met | waived
    ref: https://osf.io/xxxxx

contributors:       # people + CRediT credit (Phase 5: project/people)
  - name: Ada Researcher
    orcid: https://orcid.org/0000-0002-1825-0097
    affiliation_ror: https://ror.org/00xxxx
    roles: [Conceptualization, Formal analysis, Writing – original draft]

log:                # append-only activity log
  - { ts: 2026-07-20T14:30:00Z, op: new-project, stage: initialize,
      note: "scaffolded YODA+BIDS dataset + container recipe", branch: main }
```

## Conventions every planner reuses

These are the only ways a skill mutates the ledger. Follow them exactly, then delegate a
`datalad save` to the **datalad doer** so the change is tracked.

1. **Append to `log:`** — add one `{ ts, op, stage, note, branch? }` entry describing what happened.
   Never rewrite or reorder prior entries; a correction is a *new* entry. `ts` is ISO-8601 UTC;
   `op` is the skill name.

2. **Upsert a `products[]` entry** — find the product by `id` (create the list/entry if absent) and
   set its fields. A product groups the `comparisons` (cmp/* branches) that constitute it, the
   `outputs` it publishes, its `dois`, and its `relations`. Do not duplicate ids.

3. **Add / resolve an `obligations[]` entry** — add `{ id, kind, description, due?, status, ref? }`
   when a commitment is made (e.g. a pre-registration); flip `status` to `met`/`waived` (never
   delete the entry) when it is discharged.

4. **Provenance by default** — every ledger write is followed by a `datalad save` via the datalad
   doer. The ledger is never edited "off to the side".

## Which skills touch which sections

| Section | Written by |
|---|---|
| `project` | `project/new-project` (once) |
| `log` | every planner (append); `project/log-decision` records decisions + rationale |
| `products` | `analyze/manage-product` (create/group), `disseminate/dataset-release` + `link-outputs` (dois/relations) |
| `obligations` | `govern/preregister`, `govern/obligations`; resolved as work completes |
| `contributors` | `project/people` (CRediT roles + ORCID/ROR; mirrored to `dataset_description.json` Authors) |

`project/status-report` reads the whole ledger and renders `PROJECT.md` / funder reports — it never
writes project state, only the append-only `status-report` log entry.

## Evolution

The schema is intentionally strict (`additionalProperties: false`) to catch typos, and grows one
phase at a time. Later phases (govern) will add funding/ethics detail; when they do, extend
`schemas/project.schema.json` in the same commit that introduces the writing skill.
