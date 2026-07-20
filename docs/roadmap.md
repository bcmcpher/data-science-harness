# Roadmap — filling the workflow gaps (beginning → multiple products)

> **Temporary document.** This roadmap tracks the build-out from the current single-track
> provenance spine to a full multi-product research harness. **Delete this file once every phase
> below is checked off** — it is scaffolding, not permanent documentation. Per-feature docs live
> with their plugins.

## Where we started (v1 slice)
A working single-track provenance spine: `new-project` → `curate/annotate` → `process/run-pipeline`
→ `analyze/{propose,run,checkpoint}` → `disseminate/publish`, over the `datalad`/`nipoppy` doers,
packaged as a 9-plugin marketplace. Gaps cluster at the two ends: the governance/ledger **front**
and, critically, the **product layer** (no concept of a "product", so no way to release or link
*multiple* products).

## Guiding principles
- **Ledger-first** — formalize `project.yaml` before the skills that write to it.
- **Additive, not breaking** — keep the existing `project:` header + append-only `log:`; add new
  optional top-level keys (`products:`, `obligations:`).
- **Two-plane discipline** — new tool mechanics → a capability doer; new research process → a
  workflow planner that delegates. Planners never call a CLI.
- **Verify each phase** by extending `tests/e2e-smoke.sh` with real assertions.

---

## Phase 1 — Foundation: the ledger + products model *(keystone)*  ✅ DONE
- [x] `schemas/project.schema.json` — validates the ledger (`project`, `products[]`,
      `obligations[]`, `log[]`); strict (`additionalProperties: false`) to catch typos.
- [x] `schemas/validate-ledger.py` — reusable validator (exit 0/1/2-skip; keeps ISO timestamps
      as strings).
- [x] `docs/project-ledger.md` — the ledger conventions all planners reuse (append to `log:`,
      upsert `products[]`, add `obligations[]`).
- [x] `plugins/project/skills/new-project/SKILL.md` — scaffolds the fuller (additive) skeleton;
      references the schema + conventions.
- [x] `examples/project.yaml` — illustrates `products:` / `obligations:`.
- [x] `tests/e2e-smoke.sh` — gated assertions validating scaffolded + example ledgers, and that
      the ledger stays valid after log appends. (25 passed, 0 failed.)

## Phase 2 — Product layer: publish *multiple* products *(critical path)*  ⏳ IN PROGRESS
- [x] `analyze/manage-product` — group comparison branches into a named product; write `products[]`.
      (e2e: upserts a product, re-validates the ledger, asserts the tracked save — 29 passed.)
- [ ] archive/DOI capability doer — Zenodo/OSF DOI minting (`datalad-osf` / Zenodo API).
- [ ] `disseminate/dataset-release` — version bump, BIDS `CHANGES`, `datalad` tag, mint DOI.
- [ ] `disseminate/link-outputs` — DataCite `RelatedIdentifier` cross-linking across products.
- [ ] `e2e-smoke.sh` — two products from two branches, released + linked, asserted.

## Phase 3 — Front-end completeness (parallelizable after Phase 1)
- [ ] `govern/preregister` + `govern/obligations` — freeze specs, record confirmatory obligations
      (wires `propose-comparison`'s pre-registered mode).
- [ ] `curate/raw-to-bids` — drive `nipoppy bidsify` through `datalad run` (reuses existing doers).
- [ ] `bids` capability doer + QC skill — `bids-validator`, data-quality, `stamped-assess`.

## Phase 4 — Living products
- [ ] `disseminate/draft-manuscript` (IMRaD, auto-filled from `datalad log` + ledger)
- [ ] `disseminate/reporting-checklist` (EQUATOR / COBIDAS)
- [ ] `disseminate/executable-article` (NeuroLibre)
- [ ] `disseminate/agent-bundle` (Paper2Agent MCP server)
- [ ] `disseminate/liab-deploy` (Lab-in-a-Box)

## Phase 5 — Manage & Comply lane + capability fill
- [ ] `project/status-report`, `project/people` (CRediT/ORCID), `project/log-decision`
- [ ] `containers` capability — build + `containers-add` a `.sif` into the dataset.

---

## Dependency / critical path
```
Phase 1 (ledger+products)  ──►  Phase 2 (manage-product ─► dataset-release+DOI ─► link-outputs)
                                 └─► unblocks Phase 4 (living products) + Phase 5 (mgmt lane)
Phase 3 (govern/curate/bids) proceeds in parallel after Phase 1.
```
Everything routes through Phase 1. Phase 2 is the shortest path to the multi-product goal.

## Definition of done (delete this file when true)
All phase checkboxes above are checked, and each shipped capability has an assertion in
`tests/e2e-smoke.sh` (or a gated skip when its tool/credential is absent).
