# STROBE (reference)

Reporting guideline for **observational studies** — cohort, case-control and cross-sectional. 22
items, 18 common to all three designs and four (6, 12, 14, 15) design-specific.

Items marked `*` are to be given separately for cases and controls in a case-control study, and for
exposed and unexposed groups in cohort and cross-sectional studies.

> **Transcribed, not summarised.** The checklist below is reproduced verbatim from the source named
> in *Provenance*, which is openly licensed. It is wrapped as that source's PDF renders it: where the
> typesetter broke a word across lines, the break is left in place, because rejoining it is an edit
> and this file's value is that it is not edited. Nothing has been added, reordered or paraphrased.

## Provenance

von Elm E, Altman DG, Egger M, Pocock SJ, Gøtzsche PC, Vandenbroucke JP, for the STROBE Initiative.
The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement:
guidelines for reporting observational studies. *PLoS Medicine* 2007;4(10):e296.
<https://doi.org/10.1371/journal.pmed.0040296> — Table 1.

**Redistribution basis:** the PLoS Medicine version is open access under the Creative Commons
Attribution License (*"Copyright: © 2007 von Elm et al. This is an open-access article distributed
under the terms of the Creative Commons Attribution License"*). Note that the checklist PDFs
distributed from <https://www.strobe-statement.org> carry only *"Copyright © STROBE"* with no
licence statement — **this file derives from the PLoS Medicine article, not from those PDFs.**
Verified 2026-09-18.

The design-specific versions of the checklist (separate cohort, case-control and cross-sectional
forms) are on the STROBE site and are **not** bundled here; the combined table below carries all
three variants inline, as published.

## Checklist

```
Table 1. The STROBE Statement—Checklist of Items That Should Be Addressed in Reports of Observational Studies

                            Item                                                                       Recommendation
                           number

TITLE and ABSTRACT             1         (a) Indicate the study’s design with a commonly used term in the title or the abstract
                                         (b) Provide in the abstract an informative and balanced summary of what was done and what was found

INTRODUCTION
  Background/                  2         Explain the scientific background and rationale for the investigation being reported
  rationale
  Objectives                   3         State specific objectives, including any prespecified hypotheses

METHODS
  Study design                 4         Present key elements of study design early in the paper
  Setting                      5         Describe the setting, locations, and relevant dates, including periods of recruitment, exposure, follow-up, and data collection
  Participants                 6         (a) Cohort study—Give the eligibility criteria, and the sources and methods of selection of participants. Describe methods of
                                             follow-up
                                             Case-control study—Give the eligibility criteria, and the sources and methods of case ascertainment and control selection. Give
                                             the rationale for the choice of cases and controls
                                             Cross-sectional study—Give the eligibility criteria, and the sources and methods of selection of participants
                                         (b) Cohort study—For matched studies, give matching criteria and number of exposed and unexposed
                                             Case-control study—For matched studies, give matching criteria and the number of controls per case
  Variables                    7         Clearly define all outcomes, exposures, predictors, potential confounders, and effect modifiers. Give diagnostic criteria, if applicable
  Data sources/                8*        For each variable of interest, give sources of data and details of methods of assessment (measurement).
  measurement                            Describe comparability of assessment methods if there is more than one group
  Bias                          9        Describe any efforts to address potential sources of bias
  Study size                   10        Explain how the study size was arrived at
  Quantitative                 11        Explain how quantitative variables were handled in the analyses. If applicable, describe which groupings were chosen, and why
  variables
  Statistical                  12        (a) Describe all statistical methods, including those used to control for confounding
  methods                                (b) Describe any methods used to examine subgroups and interactions
                                         (c) Explain how missing data were addressed
                                         (d) Cohort study—If applicable, explain how loss to follow-up was addressed
                                             Case-control study—If applicable, explain how matching of cases and controls was addressed
                                             Cross-sectional study—If applicable, describe analytical methods taking account of sampling strategy
                                         (e) Describe any sensitivity analyses

RESULTS
  Participants                13*        (a) Report the numbers of individuals at each stage of the study—e.g., numbers potentially eligible, examined for eligibility, con-
                                         firmed eligible, included in the study, completing follow-up, and analysed
                                         (b) Give reasons for non-participation at each stage
                                         (c) Consider use of a flow diagram
  Descriptive                 14*        (a) Give characteristics of study participants (e.g., demographic, clinical, social) and information on exposures and potential con-
  data                                   founders
                                         (b) Indicate the number of participants with missing data for each variable of interest
                                         (c) Cohort study—Summarise follow-up time (e.g., average and total amount)
  Outcome data                15*        Cohort study—Report numbers of outcome events or summary measures over time
                                         Case-control study—Report numbers in each exposure category, or summary measures of exposure
                                         Cross-sectional study—Report numbers of outcome events or summary measures
  Main results                 16        (a) Give unadjusted estimates and, if applicable, confounder-adjusted estimates and their precision (e.g., 95% confidence interval).
                                         Make clear which confounders were adjusted for and why they were included
                                         (b) Report category boundaries when continuous variables were categorized
                                         (c) If relevant, consider translating estimates of relative risk into absolute risk for a meaningful time period
  Other                        17        Report other analyses done—e.g., analyses of subgroups and interactions, and sensitivity analyses
  analyses

DISCUSSION
  Key results                  18        Summarise key results with reference to study objectives
  Limitations                  19        Discuss limitations of the study, taking into account sources of potential bias or imprecision. Discuss both direction and magnitude
                                         of any potential bias
  Interpretation               20        Give a cautious overall interpretation of results considering objectives, limitations, multiplicity of analyses, results from similar stu-
                                         dies, and other relevant evidence
  Generalisability             21        Discuss the generalisability (external validity) of the study results

OTHER INFORMATION
  Funding                      22        Give the source of funding and the role of the funders for the present study and, if applicable, for the original study on which the
                                         present article is based

*Give such information separately for cases and controls in case-control studies, and, if applicable, for exposed and unexposed groups in cohort and cross-sectional studies.
Note: An Explanation and Elaboration article discusses each checklist item and gives methodological background and published examples of transparent reporting. The STROBE checklist
is best used in conjunction with this article (freely available on the Web sites of PLoS Medicine at http://www.plosmedicine.org/, Annals of Internal Medicine at http://www.annals.org/, and
```

## What this harness can evidence

Item 22 (funding) comes from `project.yaml`. Items 8, 12 and 17 (data sources, statistical methods,
other analyses including sensitivity analyses) can point at the `cmp/*` branches and their run
records — a sensitivity analysis that was run is a comparison, and one that was not is a gap the
checklist should show rather than hide.
