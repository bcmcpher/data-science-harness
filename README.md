# data-science-harness

A community-driven, harness-agnostic collection of AI assistant configurations for academic data science work — skills, agents, commands, hooks, MCP configs, and planning templates that work across Claude Code, Cursor, GitHub Copilot, Windsurf, OpenCode, and Gemini CLI.

---

## What this is

Most AI coding assistant configurations are designed for software products: ship a package, cut a release, deploy a service. Academic data science has a different end goal — **publish a research product**. But a research product is no longer just a static PDF or a frozen dataset. This project treats it as a **living research compendium**:

1. a **provenanced dataset** (versioned, citable, DOI-tagged), plus
2. a **re-executable article** that regenerates its own figures and results (NeuroLibre-style), plus
3. an **agent-callable method bundle** that exposes the work's methods as tools a future researcher's AI assistant can invoke on new data (Paper2Agent-style), plus
4. a **self-hostable deployment** of the dataset and its services on data-sovereign infrastructure (Lab-in-a-Box-style),

all built from a **single DataLad provenance chain** and cross-linked by DOI. The goal is research that the next person — or the next agent — can *build upon* rapidly, not just read.

This project generalizes the best patterns from software development tooling for academic research workflows, with four priorities:

1. **STAMPED by default** — every research object is built toward the [STAMPED principles](docs/stamped.md) (Self-containment, Tracking, Actionability, Modularity, Portability, Ephemerality, Distributability). Tracking runs through DataLad, so the full chain from raw data to published result — *and every administrative change* — is recorded automatically.
2. **External standards as first-class citizens** — STAMPED, BIDS, Neurobagel, SNOMED, OSF, Zenodo, NeuroLibre, Lab-in-a-Box, ORCID, CRediT, and reporting guidelines are integrated into the normal workflow, not bolted on at the end
3. **Research products are living** — the default export re-executes (NeuroLibre), is agent-callable (Paper2Agent / MCP), and is self-hostable (Lab-in-a-Box), not a one-off artifact
4. **Administration is first-class, not an afterthought** — funding, ethics, data-management plans, deadlines, people, and credit are tracked alongside the science, with the same provenance discipline

