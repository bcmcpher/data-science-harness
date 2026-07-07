# Reviews and meta-analyses

Specialized guidance for the two synthesis article types, kept distinct from primary research
articles ([`article-anatomy.md`](article-anatomy.md)). Section-, paragraph-, and sentence-level
craft still apply — see [`prose-craft.md`](prose-craft.md), especially the "never start a
paragraph with a name" and "claim vs proof" rules, which matter most in reviews.

Sources: Baumeister (2013) for narrative/literature reviews; Müller et al. (2018) for
neuroimaging meta-analysis; Kent et al. (2026) for reproducible meta-analysis tooling; plus the
community reporting standards (PRISMA, PROSPERO, MOOSE).

---

## 1. Choose the review type first

Decide **what kind of review** before writing (Baumeister 2013):

- **Narrative / literature review** — qualitative synthesis. Best when combining studies that use
  **different methods, measures, and questions**, or when the goal is to **build or evaluate a
  theory** that links diverse strands of work.
- **Meta-analysis** — quantitative combination of results. Best when many studies address the
  **same question with comparable methods**, so effects can be pooled on a common scale.

They serve different goals; neither is inherently superior. Meta-analysis gives precision;
narrative review can integrate methodological diversity that meta-analysis cannot yet formally
combine (Baumeister 2013).

---

## 2. Narrative / literature reviews (Baumeister 2013)

### Purpose — a review has a thesis, not just a summary
A literature review must **advance the field's understanding** — propose a new theory that links
findings, or evaluate a theory against the weight of evidence. "Simply providing a list and
summary of findings on some topic is not enough" and tends to be unpublishable (Baumeister 2013).
Everything in the paper should connect to an explicit **take-home message** stated in the
Abstract and General Discussion.

### Structure — theory first, then evidence organized by the theory
Plan the paper like an empirical report: **present the theory/framework first, then the review of
findings organized by that framework, then a General Discussion** of what was learned
(Baumeister 2013). Do **not** organize paper-by-paper in the order you happened to read them —
organize by **ideas** (e.g., if the theory has three steps, group findings under those steps).

### Searching the literature — and reporting the search
- Be **thorough**; you lose credibility if readers can name a missing key study.
- **Track and report** the search in the manuscript: databases, keywords, and restrictions
  (dates, journals). For new concepts, keyword search may fail and you fall back to reading whole
  journals and chasing citations — the obligation to be thorough remains (Baumeister 2013).

### Stance — stay open-minded; let the literature surprise you
- Reviewers should be **more flexible than experimentalists**; a rigid prior hypothesis biases the
  review. Be willing to revise your theory as you read (Baumeister 2013).
- **Value null findings** — a review is not endangered by null results the way a single study is;
  including unpublished theses/dissertations partly counters the file-drawer problem.
- **Methodological convergence is powerful**: five studies reaching one conclusion via *different*
  methods is far stronger than five using the *same* method (which may repeat a shared bias).
  Always discuss the methodological diversity of the evidence.

### Four possible conclusions of a review
A review can conclude far more than a single study can (Baumeister 2013):
1. The theory/hypothesis is **correct** (well supported; treat as true pending contrary evidence).
2. The hypothesis is the **current best guess** (tentative; burden of proof shifts to challengers).
3. The evidence is **inconclusive** — "we simply don't know yet" (valuable: flags an assumed-settled
   issue as open, and calls for better research).
4. The hypothesis is **false** (evidence consistently failed to support it).

### Be critical, and hunt for counterexamples
- Provide a **summary critique** of the evidence, ideally at the end of each subsection; evaluate
  strengths *and* weaknesses before deciding how strong a conclusion is warranted (Baumeister 2013).
- Deliberately **search for exceptions and counterexamples** late in the project to counter
  confirmation bias; this often improves the theory itself. Be frank about limitations — editors
  distrust overstated conclusions.

### Tell readers where to go
Close (usually in the General Discussion) with **explicit priorities for future research** — which
evidence is strong, which is weak, what to study next. This is a core service a review provides
and a reason it gets cited (Baumeister 2013).

