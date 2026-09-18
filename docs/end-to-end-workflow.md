# End-to-End Research Workflow with `data-science-harness`

A walkthrough for a researcher setting up and running a complete analysis **using every plugin** in the collection. Steps are ordered by lifecycle stage (0 → 8) with the cross-cutting *Manage & Comply* lane running throughout.

Skills are named as `plugin/skill`. **Workflow-plane** plugins (`govern`, `project`, `curate`, `analyze`, `process`, `disseminate`) drive each stage; they delegate down to **capability-plane** doers (`datalad`, `nipoppy`, `bids`, `containers`, `archive`) for the actual tool mechanics — shown as *(→ the `x` doer)*. See the [README architecture](../README.md#architecture) for the two-plane model and [STAMPED](stamped.md) for the principles.

> **This walkthrough describes the intended workflow, not a fully built one.** A skill marked
> ***(planned)*** does not exist on disk — it is design intent, and the authoritative list of what is
> being built is [`openspec/changes/`](../openspec/changes). Everything unmarked is real and
> installable today. The ⚠️ callouts below name the gaps that matter most in practice.

Two kinds of callout are interleaved with the configuration steps:

- > 🔧 **Do-it-yourself** — the scientific/engineering work the harness does *not* do for you (model selection, scripting, plotting, interpretation). The skills scaffold around this work; they don't replace it.
- > ⚠️ **Scaffolding gap** — a place where the current plugin set leaves you on your own and could plausibly be refined.
- > ✅ **Now planned** — a gap the design discussion has since folded into the intended configuration.

Skills are invoked the way your harness invokes them (e.g. `/new-project` in Claude Code, an auto-triggered rule in Cursor).

---

## Phase 0 — Install and configure the harness

Before any research begins, stand up the tooling itself.

1. **Clone the harness** and run the installer. There is no package to install — `bin/install.sh` is a shell file copier, and it is the whole distribution mechanism:
   ```bash
   git clone https://github.com/bcmcpher/data-science-harness
   data-science-harness/bin/install.sh --harness claude-code --scope project
   ```
   With no arguments it installs every plugin for OpenCode at project scope. Use `--scope global` to install once for all projects, `--dry-run` to see what would be copied, and positional plugin names to install a subset (`bin/install.sh project analyze datalad datalad-cli`).
2. **Install the dependencies the plugins drive.** At minimum `git`, `git-annex` and `datalad`; a container runtime (Apptainer or Docker) for anything that runs an analysis. `environment.yml` in the harness repo is a working conda environment for the first three.

> 🔧 **Do-it-yourself:** installing is manual. `project/env-check` reports what the committed manifests declare against what the machine has, separating *present but undeclared* (a Portability defect — it works here and breaks for the next person) from *declared but absent* (a setup step). It never installs, because installing a tool to make a check pass destroys the finding.

> ⚠️ **Scaffolding gap:** **there is no `ds-harness` CLI.** The README sketches one (`ds-harness install`, `list`, `update`, `validate`) and it is not built — `bin/install.sh` has no `update` or `remove`, so changing the harness version means re-running the installer. `project/claude-config` generates `CLAUDE.md`, settings and MCP stubs from what the project actually contains — it asks about anything it cannot source, because a CLAUDE.md is loaded into every session and followed rather than questioned.

> 🔧 **Do-it-yourself:** choose your harness, your language (R / Python / Julia), and a package manager (`conda` / `renv` / `uv`). Analyses should run in a container (required for `datalad container-run`), and you list the preprocessing pipelines you expect to use (fMRIPrep, QSIPrep, …) so `project/new-project` can scaffold them into the Nipoppy / container config.

> ✅ **Now planned:** container build is now a first-class capability. The `containers` plugin (`build-container`, `run-container`) scaffolds and pins a **basic scientific-Python container**; `project/new-project` invokes it and wires declared preprocessing pipelines into the Nipoppy config. The remaining refinement is pinning the recipe to your exact language/stack.

---

## Stage 0 — Propose & Govern

Set up the administrative and scientific *plan* before touching data.

1. **`analyze/literature-search` *(planned)*** — *(scope deliberately thin, pending participant feedback)* a lightweight BibTeX-collection helper (PubMed / Semantic Scholar), **not** an AI summary engine. The clearer connection is to meta-analysis tooling like **NeuroSynth Compose / NiMARE**.
2. **`analyze/propose-comparison`** — sketch the first comparison(s): outcomes, design, and power/effect-size estimation. Choose the rigor mode (quick query vs pre-registered — see [Comparisons](#the-comparison-spectrum-in-practice)).
3. **`govern/init-ledger` *(planned)*** — create `project.yaml`, the administrative source of truth.
4. **`project/people`** — add collaborators with ORCID and CRediT roles to the ledger.
5. **`govern/dmp` *(planned)*** — author a Data Management Plan (RDA maDMP / funder template); its obligations are written into the ledger.
6. **`govern/ethics-track` *(planned)*** — record the IRB/IACUC protocol, approval, and expiry (drives a renewal obligation).
7. **`govern/preregister`** — register on OSF / ClinicalTrials.gov / PROSPERO; record the ID in the ledger. This is also how a **confirmatory comparison** freezes its spec.
8. **`project/track-milestone`** — set the study's key dates and deliverables, as `kind: milestone` obligations in the same registry as every other commitment.

> 🔧 **Do-it-yourself:** this is where the *science* is designed. You decide the hypotheses, the primary and secondary outcomes, the inclusion/exclusion criteria, the model family, and the sample-size justification. `analyze/propose-comparison` computes power once you supply an expected effect size and design — it does not choose them for you.

> ✅ **Now planned:** the earlier "how minimal should comparison-tracking be?" question is resolved — see [The comparison spectrum in practice](#the-comparison-spectrum-in-practice). Quick queries are zero-ledger DataLad branches; pre-registered comparisons are ledger obligations. Strict pre-registration is one (optional) end of the spectrum.

---

## Stage 1 — Initialize

1. **`project/new-project`** — scaffold a YODA-structured DataLad dataset *(→ `datalad`)*, a BIDS skeleton *(→ the `bids` doer)*, the environment/container *(→ the `containers` doer)*, `CLAUDE.md`, and the project ledger. (This is also where `govern/init-ledger` *(planned)* lands if you deferred it.)
2. **`project/new-project --with-liab`** *(optional)* — provision **Lab-in-a-Box working infrastructure**: stand up a self-hosted Forgejo git host, HedgeDoc for lab notes, and dumpthings for metadata capture via `liab-deployments`, so the project lives on data-sovereign infra from day one.

> 🔧 **Do-it-yourself:** lay out your `code/` directory, decide naming conventions for derivatives, and pin your environment (`environment.yml` / `renv.lock` / `requirements.txt`). Build/select the analysis container now if you're using one.

---

## Stage 2 — Curate

Get raw data into a standardized, annotated form. The `curate` workflow orchestrates the `nipoppy`, `bids`, and `annotate` capabilities.

1. **`curate/raw-to-bids`** *(→ the `nipoppy` or `bids` doer)* — convert raw acquisitions into BIDS layout. If you've adopted **Nipoppy** as your primary tool, this is one command in a framework whose config files also drive Stages 3 and 5.
2. …then validate *(→ the `bids` doer)* — confirm the dataset is BIDS-compliant.
3. **`curate/merge-data`** — combine tabular phenotypic/clinical sources as a provenanced run, on a join key you supply, with rows in / rows out / keys dropped per side in the report. A wrong join does not fail, it produces a table, so the arithmetic is the output that matters.
4. **`curate/gen-data-dict`** — generate a data dictionary for the tabular data. The skeleton comes from the data; the meanings come from you or the `annotate` doer. An undescribed column gets no entry and is named in the report, because a description that restates the column name hides the gap.
5. **`curate/annotate`** *(→ the `annotate` doer)* — decide which variables to standardize and let the doer drive the tools. All four backends have a skill: Neurobagel via `annotate-cli/bagel-cli` (phenotypic/clinical), SNOMED CT via `snomed-lookup`, behavioral assessments via `reproschema`, and imaging experiment/results via `pynidm` — see [`openspec/specs/annotate`](../openspec/specs/annotate/spec.md). Each is checked independently, so an uninstalled tool or an unconfigured SNOMED source comes back unavailable while the others still run. 🔧 Note what *finds* a term as opposed to validating one: only the SNOMED lookup and an interactive `pynidm` session resolve a new identifier, and the latter needs you at the prompt. The doer never recalls a term identifier; an unresolved variable comes back `unannotated` with the reason.

> 🔧 **Do-it-yourself:** the real data wrangling — cleaning, format conversion for non-standard inputs, defining variables and units, deciding how to handle missingness and outliers. The skills *standardize and annotate* what you've defined; they don't define it.

6. **`curate/deidentify`** *(→ the `datalad` doer)* — inventory what identifiers are actually present per category (tabular, filenames, DICOM/NIfTI headers, and facial anatomy in structural imaging), decide removal / pseudonym / coarsening / deliberate retention with the user, and run each removal as its own `datalad run` so it joins the provenance chain like any other transformation. The record is the point: the approach, what was verified and how, what was deliberately kept, and a **residual-risk statement that is required and never blank** — an empty one is itself the claim that nothing remains. An ethics obligation is resolved by `resolved_by` naming the run, which the ledger schema enforces, so it cannot be closed by assertion.

> 🔧 **Do-it-yourself:** choosing and running the de-identification tools — defacing (`pydeface`, `mri_deface`, `mideface`), DICOM header scrubbing, PHI column detection, date-shifting — and **inspecting the output**. None of it ships with the harness, and the skill will not select a tool or invent a command line for you: a defacing tool with the wrong mask removes brain tissue, and an inconsistently applied date-shift destroys a longitudinal design while looking like it worked. The skill scaffolds the decision and the record; you run the tool and check it.

> ⚠️ **Scaffolding gap:** de-identification *tooling* is still unscaffolded — there is no capability plane beneath `curate/deidentify`. The step is now recorded and provenanced, which is the half that was missing; automating the removal itself is capability-plane work and a later change.

---

## Stage 3 — Analyze

The `analyze` workflow runs each comparison through the `datalad` capability so provenance is never broken.

1. **`analyze/plan-analysis`** — recommend a statistical approach from the design and the data's shape, and list the assumptions it rests on as **unchecked**. It reports no statistic of its own.
2. **`analyze/propose-comparison`** — record the comparison (quick query or pre-registered) as its own unit.
3. **`analyze/scaffold-analysis`** — emit the script stub for it: declared inputs, one output directory, the run command, and a placeholder that raises where the model goes.
4. **`analyze/run-comparison`** *(→ `datalad-cli/datalad-run` or `datalad-cli/datalad-container-run`)* — execute the comparison on its own DataLad branch so inputs, command, and outputs are recorded. These auto-trigger on `python …`, `Rscript …`, `apptainer exec …`, etc. Preprocessing pipelines declared via **Nipoppy** also run through this path *(→ the `nipoppy` doer)*, keeping provenance intact. For a confirmatory comparison, the result is checked against the registered spec.
5. **`analyze/plot`** — figures from the produced outputs, written as a script and run through `run-comparison` so each panel carries the same provenance as the analysis.

> 🔧 **Do-it-yourself:** you write the model. `plan-analysis` recommends *which* approach and `analyze/scaffold-analysis` writes everything around it — argument parsing, declared inputs, the output directory, the run command — leaving a placeholder that **raises** where model specification, feature engineering, estimator and hyperparameter choices go. The `datalad` capability wraps whatever you then run. The stub is deliberately unable to produce a result until you have written one.

> 🔧 **Do-it-yourself:** checking the assumptions `plan-analysis` listed is yours. Testing normality, inspecting residuals or judging whether the design is adequate are analyses in their own right and run through `propose-comparison` / `run-comparison` like any other — nothing here checks them for you, and nothing reports them as checked.

> ⚠️ **Scaffolding gap:** analysis code itself is untested. No skill scaffolds unit tests or smoke tests for analysis scripts, which undercuts the reproducibility promise.

---

## Stage 4 — Checkpoint

1. **`analyze/run-comparison`** / **`project`** *(→ `datalad-cli/datalad-save`, `analyze/checkpoint`)* — structured commits of intermediate state; an auto-hook also checkpoints at session end.
2. **`project/log-decision`** — record *why* you made each analytic choice, into the decision log, then `datalad save`.

> 🔧 **Do-it-yourself:** analysis is iterative — loop Stage 3 ↔ 4. Capture the reasoning behind branch points (why this covariate set, why this transform); that log feeds your eventual Methods section.

---

## Stage 5 — QC / Review

1. **`govern/stamped-assess` *(planned)*** — score the research object against the [STAMPED checklist](stamped.md): does the analysis reproduce from the DataLad log (Tracking/Actionability)? Are inputs available via `datalad get` (Self-containment)? Are ledger obligations, de-identification, DUA data-scope, and pre-registration adherence satisfied? **This one skill subsumes the earlier separate reproducibility-audit and compliance-audit.**
2. **`curate`** *(→ the `bids` doer)* — re-validate after derivatives are added.
3. **`analyze/gen-report`** — assemble results tables, QC metrics, figures and the commit behind each into an internal report, with a required **gaps section**: assumptions never checked, runs that failed, outputs produced by hand. A value in no output file reads `not reported`.

> 🔧 **Do-it-yourself:** interpret the results, run sensitivity/robustness analyses, check statistical assumptions, and decide whether the findings are publication-ready. `stamped-assess` confirms the work is *reproducible and compliant*; it does not tell you whether it is *correct or meaningful*.

> ⚠️ **Scaffolding gap:** no skill supports sensitivity analyses, assumption checking, or multiple-comparison correction as active steps. `stamped-assess` reports prereg adherence for confirmatory comparisons, but does not drive the robustness work itself.

---

## Stage 6 — Export

1. **`disseminate`** *(→ `publish/osf-push`)* — push the dataset version to an OSF node and register it as a DataLad sibling.
2. Provenance summary from `datalad-cli/datalad-log` accompanies the bundle.

> 🔧 **Do-it-yourself:** decide *what* is shareable (which derivatives, which intermediates), the access level (public / embargo), and any storage constraints.

---

## Stage 7 — Publish

1. **`disseminate/dataset-release`** *(→ `publish/zenodo-deposit`, `datalad` tag)* — bump `dataset_description.json` version, write a BIDS `CHANGES` entry, create a git tag, and optionally mint a Zenodo DOI.
2. Finalize **`curate/annotate`** *(→ the `annotate` doer)* and push the **Neurobagel** graph. The doer builds the graph file via `annotate-cli/bagel-cli`; pushing it to a Neurobagel node is still do-it-yourself.

> 🔧 **Do-it-yourself:** choose the dataset license, citation, and authorship; decide semantic-versioning policy for the data product.

---

## Stage 8 — Disseminate & Report

Produce the living research compendium and the classic outputs.

1. **`disseminate/draft-manuscript`** — IMRaD scaffold with Methods / Data-availability / provenance auto-filled from the DataLad log + ledger.
2. **`disseminate/reporting-checklist`** — apply the right EQUATOR guideline (CONSORT / STROBE / PRISMA / ARRIVE) or COBIDAS for neuroimaging.
3. **`disseminate/executable-article`** — scaffold a NeuroLibre reproducible preprint (MyST / Jupyter Book + `binder/` + `repo2data`) whose figures regenerate from the pipeline.
4. **`disseminate/agent-bundle`** — emit a Paper2Agent-style MCP server exposing the methods as callable, tested tools.
5. **`disseminate/liab-deploy`** — stand up a **Lab-in-a-Box** deployment: a self-hosted Forgejo + git-annex data-serving home for the provenanced dataset, published via git-annex remotes. A data-sovereign distribution channel alongside the article and agent bundle.
6. **`disseminate/link-outputs`** — cross-link dataset / code / paper / preprint / prereg / executable-article / agent-bundle / Lab-in-a-Box DOIs & URLs (DataCite relations) back into the ledger.
7. **`disseminate/submission-track` *(planned)*** — track target journal, submission, and revisions.
8. **`project/status-report`** — generate the funder/progress report from the ledger + history.

> 🔧 **Do-it-yourself:** write the science — intro, discussion, related work, the narrative. `analyze/plot` builds the publication figures from produced outputs under provenance, but what is worth showing, and what it means, is yours. The manuscript scaffold fills in the mechanical/provenance sections; the intellectual content, journal selection, cover letter, and reviewer responses are yours.

> ⚠️ **Scaffolding gap:** `agent-bundle` assumes your analysis code is already structured as importable, parameterized functions — if your Stage-3 scripts were one-off, bundling them as tools is real work that nothing helps with. (Publication figures are now scaffolded by `analyze/plot`, which runs the figure script under provenance so each panel traces to the output it was drawn from.)

---

## Ongoing — Manage & Comply (all stages)

Running in parallel from Stage 0 onward:

- **`govern/obligations`** (shared core with `govern`) — on demand, list what's due, including **pre-registered comparisons still to complete**; a Claude Code `SessionStart` hook surfaces items due soon.
- **`project/track-milestone`**, **`project/log-decision`**, **`project/people`**, **`project/status-report`** — keep the ledger current. A moved deadline updates `due` *and* logs the old date with the reason, because a slip is information.
- **`govern/stamped-assess` *(planned)*** — re-run periodically, not just at QC.

> ⚠️ **Scaffolding gap:** reminders are pull-based (a skill you invoke) plus an opt-in Claude hook. There's no cross-harness push for a deadline you'd miss while *not* in a session — acceptable for v1, but worth noting for users who live in their calendar, not their terminal.

---

## The comparison spectrum in practice

An **analysis is a comparison** — one lightweight record realized as a DataLad branch + `datalad run`, groupable into a **product**. The same record spans a rigor spectrum:

| | Quick query / plot | Pre-registered comparison |
|---|---|---|
| **Trigger** | "show me X vs Y" mid-project | confirmatory hypothesis, decided up front |
| **Spec frozen?** | no — created and run on the spot | **yes — registered before execution** (`govern/preregister`) |
| **Ledger footprint** | **none** — DataLad branch only, until promoted | **an obligation** in `comparisons:` + `obligations:` |
| **How it's run** | `analyze/run-comparison` *(→ `datalad-run`)* | `analyze/run-comparison`, then checked vs the registered spec |
| **Kept?** | only if it tells the story; else pruned (STAMPED *Ephemerality*) | completing it is tracked work; deviations are reportable |
| **Grouped by** | `analyze/manage-product` (on promotion) | `analyze/manage-product` |

So a paper is a **product** that collects the comparisons worth publishing — some pre-registered and confirmatory (their obligations tick down to done), others exploratory quick queries you promoted because they turned out to matter. "The set of comparisons I still owe" is just the confirmatory obligations in the ledger; "the explorations I tried" are DataLad branches, most of which you never record.

---

## Scaffolding gaps, consolidated

Ranked by likely impact, these are the refinements most worth a hackathon's attention:

1. **De-identification tooling** — `curate/deidentify` now records and provenances the step, but no defacing, PHI-detection or date-shifting capability sits beneath it. (High risk in clinical/neuro work; the record exists, the automation does not.)
2. **Analysis-code testing** — smoke/unit tests for the scripts the `datalad` capability wraps. `scaffold-analysis` writes the script's edges and `run-comparison` records the run, but nothing checks that the analysis inside is correct.
3. **Assumption checking and sensitivity analyses** — `plan-analysis` lists what its recommendation requires and marks the list as the researcher's; no skill tests those assumptions, runs a robustness check, or applies a multiple-comparison correction.
4. **Guided pipeline parameters** — declaring expected pipelines and wiring them into Nipoppy covers selection/config; the residual gap is guided parameter choice.

*Now addressed by the refactor:* container build (`containers` plugin), comparison tracking (the rigor spectrum above), analysis scaffolding and figures (`analyze/scaffold-analysis`, whose placeholder raises rather than returning a plausible number, and `analyze/plot`, which draws only from produced outputs), STAMPED/reproducibility/compliance auditing (`govern/stamped-assess`, which reports per dimension with evidence and marks what it could not check `unassessed` rather than zero), and self-hosted distribution (`disseminate/liab-deploy`, now over the `liab` doer).

---

## Recommended process for planning a new analysis

Two things genuinely lock *early* because they shape everything downstream — **governance/compliance** (funding, ethics, data-management obligations) and the **data model** (variables, units, standards). Most *analytic* decisions do **not** need to be fixed up front: analyses are modular comparisons you add as the story develops. Plan in roughly this order:

1. **Frame the question** (`analyze/literature-search` *(planned — the one skill still unbuilt)*, meta-analysis tools) — what's known, what's the gap. *(lightweight)*
2. **Stand up governance** (`govern/init-ledger`, `govern/dmp`, `govern/ethics-track`, `project/people`) — encode obligations and credit before data exists. These genuinely lock early. `init-ledger` is for a dataset that already exists; `project/new-project` writes the ledger for a new one.
3. **Sketch the first comparison(s)** (`analyze/propose-comparison`) — outcomes, design, effect size → power/sample size.
4. **Choose your rigor mode per comparison:**
   - *Strict / confirmatory* — write the exact models and decision rules and **pre-register** (`govern/preregister`); the comparison becomes a ledger obligation, and later changes are reportable deviations.
   - *Exploratory / flexible (common)* — skip the prereg gate; `analyze/propose-comparison` as a quick query, `project/log-decision` as you go, and promote to a **product** the ones worth publishing (`analyze/manage-product`).
5. **Initialize** (`project/new-project`, optionally `--with-liab`) — scaffold the dataset, environment/container, expected preprocessing pipelines, and (optionally) self-hosted infra.
6. Proceed through Curate → Analyze → …, adding comparisons non-linearly (DataLad branches) and grouping the ones worth publishing into products.

### When each decision must be finalized

| Decision | Finalize by | Recorded in | Why it locks there |
|----------|-------------|-------------|--------------------|
| Hypotheses, primary/secondary outcomes | **Stage 0** *(if pre-registering)* | prereg + ledger `registration` / `comparisons` | Defines everything downstream; changing later = deviation |
| Inclusion/exclusion, stopping rules | **Stage 0** *(if pre-registering)* | prereg | Must precede data collection |
| Confirmatory model spec, covariates, corrections | **Stage 0** *(if pre-registering)* | `comparisons` (confirmatory) | Separates confirmatory from exploratory |
| Sample size / power | **Stage 0** | `analyze/propose-comparison` output | Determines feasibility & cost |
| Data-management & sharing obligations | **Stage 0** | ledger `dmp` | Funder-mandated; sets later deadlines |
| Ethics scope & de-identification approach | **Stage 0–2** | ledger `ethics` | Gates what data may exist/leave |
| Tech stack, env, container, naming conventions | **Stage 1** | `project/new-project` / `containers` | Cheap now, expensive to change after data lands |
| Self-hosted infra (Lab-in-a-Box) | **Stage 1** *(optional)* or **Stage 8** | ledger `infrastructure` | Set up early for data sovereignty, or stand up at distribution |
| Variable definitions, units, data dictionary | **Stage 2** | `curate/gen-data-dict` + annotations | Must be stable before analysis runs |
| Missingness/outlier handling rules | **Stage 2–3** | decision log | Ideally pre-specified; otherwise log as analytic choice |
| Software/package versions | **Stage 3** | container digest / lockfile | Pinned so results reproduce |
| Which quick queries become products | **Stage 3–5** | `analyze/manage-product` | Promote only what tells the story |
| Final result set & sensitivity analyses | **Stage 5** | `analyze/gen-report` + decision log | After interpretation, before publication |
| Dataset version, license, DOI, access level | **Stage 6–7** | `disseminate/dataset-release` / `dataset_description.json` | At the point of sharing |
| Target journal, reporting guideline, author order | **Stage 8** | ledger `products` + `disseminate/submission-track` *(planned)* | At write-up; affects format & credit |
| Which living artifacts to produce (article, agent bundle, Lab-in-a-Box) | **Stage 8** | ledger `products` | Depends on a stable, reproducible pipeline existing first |

**Rule of thumb:** if a decision changes a *compliance obligation* or the *data model* (variables, units, standards), finalize it early — before data lands. Pre-registration additionally locks the confirmatory analysis plan, but that's an *optional* mode. Analytic and interpretive decisions can be made — and added as new comparisons — as the work develops; just `project/log-decision` when you make them.