**Two planes of configuration.** The content separates cleanly into a **capability plane** (thin wrappers over the technical tools — DataLad, Nipoppy, BIDS, containers, publishing, annotation) and a **workflow plane** (tool-agnostic research process that *orchestrates* those capabilities). This separation is STAMPED **Modularity** applied to the harness itself — and it is what makes the pieces recombine cleanly (see [Architecture](#architecture)).

**Target harnesses**: Claude Code, Cursor, GitHub Copilot, Windsurf, OpenCode, Gemini CLI

**Target workflows**: data analysis, experiment design, literature review, reproducibility, **project governance & compliance**, **administrative tracking & reporting**, **dissemination & living publications**, long-term planning

---

## Research Lifecycle Model

The lifecycle is **a linear scientific pipeline (stages 0–8) running inside a persistent administrative track**. DataLad is the connective tissue — every computation goes through `datalad run` / `datalad container-run`, and every administrative change is `datalad save`-d, so neither the analysis chain nor the administrative record is ever broken. Each stage is driven by a **workflow plugin** that calls down into one or more **capability plugins** (shown in parentheses).

| Stage | What happens | Workflow plugin (→ capabilities) |
|-------|-------------|----------------------------------|
| **0. Propose & Govern** | Funding metadata, Data Management Plan, IRB/ethics, *(optional)* pre-registration, project-ledger init | `govern` |
| **1. Initialize** | YODA dataset + BIDS layout scaffolded; environment/container; *(optional)* self-hosted lab infra | `project` (→ `datalad`, `bids`, `containers`) |
| **2. Curate** | Raw → BIDS conversion (optionally via Nipoppy); annotate variables with Neurobagel / SNOMED | `curate` (→ `nipoppy`, `bids`, `annotate`) |
| **3. Analyze** | Run comparisons and preprocessing pipelines via `datalad run` / `datalad container-run` | `analyze` (→ `datalad`, `nipoppy`) |
| **4. Checkpoint** | `datalad save` with structured commit; auto-hook on session end | `analyze`, `project` (→ `datalad`) |
| **5. QC / Review** | BIDS validator; data quality checks; STAMPED / reproducibility audit | `govern` (stamped-assess), `curate` (→ `bids`), `analyze` |
| **6. Export** | Bundle outputs; push dataset version to OSF / Zenodo | `disseminate` (→ `publish`) |
| **7. Publish** | Update `dataset_description.json`; mint DOI; push Neurobagel graph | `disseminate` (→ `publish`, `datalad`), `curate` (→ `annotate`) |
| **8. Disseminate & Report** | Manuscript **+ living compendium** (executable article + agent bundle + Lab-in-a-Box); reporting-guideline compliance; DOI cross-linking; progress/final reports | `disseminate`, `project` |

```
   ┌─────────────────────────────────────────────────────────────────────────┐
   │  Manage & Comply lane  (cross-cutting, runs across ALL stages)            │
   │  project ledger · obligations & deadlines · decision log · people/credit  │
   │  · status & funder reports · compliance audits                            │
   └─────────────────────────────────────────────────────────────────────────┘
        ▲          ▲          ▲          ▲          ▲          ▲          ▲
   ┌────┴───┐ ┌────┴───┐ ┌────┴───┐ ┌────┴───┐ ┌────┴───┐ ┌────┴───┐ ┌────┴───┐
   │ 0 Gov  │→│ 1 Init │→│2 Curate│→│3 Analyze│→│ 4-5 QC │→│6-7 Pub │→│ 8 Disse│
   │        │ │        │ │        │ │ +4 Chk │ │        │ │ +DOI   │ │ minate │
   └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

The **Manage & Comply lane** is the key conceptual addition: administration is not a single stage, it is a continuous track the whole pipeline runs inside. It is served by the tracking skills in the `project` workflow plugin and the compliance skills in `govern`, and it is backed by a single versioned [Project Ledger](#the-project-ledger-projectyaml).

---

## Analyses as Modular Products

The stage diagram above is a *typical order*, not a rigid pipeline. Real papers are a series of small **comparisons** that tell a story, usually with supplementary figures, and rarely developed in a perfectly linear order unless strictly pre-registered. New questions arrive mid-project — a reviewer's challenge, a conflicting result, a follow-up worth checking.

So rather than a fixed, up-front "analysis plan" stage, the harness treats **an analysis as a lightweight, addable unit — a comparison** — that can be introduced at *any* point and grouped into a **product** (a paper, a dataset release, a report). A comparison is one small record:

```
comparison: { id, what, why, inputs, expected_outputs,
              rigor: exploratory | confirmatory, status, product?, prereg_id?, branch }
```

realized as a **DataLad branch + `datalad run`** off the shared dataset, and groupable into a product. The same record spans a **rigor spectrum** with two anchoring modes:

- **Quick query / plot (left end).** Spec is created and executed immediately — "show me X vs Y in this cohort." It lives **only as a DataLad branch/run and has zero ledger footprint** (STAMPED *Ephemerality*): explore freely, keep it only if it tells the story. It touches `project.yaml` for the first time *only if promoted* into a product. The bar to add one is a one-liner — less is more.
- **Pre-registered comparison (right end).** The spec is **frozen and registered *before* execution** (`govern/preregister` → OSF Registrations / ClinicalTrials.gov / PROSPERO), and recorded in the ledger as an **outstanding obligation** ("a comparison that must be completed") in the Manage & Comply lane. It is executed later via `analyze/run-comparison`, and the result is checked against the registered spec — any deviation is reportable.

Both are the *same schema* on one spectrum; the confirmatory mode simply adds (1) freeze-the-spec-first and (2) a ledger obligation. This is exactly the STAMPED [specification-centric research object](docs/stamped.md) view: the durable object is the spec (Self-contained, Tracked, Actionable, Distributable), while the run is Ephemeral. A collection of pre-registered comparisons is therefore just a to-do list of confirmatory obligations; a bag of quick queries is a set of branches you prune down to the ones worth publishing.

- **Reuse over time.** Because kept comparisons are annotated and provenanced, one from an earlier project can be picked up, re-run, and extended later — flexibility for new explorations is preserved without re-architecting the project.

The `analyze/propose-comparison` skill picks the rigor mode; `analyze/manage-product` groups the kept results; the "comparisons still to complete" view is simply the confirmatory obligations in the ledger.

---

## Architecture

The design uses **two orthogonal axes**. Understand them separately.

### Axis 1 — Content organization: two planes

| Plane | What lives here | Rule |
|-------|-----------------|------|
| **Capability** (technical) | Thin, tool-scoped wrappers over one external tool each (DataLad, Nipoppy, BIDS, containers, publishing, annotation). Mechanical, reusable STAMPED primitives. | A capability skill wraps a tool; it holds no research-process logic. |
| **Workflow** (conceptual) | Tool-agnostic research process, written in research vocabulary (govern, initialize, curate, analyze, disseminate). | A workflow skill **never calls a CLI directly** — it invokes capability skills. |

This split *is* STAMPED **Modularity** (separation of concerns) + **Actionability** (the workflow is the executable spec that invokes actionable tool primitives). It is what the user's "keep the technical tools separate from the conceptual workflows" requirement buys: capabilities recombine under different workflows, and a workflow can swap one capability for another (e.g. Zenodo for OSF) without rewriting the process.

### Axis 2 — Distribution/format: three layers

Each layer is independently useful:

| Layer | Format | Who needs it |
|-------|--------|-------------|
| **1. Content** (source of truth) | Universal SKILL.md + `plugin.yaml` | Everyone — contributors only write Markdown |
| **2. Installer** (convenience) | Python CLI (`ds-harness`) | Users who want automated multi-harness install |
| **3. Manual fallback** | `bin/install.sh` + per-harness docs | Users in locked-down environments |

The content layer is plain Markdown + YAML. The Python package is just an installer/translator — you can clone the repo and manually copy files to any harness without it.

### Why Python over Node

The target community (academic data scientists) already uses `pip`/`uv`. The format itself has zero Python dependency — Python is only needed to run the CLI installer.

---

## Universal Skill Format

All skills are authored once in a **universal SKILL.md** with a superset YAML frontmatter. The installer translates this into harness-specific output at install time — no duplication per harness. Capability and workflow skills share the format; they differ only in the `plane` field and (for capabilities) a `stamped:` tag.

```yaml
---
name: plan-analysis
description: >
  Guide statistical test selection for research datasets with QC checks.
  Triggers when user asks to "plan analysis", "choose a statistical test",
  or "what test should I use for this dataset".
plane: workflow            # workflow | capability
when:
  always: false
  globs: ["*.R", "*.py", "*.ipynb"]
category: analyze
tools: [Read, Grep, Bash]
version: "0.1.0"
harnesses: [all]
---
```

A capability skill additionally declares the STAMPED letters it serves:

```yaml
---
name: datalad-run
plane: capability
stamped: [T, A]            # this primitive advances Tracking + Actionability
category: datalad
...
---
```

**Harness translation map:**

| Universal field | Claude Code | Cursor (.mdc) | Copilot (.instructions.md) | Windsurf |
|-----------------|-------------|---------------|---------------------------|----------|
| `name` | `name:` | frontmatter `description:` | frontmatter | filename |
| `description` | `description:` | `description:` | filename | filename |
| `when.globs` | (auto-load in project) | `globs:` | `applyTo:` | `triggers:` |
| `when.always` | (user-invocable) | `alwaysApply:` | always-loaded | global rules |
| `tools` | `allowed-tools:` | (ignored) | (ignored) | (ignored) |
| `plane`, `stamped` | (metadata, validated) | (metadata) | (metadata) | (metadata) |

---

## Plugins

Eleven plugins, split across the two planes. Six **capability** plugins wrap the technical tools; five **workflow** plugins encode the research process and call down into the capabilities.

### Capability plugins (technical plane)

| Plugin | Wraps | Core skills (v1) | STAMPED | Distilled from |
|--------|-------|------------------|---------|----------------|
| `datalad` | DataLad / git-annex | `datalad-run`, `datalad-container-run`, `datalad-save`, `datalad-status`, `datalad-clone`, `datalad-get`, `datalad-push`, `datalad-log`, `checkpoint` | T, S, M | seed `datalad-cli` (19 → core) |
| `nipoppy` | Nipoppy | `nipoppy-setup`, `nipoppy-bidsify`, `nipoppy-process`, `nipoppy-track` | S, T, M, A | seed `nipoppy-cli` |
| `bids` | bids-validator | `bids-validate`, `bids-scaffold` | S, M | my-skills `bids` |
| `containers` | Apptainer / Docker | `build-container`, `run-container` | P, E | new |
| `publish` | osfclient / zenodraft / git-annex special remotes | `osf-push`, `zenodo-deposit`, `annex-remote` | D | new |
| `annotate` | bagel-cli / pynidm / reproschema / SNOMED API | `neurobagel-annotate`, `snomed-lookup`, `nidm-annotate`, `reproschema-annotate` | T | new |

Capability plugins are deliberately thin: they hold tool mechanics and the STAMPED primitives, nothing about *why* or *when* you run them. The verbatim seed `datalad-cli` (19 skills) and `nipoppy-cli` are treated as **reference material** and distilled into the trimmed cores above; rarely-used skills (e.g. `datalad-addurls`, `datalad-fsck`) move to an optional "extended" set rather than v1.

**Nipoppy as a cross-stage capability.** If a project adopts [Nipoppy](https://nipoppy.readthedocs.io) as its dataset-management framework, it is more than a one-shot BIDS converter: it provides a standard CLI and config files (`global_config.json`, a manifest) that span **Initialize → Curate → Analyze → QC** — organizing the dataset, converting raw → BIDS, running preprocessing pipelines (fMRIPrep, QSIPrep, …) through containers, and tracking processing status. A project that declares its expected preprocessing pipelines at setup (see `project/new-project`) wires them into the Nipoppy config so each runs through the `datalad` capability's `container-run` with provenance intact.

### Workflow plugins (conceptual plane)

| Plugin | Lifecycle stages | Skills (orchestrate capabilities) |
|--------|------------------|-----------------------------------|
| `govern` | 0 + Manage & Comply lane | `init-ledger`, `dmp`, `ethics-track`, `preregister`, `obligations`, `stamped-assess` |
| `project` | 1, 8 + Manage & Comply lane | `new-project`, `env-check`, `claude-config`, `log-decision`, `track-milestone`, `people`, `status-report` |
| `curate` | 2, 5, 7 | `raw-to-bids`, `merge-data`, `gen-data-dict`, `annotate-variables` |
| `analyze` | 3–5 | `plan-analysis`, `propose-comparison`, `run-comparison`, `gen-report`, `manage-product`, `literature-search` |
| `disseminate` | 6, 7, 8 | `draft-manuscript`, `reporting-checklist`, `submission-track`, `dataset-release`, `executable-article`, `agent-bundle`, `liab-deploy`, `link-outputs` |

**`govern`** — Stand up and maintain the administrative + compliance backbone (stage 0 and the Manage & Comply lane).
- `init-ledger` — scaffold `project.yaml` (called by / extends `project/new-project`)
- `dmp` — author/update a Data Management Plan against the RDA DMP Common Standard (maDMP) or a funder template; record obligations into the ledger
- `ethics-track` — record IRB/IACUC protocol, approval, expiry, and amendments; flag upcoming renewals
- `preregister` — register the study (OSF Registrations / ClinicalTrials.gov / PROSPERO); record the registration ID into the ledger; used to freeze a **confirmatory comparison**'s spec
- `stamped-assess` — score a research object against the [STAMPED checklist](docs/stamped.md) (the paper's LinkML schema); **subsumes the earlier compliance-audit + reproducibility-audit** into one graded readout of Self-containment / Tracking / … coverage, including ledger obligations, de-identification, DUA data-scope, and pre-registration adherence
- References: `references/stamped.md`, `references/madmp-schema.md`, `references/hipaa-deid.md`, `references/clinicaltrials-fields.md`

**`project`** — Scaffold a new research project **and** run the ongoing Manage & Comply lane.
- `new-project` — YODA-structured DataLad dataset (via `datalad`), BIDS layout (via `bids`), a basic scientific-Python container (via `containers`), a declared list of expected preprocessing pipelines wired into the Nipoppy config, CLAUDE.md, the project ledger — **and, optionally, self-hosted Lab-in-a-Box infrastructure** (Forgejo git host, HedgeDoc notes, dumpthings metadata) so the project lives on data-sovereign infra from day one
- `env-check` — verify the executable dependencies declared in each plugin's `requires:` are present
- `claude-config` — generate CLAUDE.md, settings, MCP stubs
- `log-decision` — append to a decision / lab-notebook log, then `datalad save`
- `track-milestone` — add/update milestones & deadlines in the ledger
- `status-report` — generate a progress / funder-RPPR-style summary from the ledger + `datalad log` + git history
- `people` — manage collaborators / ORCID / CRediT contributor roles in the ledger
- `obligations` shares the harness-agnostic reminder core with `govern`. Hook: `obligations-due.sh` (Claude Code `SessionStart`) surfaces obligations due within N days; degrades to the on-demand `obligations` skill on harnesses without hooks. Mirrors the `datalad` checkpoint-hook mechanism.

**`curate`** — Get raw data into a standardized, annotated form (calls `nipoppy`, `bids`, `annotate`).
- `raw-to-bids` — convert raw acquisitions into BIDS (via `nipoppy/nipoppy-bidsify` or `bids/bids-scaffold`), then validate (via `bids/bids-validate`)
- `merge-data` — combine tabular phenotypic/clinical sources (Agent: `merge-agent`)
- `gen-data-dict` — generate a data dictionary
- `annotate-variables` — decide *which* variables to standardize and drive `annotate`'s tool skills (Neurobagel, SNOMED, NIDM, ReproSchema)

**`analyze`** — The comparison/product engine (calls `datalad`, `nipoppy`).
- `plan-analysis` — guided statistical-test selection with QC checks
- `propose-comparison` — create a comparison record; pick the rigor mode (quick query vs pre-registered)
- `run-comparison` — execute a comparison via `datalad/datalad-run` on its own branch; check confirmatory results against the registered spec
- `gen-report` — scaffold an analysis report (results tables, QC metrics)
- `manage-product` — group kept comparisons into a product
- `literature-search` — *(scope deliberately thin; pending participant feedback)* a lightweight BibTeX-collection helper (PubMed / Semantic Scholar), **not** a synthesis engine; the clearer value is connecting to meta-analytic tooling (NeuroSynth Compose / NiMARE)

**`disseminate`** — Turn the finished, provenanced work into publications and living products (calls `publish`, `datalad`).

*Classic outputs:*
- `draft-manuscript` — IMRaD scaffold; auto-fill Methods / Data-availability / provenance from `datalad log` + the ledger
- `reporting-checklist` — apply the right EQUATOR guideline (CONSORT / STROBE / PRISMA / ARRIVE) or, with the neuro pack, COBIDAS
- `submission-track` — track target journal, submission, revisions, reviewer responses in the ledger
- `dataset-release` — bump `dataset_description.json`, write a BIDS `CHANGES` entry, `datalad` git tag, optional Zenodo DOI (via `publish`)

*Living research compendium:*
- `executable-article` — scaffold a **NeuroLibre-style reproducible preprint**: MyST `myst.yml` + Jupyter Book content, a `binder/` environment from the DataLad container digest, and a `repo2data` file pointing at the OSF/DataLad-published dataset; wire figures to regenerate from the provenanced pipeline
- `agent-bundle` — **Paper2Agent-style**: synthesize an MCP server + parameterized tools from the project's scripts + data dictionary, emitted as the harness's *own* universal `SKILL.md` + `plugin.yaml` + MCP config, with result-reproduction tests. This dogfoods the project's own content format
- `liab-deploy` — **Lab-in-a-Box-style**: scaffold a `liab-deployments` (pyinfra) config that stands up self-hosted Forgejo + git-annex data serving and publishes the provenanced DataLad dataset via git-annex remotes — a **data-sovereign distribution channel** alongside the cloud-hosted article and agent bundle
- `link-outputs` — cross-link dataset / code / paper / preprint / pre-registration / executable-article / agent-bundle / Lab-in-a-Box DOIs & URLs using DataCite `RelatedIdentifier` relation types; write back to the ledger `products:` and `dataset_description.json`
- References: `references/equator-guidelines.md`, `references/datacite-relations.md`, `references/cobidas.md` (neuro), `references/neurolibre-structure.md`, `references/paper2agent-bundle.md`, `references/liab-deployments.md`

---

## The Project Ledger (`project.yaml`)

The administrative source of truth is a single machine-actionable file at the dataset root, sibling to `dataset_description.json`, and **`datalad save`-d like any other artifact** — so administrative metadata gets *provenance by default* too: every IRB amendment, DMP revision, milestone change, confirmatory-comparison obligation, or new DOI is a tracked commit. Every workflow skill reads/writes it; it auto-fills reports, drives the obligations/reminder surface, and powers STAMPED assessment. A human-readable `PROJECT.md` is generated *from* it on demand and never hand-edited.

```yaml
# project.yaml — administrative ledger (validated against schemas/project.schema.json)
study:
  title: "Effect of X on Y in cohort Z"
  short_name: xyz-study
  affiliation_ror: https://ror.org/00xxxx
  start: 2026-01-15
  end: 2028-01-14

funding:
  - funder_id: https://doi.org/10.13039/100000002   # Crossref Funder Registry (NIH)
    award_number: R01-XX000000
    period: { start: 2026-01-15, end: 2028-01-14 }
    reporting:
      - { type: RPPR, due: 2026-12-01, status: pending }

ethics:
  - body: IRB
    protocol_id: "2025-12345"
    approved: 2025-11-01
    expires: 2026-11-01          # → drives a renewal obligation
    status: approved
    amendments: []

agreements:                       # DUAs / MTAs
  - { type: DUA, party: "Site B", signed: 2026-01-10, expires: 2028-01-10, data_scope: "de-identified imaging" }

dmp:
  standard: RDA-maDMP
  location: docs/dmp.md
  version: "1.2"
  obligations:
    - { req: "Deposit data within 6 months of collection", due: 2026-09-01, status: pending }

registration:
  - { platform: OSF, id: ab12c, url: https://osf.io/ab12c, type: prereg }

people:
  - { name: "B. McPherson", orcid: 0000-0000-0000-0000, roles: [Conceptualization, Software], affiliation_ror: https://ror.org/00xxxx }

milestones:
  - { name: "Data collection complete", due: 2026-06-30, status: in_progress, deliverable: "raw BIDS dataset" }

comparisons:                      # ONLY confirmatory (pre-registered) or promoted comparisons
  - { id: cmp-primary-01, what: "group diff in outcome Y", rigor: confirmatory,
      prereg_id: ab12c, status: registered, product: paper-main, branch: cmp/primary-01 }
  # exploratory quick queries are NOT listed here — they live only as DataLad branches
  # until promoted into a product.

products:                         # cross-linked, DOI-bearing outputs
  - { type: dataset,            doi: 10.xxxx/dataset, status: published, relation: IsSourceOf }
  - { type: paper,              doi: 10.xxxx/paper,   status: submitted, relation: IsDocumentedBy }
  - { type: executable-article, url: https://neurolibre.org/..., status: planned, relation: IsSupplementTo }
  - { type: agent-bundle,       doi: 10.xxxx/agent,   status: planned, relation: IsDerivedFrom }
  - { type: liab,               url: https://data.mylab.org/xyz,   status: planned, relation: IsVariantFormOf }

infrastructure:                   # optional — a Lab-in-a-Box deployment
  liab:
    host: mylab.org
    services: [forgejo, gitannex_staticwww, hedgedoc, dumpthings]
    deployment: liab-deployments

obligations:                      # explicit + derived (from ethics/dmp/funder/milestones/comparisons)
  - { what: "Renew IRB protocol 2025-12345",       due: 2026-11-01, source: ethics,     status: pending }
  - { what: "Submit RPPR",                          due: 2026-12-01, source: funder,     status: pending }
  - { what: "Complete pre-registered comparison cmp-primary-01", source: comparison,     status: pending }
```

The ledger ships with a JSON Schema (`schemas/project.schema.json`) so `ds-harness` and editors can validate it. All sections are optional and additive — a project that only needs milestones and people can ignore the rest. **Confirmatory comparisons are the only ones that enter the ledger** (mirrored into `obligations:` as work "to be completed"); exploratory quick queries stay branch-only until promoted into a product.

---

## Living Research Products

Stage 8 produces a **living research compendium**: four coupled artifacts, all generated from the *same* DataLad provenance chain and cross-linked by DOI in the ledger.

| Artifact | What it is | How it's built | External tooling |
|----------|-----------|----------------|------------------|
| **Provenanced dataset** | Versioned, citable data + analysis record | DataLad + BIDS, pushed via `publish` | OSF / Zenodo |
| **Executable article** | A reproducible preprint that re-runs its own figures/results | `disseminate/executable-article` — MyST/Jupyter Book + `binder/` env (from the DataLad container digest) + `repo2data` pointing at the published dataset | NeuroLibre (MyST, Jupyter Book, BinderHub, repo2data) |
| **Agent bundle** | An MCP server exposing the work's methods as callable, tested tools | `disseminate/agent-bundle` — tools synthesized from the project's scripts + data dictionary, emitted as the harness's own `SKILL.md` + `plugin.yaml` + MCP config | Paper2Agent pattern + Model Context Protocol |
| **Self-hosted deployment** | A data-sovereign home serving the dataset + lab services | `disseminate/liab-deploy` — a `liab-deployments` (pyinfra) config that stands up Forgejo + git-annex data serving and publishes the DataLad dataset via git-annex remotes | Lab-in-a-Box (pyinfra, Podman, Forgejo, git-annex) |

Why this fits the architecture cleanly:

- **NeuroLibre needs exactly what the harness already produces** — a public code repo (notebooks / MyST), a data config, and a pinned, BinderHub-recognized environment. The `datalad`, `bids`, and `containers` capabilities already produce all three; `executable-article` just arranges them into NeuroLibre's expected layout.
- **Paper2Agent's output *is* the harness's own format** — an MCP server + a manifest of tools. Because this project already authors universal `SKILL.md` + MCP configs and ships adapters for them, `agent-bundle` emits its output in that same format and reuses the existing adapter layer. The research product becomes installable into the next researcher's harness with zero new tooling.
- **Lab-in-a-Box gives self-hosted Distributability** — instead of relying solely on external platforms, `liab-deploy` reproducibly stands up the lab's own git host + data-serving infrastructure. The same `git-annex`/DataLad substrate the project already uses becomes its persistent, data-sovereign distribution point. It reuses the `publish` capability's annex-remote mechanics.
- **Cross-linking is provenance, not metadata gardening** — `link-outputs` records the relations (dataset `IsSourceOf` article; article `IsSupplementTo` paper; agent bundle `IsDerivedFrom` code; Lab-in-a-Box `IsVariantFormOf` dataset) using the DataCite schema, written back into the ledger and `dataset_description.json`.

---

## Repository Structure

```
data-science-harness/
├── pyproject.toml                    # Python package: ds-harness CLI
├── README.md
├── CLAUDE.md                         # Claude Code-specific contributor guidance
├── harness.yaml                      # Root collection manifest (groups plugins by plane)
│
├── docs/
│   ├── stamped.md                    # STAMPED principles distillation
│   └── end-to-end-workflow.md        # Full lifecycle walkthrough
│
├── resources/
│   └── Macdonald_STAMPED_2026.pdf    # STAMPED source paper
│
├── schemas/
│   └── project.schema.json           # JSON Schema for the project ledger
│
├── examples/
│   └── project.yaml                  # Worked ledger sample (used by skills/hooks/tests)
│
├── templates/
│   ├── skill/SKILL.md                # Universal skill template
│   ├── executable-article/           # MyST myst.yml + binder/ + repo2data skeleton
│   ├── agent-bundle/                 # plugin.yaml + SKILL.md + MCP-config skeleton
│   └── liab/                         # liab-deployments (pyinfra) skeleton
│
├── plugins/
│   │  ── capability plane (technical tool wrappers) ──
│   ├── datalad/                      # T,S,M — provenance & content tracking
│   │   ├── plugin.yaml               #   plane: capability
│   │   ├── skills/{datalad-run,datalad-container-run,datalad-save,datalad-status,
│   │   │           datalad-clone,datalad-get,datalad-push,datalad-log,checkpoint}/SKILL.md
│   │   ├── hooks/scripts/datalad-checkpoint.sh
│   │   └── references/               # yoda-layout, annex-content-states
│   │
│   ├── nipoppy/                      # S,T,M,A — dataset mgmt + pipeline running
│   │   ├── plugin.yaml
│   │   └── skills/{nipoppy-setup,nipoppy-bidsify,nipoppy-process,nipoppy-track}/SKILL.md
│   │
│   ├── bids/                         # S,M — BIDS validation & layout
│   │   ├── plugin.yaml
│   │   ├── skills/{bids-validate,bids-scaffold}/SKILL.md
│   │   └── references/               # entities, datatypes, sidecars
│   │
│   ├── containers/                   # P,E — environment build/pin/run
│   │   ├── plugin.yaml
│   │   └── skills/{build-container,run-container}/SKILL.md
│   │
│   ├── publish/                      # D — external distribution mechanics
│   │   ├── plugin.yaml
│   │   ├── skills/{osf-push,zenodo-deposit,annex-remote}/SKILL.md
│   │   └── references/               # osf-workflow, zenodo-workflow
│   │
│   ├── annotate/                     # T — variable/assessment standardization tools
│   │   ├── plugin.yaml
│   │   ├── skills/{neurobagel-annotate,snomed-lookup,nidm-annotate,reproschema-annotate}/SKILL.md
│   │   └── references/               # neurobagel-schema, snomed-hierarchy, nidm-schema, reproschema
│   │
│   │  ── workflow plane (research process) ──
│   ├── govern/                       # Stage 0 + Manage & Comply lane
│   │   ├── plugin.yaml               #   plane: workflow
│   │   ├── skills/{init-ledger,dmp,ethics-track,preregister,obligations,stamped-assess}/SKILL.md
│   │   └── references/               # stamped, madmp-schema, hipaa-deid, clinicaltrials-fields
│   │
│   ├── project/                      # Stage 1, 8 + Manage & Comply lane
│   │   ├── plugin.yaml
│   │   ├── skills/{new-project,env-check,claude-config,log-decision,
│   │   │           track-milestone,people,status-report}/SKILL.md
│   │   └── hooks/scripts/obligations-due.sh
│   │
│   ├── curate/                       # Stage 2, 5, 7
│   │   ├── plugin.yaml
│   │   ├── skills/{raw-to-bids,merge-data,gen-data-dict,annotate-variables}/SKILL.md
│   │   └── agents/merge-agent/SKILL.md
│   │
│   ├── analyze/                      # Stages 3–5 — comparison/product engine
│   │   ├── plugin.yaml
│   │   ├── skills/{plan-analysis,propose-comparison,run-comparison,
│   │   │           gen-report,manage-product,literature-search}/SKILL.md
│   │   └── references/               # r-patterns, python-patterns, qc-metrics, decision-tree
│   │
│   └── disseminate/                  # Stages 6–8 — publications + living products
│       ├── plugin.yaml
│       ├── skills/{draft-manuscript,reporting-checklist,submission-track,dataset-release,
│       │           executable-article,agent-bundle,liab-deploy,link-outputs}/SKILL.md
│       └── references/               # equator-guidelines, datacite-relations, cobidas,
│                                     #   neurolibre-structure, paper2agent-bundle, liab-deployments
│
├── src/ds_harness/                   # Python CLI (installer only)
│   ├── cli.py
│   ├── manifest.py
│   ├── installer.py
│   └── adapters/
│       ├── base.py
│       ├── claude_code.py            # → ~/.claude/skills/ + plugin.json
│       ├── cursor.py                 # → .cursor/rules/*.mdc
│       ├── copilot.py                # → .github/instructions/*.instructions.md
│       ├── windsurf.py               # → .windsurf/rules/*.md
│       └── opencode.py               # → TBD
│
├── config/                           # Harness-specific global config templates
│   ├── claude/
│   ├── cursor/
│   └── copilot/
│
└── bin/
    └── install.sh                    # Zero-dependency shell fallback
```

---

## External Standards & Tool Integrations

### Principles & scientific pipeline

| Standard / Tool | What it does | Plane · Plugin | Install requirement |
|-----------------|-------------|----------------|---------------------|
| **STAMPED** | Operating principle framework — the properties every research object is built toward | workflow · `govern` | reference-only (`docs/stamped.md`) |
| **DataLad** | Tracking backbone — records all analysis commands, inputs, outputs | capability · `datalad` | `pip install datalad` |
| **BIDS** | Brain Imaging Data Structure — canonical neuroimaging dataset format | capability · `bids` | `npm install -g bids-validator` |
| **Nipoppy** | Standardized dataset organization + pipeline running & tracking; spans curate → analyze → QC | capability · `nipoppy` | `pip install nipoppy` |
| **Apptainer / Docker** | Portable, ephemeral computational environments | capability · `containers` | container runtime |
| **Neurobagel / bagel-cli** | Annotate phenotypic variables with controlled terms; push to graph | capability · `annotate` | `pip install bagel-cli` |
| **SNOMED CT** | Clinical terminology — normalize variable names to standard codes | capability · `annotate` | SNOMED CT API key or local OWL |
| **ReproSchema** | Standardized representation of behavioral assessments / questionnaires | capability · `annotate` | `pip install reproschema` |
| **NeuroSynth Compose / NiMARE** *(proposed)* | Reproducible coordinate-based meta-analysis of a topic | workflow · `analyze` | web platform; `pip install nimare` |
| **OSF / osfclient** | Push dataset versions, register DOI | capability · `publish` | `pip install osfclient` |
| **Zenodo / zenodraft** | Zenodo deposit — mint DOI, archive dataset release | capability · `publish` | `pip install zenodraft` |

### Administration, compliance & credit

| Standard / Tool | What it does | Plane · Plugin | Notes |
|-----------------|-------------|----------------|-------|
| **RDA DMP Common Standard (maDMP)** | Machine-actionable Data Management Plan format | workflow · `govern` | tracked in ledger `dmp:` |
| **OSF Registrations / ClinicalTrials.gov / PROSPERO** | Study pre-registration & registered reports | workflow · `govern` | recorded in ledger `registration:`; freezes confirmatory comparisons |
| **ORCID** | Persistent researcher identifiers | workflow · `project` | ledger `people[].orcid` |
| **CRediT (NISO)** | Contributor Roles Taxonomy | workflow · `project` | ledger `people[].roles` |
| **ROR** | Research Organization Registry identifiers | workflow · `project` | ledger `affiliation_ror` |
| **Crossref Funder Registry / NIH RePORTER** | Funder & grant identifiers, reporting deadlines | workflow · `govern` | ledger `funding[]` |
| **EQUATOR (CONSORT/STROBE/PRISMA/ARRIVE)** | Reporting guidelines / checklists | workflow · `disseminate` | `reporting-checklist` |
| **COBIDAS** *(neuro pack)* | Neuroimaging reporting standards | workflow · `disseminate` | optional neuro reference pack |
| **NIDM** *(neuro pack)* | Machine-readable neuroimaging annotation & provenance | capability · `annotate` | `pip install pynidm` |
| **DataCite Metadata Schema** | DOI cross-linking via `RelatedIdentifier` | workflow · `disseminate` | `link-outputs` |

### Living research products

| Standard / Tool | What it does | Plane · Plugin | Install requirement |
|-----------------|-------------|----------------|---------------------|
| **NeuroLibre** | Reproducible preprint server — re-executes the article | workflow · `disseminate` | submission via GitHub editorial workflow |
| **MyST / Jupyter Book** | Executable-article authoring format | workflow · `disseminate` | `pip install mystmd jupyter-book` |
| **repo2data / BinderHub / repo2docker** | Data + environment reproducibility for execution | `disseminate` + `containers` | `pip install repo2data` |
| **Paper2Agent + MCP** | Convert the work's methods into an agent-callable MCP server | workflow · `disseminate` | uses the harness's own SKILL.md + MCP format |
| **Lab-in-a-Box (`liab-deployments`)** | Self-hosted, data-sovereign deployment of the dataset + lab services | workflow · `disseminate` + `project` | `pip install liab-deployments`; Podman + systemd + Caddy |

---

## Architecture Notes — Dependencies & Package Scope

> Design notes for contributors and hackathon participants. These describe the intended model; the `ds-harness` package and the `requires:` manifests below are not yet built.

**Standards vs. dependencies.** Most entries in the tables above are *reference-only standards* (STAMPED principles, BIDS conventions, SNOMED / NIDM / Neurobagel schemas, COBIDAS, EQUATOR, DataCite, maDMP, CRediT, ROR, ORCID, …). These need no installation — they live as Markdown in each plugin's `references/` and are baked into skill prompts. Only a smaller set are *executable dependencies* that must actually be installed — and those live almost entirely in the **capability plane**.

**Per-plugin dependency declaration.** Each `plugin.yaml` declares a `requires:` block so dependency requirements stay tracked per module:

```yaml
requires:
  system:    [git, git-annex, datalad]          # OS / non-language tools
  python:    [bagel-cli, pynidm, reproschema]   # pip-installable
  npm:       [bids-validator]                    # Node tools
  reference: [stamped, bids, snomed-ct]          # no install — references/ only
```

Executable dependencies fall into three tiers:

- **Core (always):** `git`, `git-annex`, `datalad` (+ Python/pip-uv for the CLI) — declared once in `harness.yaml`; the Tracking substrate every project sits on (capability plugin `datalad`).
- **Cross-plane (shared by ≥2 plugins):** container runtime (`containers` + `disseminate`), `nipoppy` (`nipoppy` capability spanning curate → analyze → track, driven by `curate` + `analyze`), `osfclient`/git-annex remotes (`publish`, used by `disseminate` + `liab-deploy`), `repo2data` (`containers` + `disseminate`). The main source of inter-plane coupling — always via a capability plugin.
- **Step-localized (one plugin):** e.g. `bids-validator` (`bids`), `bagel-cli` / `pynidm` / `reproschema` (`annotate`), `mystmd` / `jupyter-book` (`disseminate`), `liab-deployments` (`disseminate`/`project`).

Dependencies span pip, npm/Node, and system packages, so `ds-harness` **detects and advises**: it verifies presence/version of every declared dependency, auto-installs only `python:` tools, and prints guidance for `system:` / `npm:` tools.

**What `ds-harness` does beyond copying files.** Translating and installing the Markdown/YAML content is the package's primary job; on top of that it adds a thin layer of *deterministic* support:

- **Validation** (schema-driven, runs as CI on PRs): `project.yaml`, the `requires:` blocks, plugin.yaml/harness.yaml cross-references, and the universal `SKILL.md` superset frontmatter — including a **plane check** (workflow skills must not declare tool dependencies; capability skills must declare a `stamped:` tag) and cross-harness translation-loss warnings.
- **Environment doctor** against the declared `requires:`.
- **Ledger read/query:** `ds-harness obligations | status | validate` provide deterministic reads that back the `obligations-due` hook and status reports. Ledger *edits* stay with the skills/LLM.
- **Install-state tracking** for clean `update` / `remove` and drift detection.

**Guiding line:** the package owns deterministic, verifiable, harness-agnostic operations; skills/LLM own generative judgment (drafting a DMP, choosing a test, writing a manuscript). Every package operation is an *optional convenience* — if the CLI is absent, skills fall back to reading/writing the content directly (Design Rule 2). Deliberately out of scope: re-implementing provenance/analysis orchestration — DataLad and git already own those.

---

## Plugin Manifest (`plugin.yaml`)

Human-readable, no tooling required to understand or contribute. A capability plugin declares its `plane`, the STAMPED letters it serves, and its `requires:`:

```yaml
name: datalad
plane: capability
description: DataLad-based Tracking primitives for all analysis steps
stamped: [T, S, M]
version: "0.1.0"
author: { name: bcmcpher, email: bcmcpher@gmail.com }
license: MIT
keywords: [datalad, tracking, provenance, reproducibility, YODA]
requires:
  system: [git, git-annex, datalad]
skills:
  - ./skills/datalad-run
  - ./skills/datalad-container-run
  - ./skills/datalad-save
  - ./skills/checkpoint
hooks:
  stop: ./hooks/scripts/datalad-checkpoint.sh
harnesses: [all]
```

A workflow plugin declares `plane: workflow` and the capability plugins it orchestrates:

```yaml
name: analyze
plane: workflow
description: Comparison/product engine — plan, propose, run, and group analyses
calls: [datalad, nipoppy]           # capability plugins this workflow invokes
skills:
  - ./skills/plan-analysis
  - ./skills/propose-comparison
  - ./skills/run-comparison
  - ./skills/gen-report
  - ./skills/manage-product
harnesses: [all]
```

The `project` workflow plugin adds a `sessionstart` hook for the obligations reminder:

```yaml
hooks:
  sessionstart: ./hooks/scripts/obligations-due.sh   # surfaces due obligations (Claude Code)
```

---

## CLI Usage (`ds-harness`)

```bash
# Install all plugins for a specific harness
ds-harness install --harness=claude-code
ds-harness install --harness=cursor --scope=project

# Install only the capability plane, or a single plugin
ds-harness install --plane=capability --harness=claude-code
ds-harness install datalad --harness=copilot

# Dry run
ds-harness install --dry-run --harness=windsurf

# List, update, remove
ds-harness list
ds-harness update
ds-harness remove analyze --harness=cursor

# Validate a project ledger against the schema
ds-harness validate ./project.yaml
```

Install the CLI:

```bash
pip install ds-harness
# or
uv tool install ds-harness
```

---

## Root Manifest (`harness.yaml`)

```yaml
name: data-science-harness
description: Community-driven AI assistant configuration for academic data science
version: "0.1.0"
plugins:
  capability:
    - ./plugins/datalad
    - ./plugins/nipoppy
    - ./plugins/bids
    - ./plugins/containers
    - ./plugins/publish
    - ./plugins/annotate
  workflow:
    - ./plugins/govern
    - ./plugins/project
    - ./plugins/curate
    - ./plugins/analyze
    - ./plugins/disseminate
harnesses:
  supported: [claude-code, cursor, copilot, windsurf, opencode, gemini-cli]
```

---

## Design Rules

Each rule is tagged with the STAMPED letter(s) it serves.

1. **Spec-first** — all content is Markdown + YAML; no Python required to read or contribute. **[A]**
2. **Installer is optional** — `bin/install.sh` and per-harness docs let users install without the CLI. **[A, D]**
3. **Claude Code-native but not Claude-only** — Claude Code plugin format is the reference; adapters translate outward. **[P]**
4. **One SKILL.md per skill** — no duplication per harness; adapters generate harness-specific output at install time. **[M, P]**
5. **Capability vs workflow separation** — tool mechanics live in **capability** plugins; research-process logic in **workflow** plugins. A workflow skill never calls a CLI directly — it invokes capability skills. **[M, A]**
6. **Community contribution = write Markdown** — contributors don't touch Python code. **[A]**
7. **References stay in `references/`** — large domain knowledge lives in `references/` dirs, not in SKILL.md bodies. **[S]**
8. **DataLad is the default run path** — the `datalad` capability's skills auto-trigger on analysis commands so the provenance chain is never accidentally broken. **[T, A]**
9. **Environments are pinned and containerized** — the `containers` capability produces portable, disposable environments rebuilt from spec. **[P, E]**
10. **Research products first** — the default project export is a versioned, citable dataset, not a software package. **[D]**
11. **Provenance for administration too** — administrative metadata lives in a versioned `project.yaml` ledger and is `datalad save`-d; every ethics amendment, DMP revision, and DOI is a tracked commit. **[T]**
12. **Obligations are first-class** — deadlines, compliance requirements, and pre-registered comparisons are explicit, queryable ledger entries, never implicit. **[T]**
13. **Reminders degrade gracefully** — a harness-agnostic on-demand `obligations` skill works everywhere; an optional Claude Code `SessionStart` hook surfaces due items where hooks exist. **[A]**
14. **Research products are living** — the default export re-executes (NeuroLibre), is agent-callable (Paper2Agent / MCP), and is self-hostable (Lab-in-a-Box), built from the same provenance chain — never a one-off PDF. **[D, E]**

---

## Relationship to `my-skills`

This project generalizes and re-partitions the Claude Code-specific plugins in [`my-skills`](../my-skills) across the two planes:

| `my-skills` plugin | data-science-harness plugin(s) | Plane | Notes |
|--------------------|--------------------------------|-------|-------|
| `stat-analysis` | `analyze` (+ `curate` merge/dict) | workflow | Add universal frontmatter; add comparison engine |
| `project-init` | `project` | workflow | Data-analysis project type; adds tracking skills + optional LiaB infra |
| `bids` | `bids` | capability | Validation/scaffold subset; workflow orchestration moves to `curate` |
| `datalad-cli` | `datalad` | capability | Core subset (run, container-run, save, clone, get, push, log, checkpoint) |
| `nipoppy-cli` | `nipoppy` | capability | Full CLI wrapper; orchestration moves to `curate`/`analyze` |
| — | `containers` | capability | New — portability/ephemerality |
| — | `publish` | capability | New — OSF/Zenodo/annex-remote mechanics |
| — | `annotate` | capability | New — Neurobagel/SNOMED/NIDM/ReproSchema tool wrappers |
| — | `govern` | workflow | DMP, ethics, pre-registration, STAMPED assessment |
| — | `disseminate` | workflow | Manuscript, reporting guidelines, executable article, agent bundle, Lab-in-a-Box |

---

## Roadmap

**Phase 1 — Capability plane.** Distill `datalad`, `nipoppy`, `bids` from the seed/reference plugins; author `containers`, `publish`, `annotate`. Universal frontmatter + `plane: capability` + `stamped:` tag + `requires:` on each.

**Phase 2 — Workflow plane.** `govern` (ledger + `stamped-assess`), `project` (new-project incl. optional Lab-in-a-Box infra), `curate`, `analyze` (comparison engine), `disseminate` (incl. `executable-article`, `agent-bundle`, `liab-deploy`). Workflow skills call capability skills only.

**Phase 3 — Ledger & schema.** `project.yaml` + `schemas/project.schema.json` with `comparisons`, `liab`, and `infrastructure`; confirmatory-comparison → obligation derivation; the `obligations-due` hook.

**Phase 4 — Python CLI.** `ds-harness` with Claude Code and Cursor adapters first; ledger validation (`ds-harness validate`) and the plane/frontmatter checks.

**Phase 5 — Remaining adapters & release.** Copilot, Windsurf, OpenCode, Gemini CLI; PyPI publish; harden the Lab-in-a-Box deployment recipe; community contribution guidelines.

---

## Contributing

Contributions are Markdown-first. To add a new skill:

1. Decide the **plane**: is this **tool mechanics** (→ a `capability` plugin) or **research process** (→ a `workflow` plugin)? Tool mechanics wrap a single CLI and declare a `stamped:` tag; process logic orchestrates capability skills and must not call a CLI directly.
2. Pick the right plugin (or propose a new one in an issue)
3. Copy `templates/skill/SKILL.md`, fill in the universal frontmatter (including `plane`) and instruction body
4. Add the path to `plugin.yaml`
5. Open a PR

No Python knowledge required. The adapter layer is maintained by core contributors.
