---
name: manage-product
description: >
  Group kept comparisons into a named product — a paper, dataset release, or report — recorded in
  the project ledger's products[] registry. Trigger on "make a product", "group these comparisons",
  "start a paper", "which comparisons go in the paper", "add this comparison to the product",
  "manage products", "define a deliverable". This is where a bag of comparison branches becomes one
  or more publishable products (the pivot toward multiple linked outputs).
plane: workflow
stamped: [M, A]
---

# Skill: manage-product

Turn kept comparisons into **products**. A comparison is a `cmp/<slug>` branch; a *product* is a
named deliverable that groups a chosen subset of them (plus their outputs) into something you will
release and cite. This is the first place the harness represents *multiple* distinct outputs from
one project — the ledger's `products[]` is the registry the later `disseminate/*` skills release and
cross-link. You own the grouping judgment, and DataLad is native, so you save the ledger yourself.

> Ledger note: `products[]` is an **upsert registry** (edited in place), unlike the legacy, no
> longer written `log:`. Follow `docs/project-ledger.md`: find a product by `id` and update its
> fields, or add a new entry — never drop or rewrite another product, and move `status` only
> forward. Every write is `datalad save`-d so the grouping is provenanced.

## When to use
- The user wants to bundle comparisons into a paper / dataset release / report, add a comparison to
  an existing product, or see/adjust what products exist.
- Do NOT use to create or run a comparison (`analyze/propose-comparison` / `run-comparison`), to
  release a product with a DOI (`disseminate/dataset-release`), or to cross-link products
  (`disseminate/link-outputs`) — this skill only defines the grouping.

## Steps
1. **Identify the product** — get from the user:
   - `id` — a stable kebab-case slug, unique within `products[]` (e.g. `main-paper`)
   - `kind` — `paper` | `dataset` | `report` | `article` | `agent-bundle` | `other`
   - `title` — a human label
   - which comparisons belong to it (`cmp/<slug>` branches). One comparison may appear in more than
     one product (e.g. a shared figure) — that is allowed; call it out so it is intentional.
2. **Verify the comparisons exist and are complete** — run `git branch --list 'cmp/*'` yourself and
   check `bash plugins/datalad-cli/scripts/dsh-log.sh --legacy` for a `run-comparison` entry on
   each of `<the named branches>`. If a named comparison has no recorded run, warn that the product
   references incomplete work and ask whether to include it anyway or run it first
   (`analyze/run-comparison`).
3. **Upsert the product** in `project.yaml` `products[]` (per `docs/project-ledger.md`): create the
   entry if `id` is new, else update it. Set `kind`, `title`, `status`
   (`planned` → `in-progress` → `released`), `comparisons` (the branch list), and `outputs` (the
   dataset-relative result paths, e.g. `derivatives/cmp-<slug>/`). Leave `dois: []` and
   `relations: []` — those are owned by `disseminate/dataset-release` and `link-outputs`.
4. **Save** — run it yourself:
   ```bash
   datalad save -m "$(printf 'manage-product: <id> groups <branches>\n\nDSH-Op: manage-product\nDSH-Stage: analyze\nDSH-Product: <id>')" project.yaml
   ```
5. **Report** — the product `id`, its comparisons/outputs/status, any incomplete comparisons
   flagged, and the next step (add more comparisons, or `disseminate/dataset-release` to release it,
   then `disseminate/link-outputs` to link it to other products).

## Constraints
- Keep `products[]` ids unique; do not duplicate a comparison within a single product's list.
- Products group and describe comparisons — they never move, rename, or modify the branches or
  their data. This skill edits only the ledger.
- Do not set `dois` or `relations` here; releasing and cross-linking are separate skills.
- `products[]` is upserted in place but never destructively (status moves forward, entries are not
  deleted); never append to `project.yaml` `log`. Keep the ledger schema-valid
  (`schemas/project.schema.json`).
- Run every DataLad operation (branch listing, save) yourself; it is native, not a doer.
