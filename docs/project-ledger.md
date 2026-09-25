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
    submissions:     # submission HISTORY (disseminate/submission-track) — see below
      - { venue: "Journal of X", submitted: 2026-08-04, status: rejected,
          decision: "Reject after review", ref: JX-2026-0412 }
      - { venue: "Reports in Y", submitted: 2026-09-12, status: under-review, ref: RY-2026-1187 }

obligations:        # Manage & Comply lane (Phase 3: govern/*)
  - id: prereg-h1
    kind: preregistration   # preregistration | confirmatory-comparison | dmp | ethics | milestone | funder-report | other
    description: "H1 frozen before data lock"
    due: 2026-09-01
    status: met             # pending | met | waived
    ref: https://osf.io/xxxxx   # the EXTERNAL reference
    resolved_by: a1b2c3d        # internal evidence — REQUIRED when status is `met`

contributors:       # people + CRediT credit (Phase 5: project/people)
  - name: Ada Researcher
    orcid: https://orcid.org/0000-0002-1825-0097
    affiliation_ror: https://ror.org/00xxxx
    roles: [Conceptualization, Formal analysis, Writing – original draft]

log:                # LEGACY — read by dsh-log --legacy; no skill writes it
  - { ts: 2026-07-20T14:30:00Z, op: new-project, stage: initialize,
      note: "scaffolded YODA+BIDS dataset + container recipe", branch: main }
```

`project.yaml` holds **state**: what the project is, what it produces, what it owes, and who did
it. **Activity** — what happened, when, and why — lives in the commit history, one `DSH-*`-bearing
commit per action (see below). Only `project` is required. `log` remains a permitted key so that
ledgers written before activity moved into commits still validate; `dsh-log --legacy` reads it
alongside the commits.

## Conventions every planner reuses

These are the only ways a skill mutates the ledger. Follow them exactly, then run `datalad save`
yourself so the change is tracked.

1. **Record the action in the commit, not the ledger.** The save that carries the change has a
   `<what> — <why>` subject and, after a blank line, `DSH-Op: <skill>` plus any of `DSH-Stage`,
   `DSH-Product: <id>`, `DSH-Obligation: <id> opened|resolved` and `DSH-Binding:
   <doer>/<tool>@<version>`, all in **one** `-m` (DataLad keeps only the last of several):

   ```bash
   datalad save -m "$(printf 'register cmp-01 — confirmatory test frozen\n\nDSH-Op: preregister\nDSH-Stage: govern\nDSH-Obligation: prereg-cmp-01 opened')" project.yaml
   ```

   History is immutable, so a correction is a *new* commit. Read the history with
   `plugins/datalad-cli/scripts/dsh-log.sh` (`--legacy` adds pre-change `log:` entries). Never
   append to `log:`.

2. **Upsert a `products[]` entry** — find the product by `id` (create the list/entry if absent) and
   set its fields. A product groups the `comparisons` (cmp/* branches) that constitute it, the
   `outputs` it publishes, its `dois`, and its `relations`. Do not duplicate ids.

3. **Add / resolve an `obligations[]` entry** — add
   `{ id, kind, description, due?, status, ref?, resolved_by? }` when a commitment is made (e.g. a
   pre-registration); flip `status` to `met`/`waived` (never delete the entry) when it is discharged.

   **Resolving means naming the evidence.** An obligation at `status: met` MUST carry `resolved_by`:
   a commit SHA (preferred, and the only form new skills write), a legacy `log:` entry timestamp,
   or a product id. The commit that sets `met` carries `DSH-Obligation: <id> resolved`. The schema
   enforces `resolved_by`, so a status flip cannot stand in for a record of what actually happened.

   `ref` and `resolved_by` are deliberately different fields. `ref` is the **external** reference —
   a registration id, an IRB protocol number, a funder award URL. `resolved_by` is **internal**
   evidence, checkable against the dataset in hand. Whoever audits the claim later needs to know
   which of the two they are reading: an external URL can rot, a commit SHA cannot.

   A deadline is an obligation with `kind: milestone`, not a separate registry — a milestone is a
   commitment with a date, and `govern/obligations` surfaces it alongside every other one.

4. **Append to a product's `submissions[]`** — a submission is a **history, not a state**. Append an
   entry per submission; never overwrite the previous one, and never fold submission state into the
   product's own `status`. A paper under review and a paper whose submission was rejected are both
   still `in-progress`, and a resubmission must leave the first venue's outcome readable.

   `venue` is required — a submission with no destination is not a submission. `status` is one of
   `preparing`, `submitted`, `under-review`, `revision-requested`, `accepted`, `rejected`,
   `withdrawn`; `decision` is free text, because editors do not use a closed vocabulary.

5. **Ethics protocol detail is an obligation plus commits**, not a structured block. An IRB or
   IACUC record is an `obligations[]` entry with `kind: ethics`, the expiry in `due`, and the
   protocol number or URL in `ref`. The approval date and every amendment are stated in the
   `DSH-Op: ethics-track` commit that records them, where immutable history already provides an
   amendment trail. `govern/ethics-track` reads and writes exactly that shape.

6. **Provenance by default** — every ledger write is followed by a `datalad save` in the same
   step. The ledger is never edited "off to the side".

## Which skills touch which sections

| Section | Written by |
|---|---|
| `project` | `project/new-project` (once) |
| `log` | legacy — no skill writes it. Activity is in commit `DSH-*` lines; `project/log-decision` writes `docs/decisions/<date>-<slug>.md` |
| `products` | `analyze/manage-product` (create/group), `disseminate/dataset-release` + `link-outputs` (dois/relations), `disseminate/submission-track` (submissions) |
| `obligations` | `govern/preregister`, `govern/obligations`, `govern/dmp`, `govern/ethics-track`, `project/track-milestone`; resolved as work completes |
| `contributors` | `project/people` (CRediT roles + ORCID/ROR; mirrored to `dataset_description.json` Authors) |

`project/status-report` reads the whole ledger and `dsh-log --legacy` and renders a report. It
is read-only: it writes nothing unless asked to keep a copy, in which case it saves
`reports/status-<date>.md`.

## Evolution

The schema is intentionally strict (`additionalProperties: false`) to catch typos, and grows one
phase at a time. For a single new skill, extend `schemas/project.schema.json` in the same commit
that introduces the writing skill.

That rule inverts when several skills land at once. `extend-ledger-for-planned-skills` grew
`milestone`, `resolved_by` and `submissions[]` in one pass, ahead of the five changes that write
them, because five concurrent edits to one closed schema would each design their own corner of it
and discover the conflicts at merge time. `openspec/README.md` states the governing convention:
**ledger-first — formalize the schema before the skills that write to it.**
