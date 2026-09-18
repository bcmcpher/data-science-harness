# ARRIVE 2.0 (reference)

Reporting guideline for **animal (in vivo) research**. Two sets: the **Essential 10** (items 1–10),
the minimum without which a reader cannot assess reliability, and the **Recommended Set** (items
11–21), which adds context. Together they are best reporting practice.

> **Transcribed, not summarised.** The checklist below is reproduced verbatim from the source named
> in *Provenance*, which is openly licensed. It is wrapped as that source's PDF renders it: where the
> typesetter broke a word across lines, the break is left in place, because rejoining it is an edit
> and this file's value is that it is not edited. Nothing has been added, reordered or paraphrased.

## Provenance

Percie du Sert N, Hurst V, Ahluwalia A, Alam S, Avey MT, Baker M, et al. The ARRIVE guidelines 2.0:
Updated guidelines for reporting animal research. *PLOS Biology* 2020;18(7):e3000410.
<https://doi.org/10.1371/journal.pbio.3000410> — Tables 1 and 2.

**Redistribution basis:** *"This is an open access article, free of all copyright, and may be freely
reproduced, distributed, transmitted, modified, built upon, or otherwise used by anyone for any
lawful purpose."* The per-item Explanation and Elaboration is a separate PLOS Biology article
(<https://doi.org/10.1371/journal.pbio.3000411>, CC BY) and is **not** bundled here. The checklist
PDFs on <https://arriveguidelines.org> carry only *"© NC3Rs"* with no licence statement; this file
derives from the PLOS Biology article. Verified 2026-09-18.

## Checklist

```
Table 1. ARRIVE Essential 10.
                                                    ARRIVE Essential 10
Study design                 1    For each experiment, provide brief details of study design including:
                                  a. The groups being compared, including control groups. If no control group has
                                  been used, the rationale should be stated.
                                  b. The experimental unit (e.g., a single animal, litter, or cage of animals).
Sample size                  2    a. Specify the exact number of experimental units allocated to each group, and the
                                  total number in each experiment. Also indicate the total number of animals used.
                                  b. Explain how the sample size was decided. Provide details of any a priori sample
                                  size calculation, if done.
Inclusion and exclusion      3    a. Describe any criteria used for including and excluding animals (or experimental
criteria                          units) during the experiment, and data points during the analysis. Specify if these
                                  criteria were established a priori. If no criteria were set, state this explicitly.
                                  b. For each experimental group, report any animals, experimental units, or data
                                  points not included in the analysis and explain why. If there were no exclusions,
                                  state so.
                                  c. For each analysis, report the exact value of n in each experimental group.
Randomisation                4    a. State whether randomisation was used to allocate experimental units to control
                                  and treatment groups. If done, provide the method used to generate the
                                  randomisation sequence.
                                  b. Describe the strategy used to minimise potential confounders such as the order
                                  of treatments and measurements, or animal/cage location. If confounders were not
                                  controlled, state this explicitly.
Blinding                     5    Describe who was aware of the group allocation at the different stages of the
                                  experiment (during the allocation, the conduct of the experiment, the outcome
                                  assessment, and the data analysis).
Outcome measures             6    a. Clearly define all outcome measures assessed (e.g., cell death, molecular markers,
                                  or behavioural changes).
                                  b. For hypothesis-testing studies, specify the primary outcome measure, i.e., the
                                  outcome measure that was used to determine the sample size.
Statistical methods          7    a. Provide details of the statistical methods used for each analysis, including
                                  software used.
                                  b. Describe any methods used to assess whether the data met the assumptions of the
                                  statistical approach, and what was done if the assumptions were not met.
Experimental animals         8    a. Provide species-appropriate details of the animals used, including species, strain
                                  and substrain, sex, age or developmental stage, and, if relevant, weight.
                                  b. Provide further relevant information on the provenance of animals, health/
                                  immune status, genetic modification status, genotype, and any previous
                                  procedures.
Experimental procedures      9    For each experimental group, including controls, describe the procedures in
                                  enough detail to allow others to replicate them, including:
                                  a. What was done, how it was done, and what was used.
                                  b. When and how often.
                                  c. Where (including detail of any acclimatisation periods).
                                  d. Why (provide rationale for procedures).
Results                      10 For each experiment conducted, including independent replications, report:
                                a. Summary/descriptive statistics for each experimental group, with a measure of
                                variability where applicable (e.g., mean and SD, or median and range).
                                b. If applicable, the effect size with a confidence interval.

Explanations and examples for items 1 to 10 are available in the E&E document [42] and on the website at https://

Table 2. ARRIVE Recommended Set.
                                                    Recommended Set
Abstract                         11 Provide an accurate summary of the research objectives, animal species, strain
                                    and sex, key methods, principal findings, and study conclusions.
Background                       12 a. Include sufficient scientific background to understand the rationale and
                                    context for the study, and explain the experimental approach.
                                    b. Explain how the animal species and model used address the scientific
                                    objectives and, where appropriate, the relevance to human biology.
Objectives                       13 Clearly describe the research question, research objectives and, where
                                    appropriate, specific hypotheses being tested.
Ethical statement                14 Provide the name of the ethical review committee or equivalent that has
                                    approved the use of animals in this study, and any relevant licence or protocol
                                    numbers (if applicable). If ethical approval was not sought or granted, provide a
                                    justification.
Housing and husbandry            15 Provide details of housing and husbandry conditions, including any
                                    environmental enrichment.
Animal care and monitoring       16 a. Describe any interventions or steps taken in the experimental protocols to
                                    reduce pain, suffering, and distress.
                                    b. Report any expected or unexpected adverse events.
                                    c. Describe the humane endpoints established for the study, the signs that were
                                    monitored, and the frequency of monitoring. If the study did not have humane
                                    endpoints, state this.
Interpretation/scientific        17 a. Interpret the results, taking into account the study objectives and hypotheses,
implications                        current theory, and other relevant studies in the literature.
                                    b. Comment on the study limitations, including potential sources of bias,
                                    limitations of the animal model, and imprecision associated with the results.
Generalisability/translation     18 Comment on whether, and how, the findings of this study are likely to
                                    generalise to other species or experimental conditions, including any relevance
                                    to human biology (where appropriate).
Protocol registration            19 Provide a statement indicating whether a protocol (including the research
                                    question, key design features, and analysis plan) was prepared before the study,
                                    and if and where this protocol was registered.
Data access                      20 Provide a statement describing if and where study data are available.
Declaration of interests         21 a. Declare any potential conflicts of interest, including financial and
                                    nonfinancial. If none exist, this should be stated.
                                    b. List all funding sources (including grant identifier) and the role of the
                                    funder(s) in the design, analysis, and reporting of the study.
```

## What this harness can evidence

Items 14 (ethical statement), 19 (protocol registration), 20 (data access) and 21b (funding) come
from `project.yaml` — `govern/ethics-track` records the approval, `govern/preregister` the protocol,
and `disseminate/dataset-release` the identifier. Item 7b — whether the data met the assumptions of
the statistical approach — is the researcher's: `analyze/plan-analysis` states assumptions and
explicitly does not check them.
