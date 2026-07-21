# EQUATOR reporting guidelines (reference)

Pick the guideline by **study design**. The EQUATOR Network catalogues reporting guidelines; the
common ones (plus COBIDAS for neuroimaging) are below. Each is a checklist of items a paper of that
design should report.

| Study design | Guideline | Scope |
|---|---|---|
| Randomized controlled trial | **CONSORT** | trial design, randomization, flow diagram, outcomes |
| Observational (cohort/case-control/cross-sectional) | **STROBE** | setting, participants, variables, bias, results |
| Systematic review / meta-analysis | **PRISMA** | search, selection flow, synthesis, risk of bias |
| Animal (in vivo) research | **ARRIVE** | animals, housing, sample size, randomization, blinding |
| Diagnostic accuracy | **STARD** | index test, reference standard, flow, estimates |
| Prediction model | **TRIPOD** | predictors, model building, validation, performance |
| Case report | **CARE** | timeline, diagnostics, intervention, outcome |
| **Neuroimaging methods reporting** | **COBIDAS** (neuro pack) | acquisition, preprocessing, modeling, inference, sharing |

## Notes
- **COBIDAS** (Committee on Best Practices in Data Analysis and Sharing) is the neuroimaging-specific
  companion — use it *alongside* the design guideline (e.g. STROBE + COBIDAS for an observational
  fMRI study) to cover acquisition/preprocessing/modeling/inference reporting.
- Several items are provenance-evidenced by this harness: data & code availability (ledger DOIs +
  DataLad), analysis reproducibility (`datalad run` records), and pre-registration (`obligations[]`).
  Pre-fill those; leave design/clinical items to the author.
- Canonical source: the EQUATOR Network library and each guideline's official checklist/explanation.