### Common review errors (Baumeister 2013)
- **Uncertain purpose** — summarizing instead of advancing a theory.
- **Vague introduction / poor organization** — not spelling out the goal and theory up front;
  organizing paper-by-paper instead of by ideas.
- **Not enough information** — stating what a study concluded without how it reached that
  conclusion (a review's evidence *is* the prior literature, so it must be characterized).
- **Failing to connect to the take-home** — presenting studies "on their own terms" without saying
  how each bears on the theory; *everything in the paper should refer to the take-home*.
- **Forgetting to criticize** — especially when defending a favored theory.
- **Name-first paragraphs** — see [`prose-craft.md`](prose-craft.md).

---

## 3. Systematic reviews & meta-analyses — general standards

Independent of domain, a rigorous quantitative synthesis should:
- **Pre-register the protocol** (research question, inclusion/exclusion, planned analyses) on
  **PROSPERO** (or equivalent) *before* the search, to constrain researcher degrees of freedom and
  prevent post-hoc p-hacking (Müller et al. 2018).
- **Report to a standard**: **PRISMA** (Preferred Reporting Items for Systematic reviews and
  Meta-Analyses) — including the **PRISMA flow diagram** of records identified → screened →
  included, with counts and exclusion reasons. Use **MOOSE** for meta-analyses of observational
  studies.
- **Address publication bias / the file-drawer problem** — significant results are preferentially
  published; assess bias (e.g., funnel plots for effect-size meta-analyses) and consider grey
  literature (Müller et al. 2018).

---

## 4. Neuroimaging meta-analysis — Müller et al. (2018) "Ten simple rules"

Coordinate-based meta-analysis (**CBMA**) pools the reported x,y,z peak coordinates across studies
to test where activation **converges** more than chance; image-based meta-analysis (**IBMA**) pools
full statistical images and preserves direction/magnitude (Salimi-Khorshidi et al. 2009). Common
CBMA algorithms: **ALE** (activation likelihood estimation), **(M)KDA**, **GPR**, and
**SDM/ES-SDM** (signed differential mapping, which can combine coordinates + images). The ten
rules:

1. **Be specific about the research question** — precisely define the process of interest and the
   paradigms/contrasts to include; inclusion/exclusion criteria follow from it.
2. **Consider power** — too few experiments cannot detect smaller effects and lets a few studies
   drive the result. For ALE, simulation recommends including **≥ ~17–20 experiments** (Eickhoff
   et al. 2016); the exact number depends on expected effect size. Balance homogeneity against power.
3. **Collect and organize the data** — systematic search (PubMed, Web of Science, Google Scholar,
   and databases like BrainMap/Neurosynth); extract coordinates, sample size, and inference space;
   **build a table of every included experiment's meta-data**.
4. **Same search coverage & reference space** — include only **whole-brain** experiments (exclude
   ROI/SVC analyses and partial-brain coverage, which violate the whole-brain null and inflate
   significance); **convert all coordinates to one space** (MNI or Talairach), accounting for the
   template/transform used.
5. **Adjust for multiple contrasts** — multiple contrasts from the *same subjects* create
   dependence; pool/average within-group contrasts into one per study, or include only one
   representative contrast (Turkeltaub et al. 2012).
6. **Double-check the data and report how** — have **two investigators** independently check
   inclusion and extract/verify coordinates and space (reduces selection bias and sign/transform
   errors); avoid error-prone copy-paste from PDFs.
7. **Plan analyses beforehand and register** — pre-specify all choices and criteria; **register on
   PROSPERO**; mark any post-hoc/unplanned analysis as such in the paper.
8. **Balance sensitivity vs. false positives** — correct for multiple comparisons: for ALE,
   **cluster-level FWE** (voxel-forming *p* < 0.001, cluster *p* < 0.05) is recommended; for
   ES-SDM, an uncorrected *p* = 0.005 with cluster extent ~10 and SDM-Z > 1 approximates corrected
   results. Specify the error-control strategy a priori.
9. **Show diagnostics** — post-hoc analyses on the convergence clusters: **contribution analysis**
   (how much each experiment drives a cluster), **funnel plots**, and heterogeneity (**I²**,
   meta-regression, usually for ES-SDM). Treat post-hoc cluster interpretations as exploratory.
10. **Be transparent in reporting** — report the research question, full inclusion/exclusion
    criteria and their motivation, the **flow chart**, the **number of experiments** in each
    (sub-)analysis, a **table of every included experiment** (subjects, task, stimuli, contrast,
    coordinate space, source), handling of multiple contrasts, and any author-supplied data not in
    the original paper. Provide detailed reporting as supplementary material; **share results**
    (e.g., ANIMA, NeuroVault).

**Interpretation caveat:** CBMA tests **spatial convergence**, so significant effects mean "studies
consistently report activation here," **not** stronger activation/gray-matter change — interpret
CBMA (and CBMA contrasts) as *convergence*, not magnitude. IBMA/ES-SDM preserve direction and may
be interpreted as increase/decrease (Müller et al. 2018).

**Müller Table 1 is a fill-in checklist** for exactly these items — adopt it directly (see the
`reporting-checklist` skill in [`SPEC.md`](SPEC.md)).

---

## 5. Reproducible meta-analysis tooling (Kent et al. 2026)

Manual neuroimaging meta-analyses are time-intensive and often irreproducible due to idiosyncratic
workflows. **Neurosynth Compose** is a web platform for **transparent, reproducible** meta-analyses
that operationalizes the rules above (Kent et al. 2026):
- **Study curation & annotation** in a UI that **adheres to PRISMA**; backed by **NeuroStore**
  (>30,000 studies with pre-extracted coordinates).
- Meta-analytic models specified in the **NiMADS** standard and executed via the **NiMARE** Python
  library (diverse coordinate- and image-based algorithms — ALE, (M)KDA, SDM, IBMA).
- Analyses run **locally or in the cloud** via portable execution bundles; results upload back for
  **interactive review and sharing** — enabling crowdsourced annotation and **"living" syntheses**
  that update as new studies appear.

**Harness tie-in.** This is the concrete backing for the project's `analyze/literature-search`
meta-analysis connection point (README references NeuroSynth Compose / NiMARE) and for the *living
research product* goal: a meta-analysis authored here can be a re-executable, updatable artifact,
not a frozen table. Related tools: **BrainMap/Sleuth** (curated CBMA database), **Neurosynth**
(automated synthesis), **NeuroVault** (unthresholded statistical images for IBMA).

---

## Review / meta-analysis review checklist

**Narrative review**
- [ ] Has an explicit **take-home thesis** (advances/evaluates a theory), not just a summary.
- [ ] Organized **by ideas/theory**, not paper-by-paper; every finding connects to the take-home.
- [ ] Search reported (databases, keywords, restrictions); thorough coverage.
- [ ] Discusses **methodological convergence/diversity**; includes null/unpublished where possible.
- [ ] States which of the **four conclusion types** it reaches.
- [ ] Contains a **summary critique** and a deliberate **counterexample** search; frank about limits.
- [ ] Ends with explicit **future-research priorities**.

**Meta-analysis (esp. neuroimaging)**
- [ ] Specific research question; inclusion/exclusion pre-specified and motivated.
- [ ] Protocol **registered (PROSPERO)**; **PRISMA** flow diagram; **≥~17–20** experiments for ALE.
- [ ] Whole-brain only; ROI/SVC/partial-coverage excluded; all coordinates in **one space**.
- [ ] Within-subject multiple contrasts handled; data **double-checked by two people**.
- [ ] Multiple-comparison correction specified a priori (ALE: cluster-FWE, voxel *p*<0.001).
- [ ] **Diagnostics** shown (contribution/funnel/heterogeneity); post-hoc labeled exploratory.
- [ ] Full **table of included experiments**; results **shared**; CBMA interpreted as convergence.
- [ ] Tooling supports reproducibility (Neurosynth Compose / NiMARE / NiMADS where applicable).
