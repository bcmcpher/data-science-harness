# data-science-harness

A community-driven, harness-agnostic collection of AI assistant configurations for academic data science work — skills, agents, commands, hooks, MCP configs, and planning templates. The content is harness-neutral Markdown; `bin/install.sh` installs to **Claude Code and OpenCode today**, and Cursor, GitHub Copilot, Windsurf and Gemini CLI are the harnesses the format is designed to reach next (see [Install](#install)).

> **Status:** the workflow plane is built, the capability plane is uneven — `datalad` has a 19-skill toolbox, `annotate` a 4-skill one, `archive` a 3-skill one, and `bids`, `compendium` and `liab` a 1-skill one each, while `containers` has none — and the [evaluation protocol](docs/evaluation.md) is specified but **unrun**. No number in this repository comes from a measurement. [**Why this exists**](docs/motivation.md) states what is built, what is specified, and what is a gap.

---

## What this is

**Governance should be a by-product of doing the work.** Assistants now execute analyses faster than the surrounding record can be maintained by hand, and anything that requires a separate act of discipline gets skipped under deadline. So the harness routes every computation and every administrative change through one provenance chain — the record is produced by doing the work, not by remembering to. [**Why this exists**](docs/motivation.md) makes the full argument: the problem, who the work is for, what it claims, how you would know, and what is not built.

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
4. **Administration is first-class** — funding, ethics, data-management plans, deadlines, people, and credit are tracked alongside the science, with the same provenance discipline. This is what the by-product commitment above delivers: administration stops being the part reconstructed after the fact

**Two planes of configuration.** The content separates cleanly into a **capability plane** (thin wrappers over the technical tools — DataLad, Nipoppy, BIDS, containers, publishing, annotation) and a **workflow plane** (tool-agnostic research process that *orchestrates* those capabilities). This separation is STAMPED **Modularity** applied to the harness itself — and it is what makes the pieces recombine cleanly (see [Architecture](#architecture)).

**Target harnesses**: Claude Code and OpenCode (installable today via `bin/install.sh`); Cursor, GitHub Copilot, Windsurf and Gemini CLI (designed for, not yet exercised — the content layer is harness-neutral, so a manual copy works anywhere)

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
| **1. Content** (source of truth) | Universal SKILL.md + `.claude-plugin/plugin.json` | Everyone — contributors only write Markdown |
| **2. Installer** (current convenience) | `bin/install.sh` | Users who want automated OpenCode / Claude Code file installs without extra dependencies |
| **3. Package CLI** (planned) | Python CLI (`ds-harness`) | Users who want validation, update/remove state, and broader multi-harness translation |
| **4. Manual fallback** | Per-harness docs + direct copies | Users in locked-down environments |

The content layer is plain Markdown + YAML. The shell installer is just a copier/translator for the supported on-disk layouts — you can clone the repo and manually copy files to any harness without it. The planned Python package adds validation and richer lifecycle commands, but is not required for install.

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

An agent may pin the model it runs on with an optional `model:`. Without it, the agent runs on the
harness default. The value must be one of the bare aliases `haiku`, `sonnet`, `opus` or `fable`, and
the lint checks it. A provider-prefixed value such as `anthropic/claude-haiku-4-5` is rejected,
because producing target-specific forms is the installer's job. Only read-only agents (`bids-doer`,
`coordinator`) may pin a model. A doer that can change a dataset or publish runs on the session
default.

```yaml
---
name: bids-doer
tools: Read, Bash, Grep, Glob
model: haiku               # read-only: validates and reports
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
| `model` (agents) | `model:` as written | — | — | — |

For OpenCode, the installer maps `model:` to `anthropic/claude-haiku-4-5`, `anthropic/claude-sonnet-5`,
`anthropic/claude-opus-5` or `anthropic/claude-fable-5-1`. These resolve only when OpenCode has the
Anthropic provider configured. A value with no mapping is stripped, so the agent inherits the invoking
agent's model rather than failing to load.

---

## Plugins

**21 plugins**, split across the two planes: 15 **capability** plugins wrap the technical tools, and
6 **workflow** plugins encode the research process and call down into them.

Tables below separate what is **built** from what is **planned**. Planned entries are kept because
they carry design intent, but nothing in them exists on disk — the authoritative list of planned
work is [`openspec/changes/`](openspec/changes), where each item has a proposal and a task list.
Within the per-plugin skill lists, an unbuilt skill is marked *(planned)*.

### Capability plugins (technical plane)

A capability plugin is either a **doer** (a subagent owning tool mechanics) or a **toolbox** (a
`*-cli` plugin of one skill per command, which the doer reads as reference material). The
`datalad` pair is the reference shape the others are growing toward.

**Built:**

| Plugin | Kind | Wraps | Contents | STAMPED |
|--------|------|-------|----------|---------|
| `datalad` | doer | DataLad / git-annex | `datalad-doer` | T, S, M |
| `datalad-cli` | toolbox | DataLad CLI | 19 skills, one per command | T, S, M |
| `nipoppy` | doer | Nipoppy | `nipoppy-doer` | S, T, M, A |
| `nipoppy-cli` | toolbox | Nipoppy CLI | 1 skill covering the whole CLI | S, T, M, A |
| `bids` | doer | bids-validator | `bids-doer` | S, M |
| `bids-cli` | toolbox | `@bids/validator` / legacy `bids-validator` | 1 skill + offline validator-presence check | S, M |
| `containers` | doer | Apptainer / Docker | `containers-doer` — no toolbox yet | P, E |
| `archive` | doer | OSF / Zenodo / DataCite | `archive-doer` | D |
| `archive-cli` | toolbox | OSF / Zenodo / DataCite APIs | 3 skills, one per backend, + offline readiness check | D |
| `annotate` | doer | Neurobagel / SNOMED / ReproSchema / NIDM | `annotate-doer` | M, A |
| `annotate-cli` | toolbox | bagel-cli / pynidm / reproschema / SNOMED source | 4 skills, one per backend, + offline per-backend check | M, A |
| `compendium` | doer | MyST (Jupyter Book / repo2data / MCP planned) | `compendium-doer` | A, P, E |
| `compendium-cli` | toolbox | mystmd | 1 skill + offline tool check | A, P, E |
| `liab` | doer | pyinfra (Forgejo planned) | `liab-doer` — plans by default | D |
| `liab-cli` | toolbox | pyinfra | 1 skill + offline tool check | D |

**Planned** — each has an OpenSpec change:

| Plugin | Wraps | Change |
|--------|-------|--------|

The capability plane is the uneven half of the harness. `datalad` has 19 toolbox skills, `annotate`
has 4, `archive` has 3, and `bids`, `compendium` and `liab` have 1 each; `containers` has none, so a planner above them can express
what should happen and can only actually do the parts a toolbox covers. The archive skills were written against
the live OSF, Zenodo, and DataCite APIs, but no deposit has yet been run through them against a live
archive. Closing that is what the changes above are for, and the
observable signal that one has shipped is a planner's `delegates_to:` growing beyond `[datalad]`.

Capability plugins are deliberately thin: they hold tool mechanics and the STAMPED primitives,
nothing about *why* or *when* you run them.

**Nipoppy as a cross-stage capability.** If a project adopts [Nipoppy](https://nipoppy.readthedocs.io) as its dataset-management framework, it is more than a one-shot BIDS converter: it provides a standard CLI and config files (`global_config.json`, a manifest) that span **Initialize → Curate → Analyze → QC** — organizing the dataset, converting raw → BIDS, running preprocessing pipelines (fMRIPrep, QSIPrep, …) through containers, and tracking processing status. A project that declares its expected preprocessing pipelines at setup (see `project/new-project`) wires them into the Nipoppy config so each runs through the `datalad` capability's `container-run` with provenance intact.

### Workflow plugins (conceptual plane)

| Plugin | Lifecycle stages | Built skills |
|--------|------------------|--------------|
| `govern` | 0 + Manage & Comply lane | `init-ledger`, `obligations`, `preregister`, `dmp`, `ethics-track`, `qc-review`, `stamped-assess` |
| `project` | 1, 8 + Manage & Comply lane | `new-project`, `log-decision`, `people`, `status-report`, `track-milestone`, `env-check`, `claude-config` |
| `curate` | 2, 5, 7 | `raw-to-bids`, `annotate`, `deidentify`, `merge-data`, `gen-data-dict` |
| `analyze` | 3–5 | `plan-analysis`, `propose-comparison`, `scaffold-analysis`, `run-comparison`, `plot`, `checkpoint`, `manage-product`, `gen-report` |
| `process` | 2–3 | `run-pipeline` |
| `disseminate` | 6, 7, 8 | `draft-manuscript`, `reporting-checklist`, `dataset-release`, `publish`, `link-outputs`, `executable-article`, `agent-bundle`, `liab-deploy`, `submission-track` |

37 planner skills across the six. The lists below describe each; one, `analyze/literature-search`, is not yet built.

**`govern`** — Stand up and maintain the administrative + compliance backbone (stage 0 and the Manage & Comply lane).
- `obligations` — surface and resolve deadlines, compliance requirements, and confirmatory-comparison commitments recorded in the ledger
- `preregister` — register the study (OSF Registrations / ClinicalTrials.gov / PROSPERO); record the registration ID into the ledger; used to freeze a **confirmatory comparison**'s spec
- `qc-review` — review a dataset's quality and completeness before it moves downstream
- `init-ledger` — create `project.yaml` in a dataset that has none: the **brownfield** entry point for a study already under way. Refuses to overwrite an existing ledger and never backfills its log — the first entry records where the record begins
- `dmp` — author/update a Data Management Plan against the RDA DMP Common Standard (maDMP) or a funder template, and turn each promise it makes into a `kind: dmp` obligation. Never asserts a funder requirement it did not read; reports the sections you still have to fill
- `ethics-track` — record IRB/IACUC protocol, approval, expiry and amendments as a `kind: ethics` obligation (expiry in `due`, protocol in `ref`, amendments append to `log:`); flag upcoming renewals. Never computes an expiry from an approval date, and never rules on whether a use is in scope
- `stamped-assess` — score a research object against the [STAMPED checklist](docs/stamped.md), per dimension against the requirement ids S.1 … D.3, with the evidence for each. **No composite score** (the framework sets no pass mark) and a dimension it could not check is `unassessed`, never zero. Subsumes the old compliance-audit + reproducibility-audit idea
- References: `references/stamped.md`

**`project`** — Scaffold a new research project **and** run the ongoing Manage & Comply lane.
- `new-project` — YODA-structured DataLad dataset (via `datalad`), BIDS layout (via `bids`), a basic scientific-Python container (via `containers`), a declared list of expected preprocessing pipelines wired into the Nipoppy config, CLAUDE.md, the project ledger — **and, optionally, self-hosted Lab-in-a-Box infrastructure** (Forgejo git host, HedgeDoc notes, dumpthings metadata) so the project lives on data-sovereign infra from day one
- `log-decision` — append to a decision / lab-notebook log, then `datalad save`
- `status-report` — generate a progress / funder-RPPR-style summary from the ledger + `datalad log` + git history
- `people` — manage collaborators / ORCID / CRediT contributor roles in the ledger
- `env-check` — report the project's tool dependencies as two separate findings: **declared but absent** (a setup step) and **present but undeclared** (a Portability defect, `P.1`). Runs each capability's own gate script rather than re-implementing it; never installs anything
- `claude-config` — generate CLAUDE.md, settings and MCP stubs from facts verified in the project. Writes no instruction it could not source, and never puts a credential in a committed stub
- `track-milestone` — add/update deadlines in the ledger as `kind: milestone` obligations, so "what's due" has one answer. Never invents a date and never moves one silently — a slip is logged
- `coordinator` — a read-only orientation **agent**, not a skill: it reports where a project stands so a fresh session can get oriented without reconstructing state by hand

**`curate`** — Get raw data into a standardized, annotated form.
- `raw-to-bids` — convert raw acquisitions into BIDS (via the `nipoppy` doer), then validate (via the `bids` doer)
- `annotate` — enrich metadata so the dataset is self-describing: `dataset_description.json`, a `participants.json` data dictionary, BIDS sidecars, and optionally controlled terms via the `annotate` doer (Neurobagel today; NIDM, ReproSchema and SNOMED report unavailable)
- `deidentify` — remove PHI as a recorded, provenanced step rather than an untracked fixup: one `datalad run` per category, with what was deliberately kept and a required residual-risk statement in the ledger. Selecting and running the tools stays 🔧 do-it-yourself
- `merge-data` — combine tabular phenotypic/clinical sources as a provenanced run, with the join key supplied rather than inferred and the row/column arithmetic reported. A wrong join does not fail, it produces a table
- `gen-data-dict` — generate a `participants.json` data dictionary: the skeleton from the data, the meanings from the user or a codebook. An undescribed column gets no entry and appears in the report rather than a guessed `Description`

**`process`** — Run established preprocessing pipelines under provenance.
- `run-pipeline` — execute a preprocessing pipeline (fMRIPrep, QSIPrep, …) through the `nipoppy` and `datalad` doers, so the run is containerized and recorded

**`analyze`** — The comparison/product engine (calls `datalad`, `containers`).
- `propose-comparison` — create a comparison record; pick the rigor mode (quick query vs pre-registered)
- `run-comparison` — execute a comparison via the `datalad` doer on its own branch; check confirmatory results against the registered spec
- `checkpoint` — take a described, clean snapshot of the dataset state
- `manage-product` — group kept comparisons into a product
- `plan-analysis` — recommend a statistical approach from the design and the data's shape, and list the assumptions it rests on as **unchecked**; reports no p-value, effect size or power figure, because a number that arrives before the analysis will be quoted as if it came from one
- `scaffold-analysis` — emit a runnable, provenance-wrapped script stub for the chosen approach: inputs, outputs and run command, with a `NotImplementedError` where the model goes. It writes no analysis logic, and the placeholder **fails loudly** rather than returning a plausible number
- `plot` — consistent exploratory and publication figures, written as a script and run through `run-comparison` so each figure carries the analysis's provenance; every value shown comes from a produced output file, and nothing is mocked up
- `gen-report` — assemble results tables, QC metrics, figures and their commits into an internal report, with a required **gaps section**: assumptions never checked, runs that failed, outputs produced by hand. A missing value reads `not reported`, never a plausible one
- `literature-search` *(planned)* — *(scope deliberately thin; pending participant feedback)* a lightweight BibTeX-collection helper (PubMed / Semantic Scholar), **not** a synthesis engine; the clearer value is connecting to meta-analytic tooling (NeuroSynth Compose / NiMARE)

**`disseminate`** — Turn the finished, provenanced work into publications and living products.

*Classic outputs:*
- `draft-manuscript` — IMRaD scaffold; auto-fill Methods / Data-availability / provenance from `datalad log` + the ledger
- `reporting-checklist` — apply the right EQUATOR guideline (CONSORT / STROBE / PRISMA / ARRIVE) or, with the neuro pack, COBIDAS
- `dataset-release` — bump `dataset_description.json`, write a BIDS `CHANGES` entry, `datalad` git tag, optional Zenodo DOI (via the `archive` doer)
- `publish` — push a released product to an archive and record the identifier it returns
- `submission-track` — record venue, date, status and decision as an append-only `submissions[]` history on the product, so a resubmission does not erase the first venue's outcome. Never records an outcome that has not happened

*Living research compendium:*
- `executable-article` — scaffold a **NeuroLibre-style reproducible preprint**: MyST `myst.yml` + Jupyter Book content, a `binder/` environment from the DataLad container digest, and a `repo2data` file pointing at the OSF/DataLad-published dataset; wire figures to regenerate from the provenanced pipeline. *Delegates to the `compendium` doer, which invokes MyST, resolves each figure's output to the run that produced it, and builds in the project's container — reporting an untraceable figure as `unprovenanced` and a host build as unpinned. `jupyter-book`, `repo2data` and the MCP scaffold are still unbuilt; see [`add-compendium-capability`](openspec/changes/add-compendium-capability).*
- `agent-bundle` — **Paper2Agent-style**: synthesize an MCP server + parameterized tools from the project's scripts + data dictionary, emitted as the harness's *own* universal `SKILL.md` + `plugin.json` + MCP config, with result-reproduction tests. This dogfoods the project's own content format. *Still delegates only to `datalad`: the `compendium` doer exists but its MCP-scaffold skill does not, so this can describe the bundle and commit it. See [`add-compendium-capability`](openspec/changes/add-compendium-capability) section 3.3.*
- `liab-deploy` — **Lab-in-a-Box-style**: scaffold a `liab-deployments` (pyinfra) config that stands up self-hosted Forgejo + git-annex data serving and publishes the provenanced DataLad dataset via git-annex remotes — a **data-sovereign distribution channel** alongside the cloud-hosted article and agent bundle. *Delegates to the `liab` doer, which plans by default and applies only on an explicit instruction naming the target host, and which reports `applied` rather than `working` until a `datalad get` retrieves annexed content from the self-hosted remote. Forgejo instance setup is still unbuilt; see [`add-liab-capability`](openspec/changes/add-liab-capability).*
- `link-outputs` — cross-link dataset / code / paper / preprint / pre-registration / executable-article / agent-bundle / Lab-in-a-Box DOIs & URLs using DataCite `RelatedIdentifier` relation types; write back to the ledger `products:` and `dataset_description.json`
- References: `references/equator-guidelines.md`, `references/datacite-relations.md`

---

## The Project Ledger (`project.yaml`)

The administrative source of truth is a single machine-actionable file at the dataset root, sibling to `dataset_description.json`, and **`datalad save`-d like any other artifact** — so administrative metadata gets *provenance by default* too: every IRB amendment, DMP revision, milestone change, confirmatory-comparison obligation, or new DOI is a tracked commit. Every workflow skill reads/writes it; it auto-fills reports, drives the obligations/reminder surface, and powers STAMPED assessment. A human-readable `PROJECT.md` is generated *from* it on demand and never hand-edited.

```yaml
# project.yaml — the project ledger, as schemas/project.schema.json accepts it today.
# This block is examples/project.yaml; `python3 schemas/validate-ledger.py examples/project.yaml` passes.
project:
  name: demo-study
  description: "Effect of X on outcome Y in cohort Z"
  created: 2026-07-10T14:30:00Z
  dataset_root: .
  stack: python

products:
  # Named deliverables grouped from kept comparisons (analyze/manage-product), released and
  # cross-linked by disseminate/*. Empty at new-project; populated as the story takes shape.
  - id: main-paper
    kind: paper
    title: "X reduces Y in cohort Z"
    status: in-progress
    comparisons: [cmp/group-diff-y]
    outputs: [derivatives/cmp-group-diff-y/]
    dois: []
    relations:
      - { relation: IsSupplementedBy, target: data-release }
  - id: data-release
    kind: dataset
    title: "Cohort Z curated BIDS dataset"
    status: planned
    comparisons: []
    outputs: [.]
    dois: []
    relations: []

obligations:
  # Manage & Comply commitments (govern/*). Resolved by flipping status, never by deletion.
  - id: prereg-h1
    kind: preregistration
    description: "Primary hypothesis (group difference in Y) frozen before data lock"
    due: 2026-09-01
    status: pending
    ref: https://osf.io/xxxxx

contributors:
  # People + CRediT credit (project/people); mirrored to dataset_description.json Authors.
  - name: Ada Researcher
    orcid: https://orcid.org/0000-0002-1825-0097
    affiliation_ror: https://ror.org/00xxxxx
    roles: [Conceptualization, Formal analysis, Writing – original draft]

log:
  # Append-only. Each entry: { ts, op, stage, note, branch? }.
  # Never rewrite or reorder prior entries — corrections are new entries.
  - { ts: 2026-07-10T14:30:00Z, op: new-project, stage: initialize,
      note: "scaffolded YODA+BIDS dataset + container recipe", branch: main }

  - { ts: 2026-07-10T15:05:00Z, op: propose-comparison, stage: analyze,
      note: "cmp: group difference in outcome Y (exploratory quick query)", branch: cmp/group-diff-y }

  - { ts: 2026-07-10T15:40:00Z, op: run-comparison, stage: analyze,
      note: "container-run stats.py; recorded commit a1b2c3d; outputs derivatives/cmp-group-diff-y/",
      branch: cmp/group-diff-y }

  - { ts: 2026-07-10T16:00:00Z, op: checkpoint, stage: analyze,
      note: "datalad save end-of-session; decision log updated", branch: cmp/group-diff-y }

  - { ts: 2026-07-10T16:30:00Z, op: manage-product, stage: analyze,
      note: "grouped cmp/group-diff-y into product main-paper", branch: main }
```

**The schema is strict and small on purpose.** `additionalProperties: false` everywhere, so a typo
is an error rather than a silently ignored key, and it accepts exactly five top-level sections:
`project`, `products`, `obligations`, `contributors`, `log`. The richer shape this README used to
show — `study`, `funding`, `ethics`, `agreements`, `dmp`, `registration`, `people`, `milestones`,
`comparisons`, `infrastructure` — is **design intent, not the current schema**; a ledger written that
way fails validation. The schema grows one section at a time, in the same change that introduces the
skill which writes to it.

The ledger ships with a JSON Schema (`schemas/project.schema.json`) so editors and CI can validate it; `schemas/validate-ledger.py` is the checker. Only `project` and `log` are required, the rest are additive — a project that only needs milestones and people can ignore the rest. **Confirmatory comparisons are the only ones that enter the ledger** (mirrored into `obligations:` as work "to be completed"); exploratory quick queries stay branch-only until promoted into a product.

---

## Living Research Products

Stage 8 produces a **living research compendium**: four coupled artifacts, all generated from the *same* DataLad provenance chain and cross-linked by DOI in the ledger.

| Artifact | What it is | How it's built | External tooling |
|----------|-----------|----------------|------------------|
| **Provenanced dataset** | Versioned, citable data + analysis record | DataLad + BIDS, pushed via `publish` | OSF / Zenodo |
| **Executable article** | A reproducible preprint that re-runs its own figures/results | `disseminate/executable-article` — MyST/Jupyter Book + `binder/` env (from the DataLad container digest) + `repo2data` pointing at the published dataset | NeuroLibre (MyST, Jupyter Book, BinderHub, repo2data) |
| **Agent bundle** | An MCP server exposing the work's methods as callable, tested tools | `disseminate/agent-bundle` — tools synthesized from the project's scripts + data dictionary, emitted as the harness's own `SKILL.md` + `plugin.json` + MCP config | Paper2Agent pattern + Model Context Protocol |
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
├── README.md
├── LICENSE                           # MIT
├── pyproject.toml / uv.lock          # Python toolchain for the check scripts
├── package.json / package-lock.json  # Node toolchain — openspec, mystmd
├── environment.yml                   # conda env for the end-to-end stack
├── .nvmrc
├── bin/
│   └── install.sh                    # OpenCode / Claude Code file installer
├── .claude-plugin/
│   └── marketplace.json              # plugin marketplace manifest
│
├── docs/
│   ├── stamped.md                    # STAMPED principles distillation
│   ├── end-to-end-workflow.md        # full lifecycle walkthrough
│   ├── project-ledger.md             # ledger conventions every planner reuses
│   ├── evaluation.md                 # evaluation protocol (nothing run yet)
│   ├── references/                   # motivating literature — references.bib, index, notes
│   └── writing/                      # manuscript craft reference bundle
│
├── openspec/
│   ├── specs/<capability>/spec.md    # requirements as they stand today
│   └── changes/<change-id>/          # proposed work; archive/ holds merged changes
│
├── paper/                            # the manuscript, as a MyST project
│   ├── myst.yml
│   └── sections/
│
├── bench/                            # evaluation fixtures — probes, tasks, rubrics
│
├── resources/                        # source PDFs (git-ignored)
│
├── schemas/
│   ├── project.schema.json           # JSON Schema for the project ledger
│   └── validate-ledger.py            # the validator
│
├── examples/
│   └── project.yaml                  # worked ledger sample (used by skills/hooks/tests)
│
├── templates/
│   └── skill/SKILL.md                # universal skill template
│
├── plugins/
│   ├── */.claude-plugin/plugin.json  # plugin manifests used by Claude Code and the installer
│   ├── */skills/*/SKILL.md           # universal skill definitions
│   ├── */agents/*.md                 # Claude Code agents / OpenCode subagents
│   ├── */references/                 # plugin reference material copied with bundles
│   └── */hooks/                      # optional; only datalad-cli ships one
│
├── tests/
│   ├── lint-plugins.py               # structural plugin/skill/agent lint
│   ├── lint-plugins-selftest.py      # proves the lint still catches injected drift
│   ├── check-bench-fixtures.py       # structural check over bench/
│   ├── check-paper.sh                # builds paper/, fails on an unresolved citation
│   └── e2e-smoke.sh                  # DataLad provenance smoke test
│
└── .github/workflows/ci.yml          # structure, specs, paper; e2e on dispatch
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

**Per-plugin dependency declaration.** Each plugin's `.claude-plugin/plugin.json` would gain a
`requires` block, so dependency requirements stay tracked per module. No manifest carries one today:

```json
"requires": {
  "system":    ["git", "git-annex", "datalad"],          // OS / non-language tools
  "python":    ["bagel-cli", "pynidm", "reproschema"],   // pip-installable
  "npm":       ["bids-validator"],                       // Node tools
  "reference": ["stamped", "bids", "snomed-ct"]          // no install — references/ only
}
```

Executable dependencies fall into three tiers:

- **Core (always):** `git`, `git-annex`, `datalad` (+ Python/pip-uv for the CLI) — declared once in `harness.yaml`; the Tracking substrate every project sits on (capability plugin `datalad`).
- **Cross-plane (shared by ≥2 plugins):** container runtime (`containers` + `disseminate`), `nipoppy` (`nipoppy` capability spanning curate → analyze → track, driven by `curate` + `analyze`), `osfclient`/git-annex remotes (`publish`, used by `disseminate` + `liab-deploy`), `repo2data` (`containers` + `disseminate`). The main source of inter-plane coupling — always via a capability plugin.
- **Step-localized (one plugin):** e.g. `bids-validator` (`bids`), `bagel-cli` / `pynidm` / `reproschema` (`annotate`), `mystmd` / `jupyter-book` (`disseminate`), `liab-deployments` (`disseminate`/`project`).

Dependencies span pip, npm/Node, and system packages, so `ds-harness` **detects and advises**: it verifies presence/version of every declared dependency, auto-installs only `python:` tools, and prints guidance for `system:` / `npm:` tools.

**What `ds-harness` does beyond copying files.** Translating and installing the Markdown/YAML content is the package's primary job; on top of that it adds a thin layer of *deterministic* support:

- **Validation** (schema-driven, runs as CI on PRs): `project.yaml`, the `requires` blocks, plugin-manifest and root-manifest cross-references, and the universal `SKILL.md` superset frontmatter — including a **plane check** (workflow skills must not declare tool dependencies; capability skills must declare a `stamped:` tag) and cross-harness translation-loss warnings.
- **Environment doctor** against the declared `requires:`.
- **Ledger read/query:** `ds-harness obligations | status | validate` provide deterministic reads that back the `obligations-due` hook and status reports. Ledger *edits* stay with the skills/LLM.
- **Install-state tracking** for clean `update` / `remove` and drift detection.

**Guiding line:** the package owns deterministic, verifiable, harness-agnostic operations; skills/LLM own generative judgment (drafting a DMP, choosing a test, writing a manuscript). Every package operation is an *optional convenience* — if the CLI is absent, skills fall back to reading/writing the content directly (Design Rule 2). Deliberately out of scope: re-implementing provenance/analysis orchestration — DataLad and git already own those.

---

## Plugin Manifest (`.claude-plugin/plugin.json`)

Each plugin carries one manifest at `plugins/<name>/.claude-plugin/plugin.json`. It is the
registration list: it declares the plugin's identity and enumerates the skills and agents that ship
with it. A skill or agent on disk but absent from the manifest **will not load**, which is a silent
failure — `tests/lint-plugins.py` checks the relationship in both directions and errors on either
side of the mismatch.

A capability plugin providing a doer:

```json
{
  "name": "datalad",
  "description": "DataLad doer (capability plane): the tool subagent that executes all DataLad / git-annex operations with provenance — create datasets, run/container-run commands, save, inspect status/log, push to siblings. Workflow-plane planner skills delegate here instead of calling the CLI directly.",
  "version": "0.1.0",
  "author": { "name": "bcmcpher" },
  "license": "MIT",
  "keywords": ["datalad", "git-annex", "provenance", "reproducibility", "doer", "capability"],
  "agents": ["./agents/datalad-doer.md"]
}
```

A workflow plugin listing its planner skills:

```json
{
  "name": "govern",
  "description": "Governance planner (workflow plane): the Manage & Comply lane + QC/review. …",
  "version": "0.1.0",
  "author": { "name": "bcmcpher" },
  "license": "MIT",
  "keywords": ["data-science", "govern", "preregistration", "obligations", "compliance", "workflow"],
  "skills": [
    "./skills/preregister",
    "./skills/obligations",
    "./skills/qc-review"
  ]
}
```

**The manifest does not carry harness metadata.** `plane`, `stamped` and `delegates_to` live in each
skill's own frontmatter, not in the manifest, so a skill is self-describing wherever it is installed:

```yaml
---
name: run-comparison
description: >
  Execute a proposed comparison's analysis script with full DataLad provenance, on its branch,
  inside the project container. Trigger on "run the comparison", …
plane: workflow
stamped: [A, T, P, E]
delegates_to: [containers, datalad]
---
```

That split is deliberate. The manifest is what a harness reads to load files; the frontmatter is what
the harness-agnostic content says about itself. Putting `plane` in the manifest would mean a skill
copied out of its plugin no longer knows which plane it belongs to.

Every plugin must also appear in the top-level `.claude-plugin/marketplace.json`, or it is not
installable. The lint checks that too.

A plugin may ship a `hooks/` directory — `datalad-cli` is the only one that currently does.

## Install

The current installer is `bin/install.sh`. It copies the existing Claude Code-compatible plugin content into the target harness's native file layout without changing the source plugins.

It takes `--harness opencode|claude-code` and `--scope project|global`, plus `--target` to override the resolved directory and `--dry-run` to print the copies it would make without touching the filesystem. **With no arguments it installs every plugin for OpenCode at project scope** — OpenCode is the default target, because Claude Code has its own native `claude plugin install` path and OpenCode does not.

The installer is deliberately a small file copier and translator, so someone in a locked-down environment can reproduce what it does by hand.

OpenCode project install:

```bash
bin/install.sh --harness opencode --scope project
```

OpenCode global install:

```bash
bin/install.sh --harness opencode --scope global
```

Install selected plugins only:

```bash
bin/install.sh --harness opencode --scope project project analyze datalad datalad-cli
```

Preview an install:

```bash
bin/install.sh --harness opencode --scope project --dry-run
```

For OpenCode, the installer writes:

| Scope | Skills | Subagents | Plugin bundles / references |
|-------|--------|-----------|-----------------------------|
| Project | `.opencode/skills/<name>/SKILL.md` | `.opencode/agents/<name>.md` | `.opencode/dsh/plugins/<plugin>/` |
| Global | `~/.config/opencode/skills/<name>/SKILL.md` | `~/.config/opencode/agents/<name>.md` | `~/.config/opencode/dsh/plugins/<plugin>/` |

OpenCode also discovers Claude-compatible skill paths such as `.claude/skills/`, but this installer writes to `.opencode/` explicitly so OpenCode installs are easy to inspect and remove. Installed skill and agent copies have prompt-visible reference paths rewritten to the installed bundle location; source files under `plugins/` are not rewritten.

Claude Code still supports its native plugin install path:

```bash
claude plugin install ./plugins/project
claude plugin install ./plugins/analyze
claude plugin install ./plugins/datalad
```

The shell installer can also copy Claude Code-native skill and agent files for a project or globally:

```bash
bin/install.sh --harness claude-code --scope project
bin/install.sh --harness claude-code --scope global project analyze datalad
```

For Claude Code copy installs, the installer writes `.claude/skills/`, `.claude/agents/`, and `.claude/dsh/plugins/` for project scope, or the matching `~/.claude/` directories for global scope. This does not remove or alter `.claude-plugin/plugin.json`, so existing `claude plugin install ./plugins/<name>` workflows continue to work.

---

## Future CLI (`ds-harness`)

The planned Python CLI is not currently present in this repository. The intended interface is:

```bash
# Install all plugins for a specific harness
ds-harness install --harness=claude-code
ds-harness install --harness=opencode
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

Once packaged, install the CLI with:

```bash
pip install ds-harness
# or
uv tool install ds-harness
```

---

## Root Manifest (`harness.yaml`) — planned

> **Not built.** There is no `harness.yaml` on disk. What registers the plugin set today is
> [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json), which `bin/install.sh` reads
> and `tests/lint-plugins.py` checks every plugin against. The sketch below is the intended shape
> for a root manifest that also records the plane split and the supported harnesses.

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
| `bids` | `bids` | capability | Validation subset only — the doer is read-only and never modifies the dataset; scaffolding and workflow orchestration move to `curate` |
| `datalad-cli` | `datalad` | capability | Core subset (run, container-run, save, clone, get, push, log, checkpoint) |
| `nipoppy-cli` | `nipoppy` | capability | Full CLI wrapper; orchestration moves to `curate`/`analyze` |
| — | `containers` | capability | New — portability/ephemerality |
| — | `disseminate/publish` + `archive` | workflow + capability | New — the planner skill is `disseminate/publish`; OSF/Zenodo/DataCite mechanics live in the `archive` doer |
| — | `curate/annotate` + `annotate` | workflow + capability | New — the planner skill is `curate/annotate`; the Neurobagel/SNOMED/NIDM/ReproSchema wrappers live in the `annotate` doer and its four `annotate-cli` skills ([`openspec/specs/annotate`](openspec/specs/annotate/spec.md)) |
| — | `govern` | workflow | DMP, ethics, pre-registration, STAMPED assessment |
| — | `disseminate` | workflow | Manuscript, reporting guidelines, executable article, agent bundle, Lab-in-a-Box |

---

## Developing on this repo

**Using the harness needs nothing installed.** `bin/install.sh` is a shell file copier and the
content is plain Markdown — see [Install](#install). The toolchains below are for *checking and
building this repository*, and each is pinned in a committed manifest, because STAMPED P.2/P.3 ask
that computational environments be explicitly specified and version controlled and it would be odd
to ask that of users and not of ourselves.

| Toolchain | Manifest | Locked | Enables |
|---|---|---|---|
| Python | `pyproject.toml` | `uv.lock` | the four check scripts |
| Node | `package.json` | `package-lock.json` | `openspec validate`, the `paper/` build |
| e2e stack | `environment.yml` | *deliberately not* — see the file | `tests/e2e-smoke.sh` |

```bash
# Python checks
uv sync --group dev
uv run python tests/lint-plugins.py --strict        # plugin/skill/agent structure
uv run python tests/lint-plugins-selftest.py        # meta-test of the lint
uv run python schemas/validate-ledger.py examples/project.yaml
uv run python tests/check-bench-fixtures.py         # evaluation fixtures + routing ground truth

# Node CLIs (resolved from node_modules, not globally)
npm ci
npm run spec:validate     # openspec validate --all --strict
npm run paper:check       # build paper/ and fail on any unresolved citation

# End-to-end provenance smoke test (needs git-annex; apptainer is a system package)
conda env create -f environment.yml && conda activate ds-harness-e2e
bash tests/e2e-smoke.sh
```

Each check exits **2** when its own dependency is absent, so it degrades to a skip rather than a
failure. [`.github/workflows/ci.yml`](.github/workflows/ci.yml) installs from the manifests and
treats a 2 as an environment error, since the lock file should have supplied the dependency.

CI checks **structure and specs, not agent behaviour** — see [Evaluating the harness](#evaluating-the-harness).

## Planning & specs — `openspec/`

The forward plan no longer lives in this README. It lives in [`openspec/`](openspec), where each
proposed change is a validated record rather than a checkbox in a 55 KB file:

- **[`openspec/specs/`](openspec/specs)** — 20 specs describing what the harness *does today*,
  grounded in the checks that already enforce it (`tests/lint-plugins.py`, `tests/e2e-smoke.sh`,
  `schemas/project.schema.json`).
- **[`openspec/changes/`](openspec/changes)** — what we have decided to do next. The former
  "deepening the capability plane" roadmap is now four open changes: `add-compendium-capability`,
  `add-deidentify-skill`, `add-liab-capability`, and `deepen-bids-nipoppy`.
- **[`openspec/changes/archive/`](openspec/changes/archive)** — changes that shipped. A change leaves
  `changes/` only when its tasks are done and its spec delta has been merged into `specs/`, so the
  open list stays an accurate account of what is *not* built.

```bash
openspec list            # proposed changes
openspec list --specs    # current specs
openspec show <id>       # a change or a spec
openspec validate --all --strict
```

[`openspec/README.md`](openspec/README.md) covers the conventions — including the fact that OpenSpec
calls a spec folder a "capability", which is *not* this repository's "capability plane".

**Where the harness stands.** The workflow plane is complete: 37 planner skills across six workflow
plugins, each naming concrete ledger fields, log-entry shapes, and delegations. The capability plane
beneath them is uneven — `datalad` has 19 toolbox skills, `annotate` has 4, `archive` has 3, and
`bids`, `compendium` and `liab` have 1 each, while `containers` has none, so most steps can express
what should happen but can only actually *do* the git-annex, annotation, archive, validation,
article-build and deployment-planning parts. Closing that gap is what the changes above are for. The observable signal that one has shipped
is a planner's `delegates_to:` growing beyond `[datalad]`.

## Evaluating the harness

[`docs/evaluation.md`](docs/evaluation.md) specifies four probes — routing accuracy, provenance
completeness, end-to-end reproducibility, and cost — with declarative fixtures in
[`bench/`](bench). **None has been run.** The protocol is written before the capabilities it would
measure, deliberately.

The paper describing all of this is drafted in [`paper/`](paper) as a MyST project; its motivating
literature is tracked in [`docs/references/`](docs/references).

## License

Two licences, split by what the file is rather than by what reads it:

| Covers | Licence | SPDX |
|--------|---------|------|
| **Content** — `plugins/**/*.md`, `docs/`, `templates/`, `openspec/`, `paper/`, `bench/`, `examples/`, this README | Creative Commons Attribution 4.0 International | `CC-BY-4.0` |
| **Code** — `bin/`, `tests/`, `schemas/`, the JSON manifests, `.github/`, the dependency manifests | MIT | `MIT` |

See [`LICENSE`](LICENSE), [`LICENSE-CONTENT.md`](LICENSE-CONTENT.md), and
[`REUSE.toml`](REUSE.toml) for the path-by-path mapping. `paper/myst.yml` declares the same split
for the manuscript.

A `SKILL.md` is prose that instructs a model. Licensing it as software because a machine consumes it
would put the boundary in the wrong place — so it is content, and reuse requires attribution.
STAMPED **D.3** asks that each module carry an explicit licence with a resolvable identifier; this
is the repository holding itself to the principle it publishes.

---

## Contributing

Contributions are Markdown-first. To add a new skill:

1. Decide the **plane**: is this **tool mechanics** (→ a `capability` plugin) or **research process** (→ a `workflow` plugin)? Tool mechanics wrap a single CLI and declare a `stamped:` tag; process logic orchestrates capability skills and must not call a CLI directly.
2. Pick the right plugin (or propose a new one in an issue)
3. Copy `templates/skill/SKILL.md`, fill in the universal frontmatter (including `plane`) and instruction body
4. Add the path to the plugin's `.claude-plugin/plugin.json` (`skills[]` or `agents[]`) — the lint errors if you skip this, because an unregistered skill silently never loads
5. Open a PR

No Python knowledge required. The adapter layer is maintained by core contributors.
