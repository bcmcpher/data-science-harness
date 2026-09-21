# CONSORT 2025 (reference)

Reporting guideline for **randomised trials**. 30 items.

**CONSORT 2025 supersedes CONSORT 2010**, which its authors state should no longer be used. If a
journal's instructions still name CONSORT 2010, report against 2025 and say which version was used —
2025 adds seven items, revises three and removes one, and the additions are mostly open-science
items (registration, protocol and SAP access, data sharing, declarations) that this harness can
evidence directly from the ledger.

> **Transcribed, not summarised.** The checklist below is reproduced verbatim from the source named
> in *Provenance*, which is openly licensed. It is wrapped as that source's PDF renders it: where the
> typesetter broke a word across lines, the break is left in place, because rejoining it is an edit
> and this file's value is that it is not edited. Nothing has been added, reordered or paraphrased.

## Provenance

Hopewell S, Chan A-W, Collins GS, Hróbjartsson A, Moher D, Schulz KF, et al. CONSORT 2025
statement: Updated guideline for reporting randomised trials. *PLOS Medicine* 2025;22(4):e1004587.
<https://doi.org/10.1371/journal.pmed.1004587> — Table 1.

**Redistribution basis:** the PLOS Medicine version is open access under the Creative Commons
Attribution License: *"Copyright: © 2025 Hopewell et al. This is an open access article distributed
under the terms of the Creative Commons Attribution License, which permits unrestricted use,
distribution, and reproduction in any medium, provided the original author and source are
credited."* CONSORT 2025 was published simultaneously in several journals; **this file derives from
the PLOS Medicine version specifically**, because that is the one whose licence permits
redistribution. Verified 2026-09-18.

## Checklist

```
Table 1. CONSORT 2025 checklist of information to include when reporting a randomised trial.
Section/topic        No CONSORT 2025 checklist item description
Title and abstract
Title and struc-     1a   Identification as a randomised trial
tured abstract       1b Structured summary of the trial design, methods, results, and conclusions
Open science
Trial registration 2      Name of trial registry, identifying number (with URL) and date of registration
Protocol and         3    Where the trial protocol and statistical analysis plan can be accessed
statistical analysis
plan
Data sharing         4    Where and how the individual de-identified participant data (including data dictionary),
                          statistical code and any other materials can be accessed
Funding and          5a   Sources of funding and other support (e.g., supply of drugs), and role of funders in the design,
conflicts of              conduct, analysis and reporting of the trial
interest             5b Financial and other conflicts of interest of the manuscript authors
Introduction
Background and 6          Scientific background and rationale
rationale
Objectives           7    Specific objectives related to benefits and harms
Methods
Patient and pub- 8        Details of patient or public involvement in the design, conduct and reporting of the trial
lic involvement
Trial design         9    Description of trial design including type of trial (e.g., parallel group, crossover), allocation
                          ratio, and framework (e.g., superiority, equivalence, non-inferiority, exploratory)
Changes to trial     10 Important changes to the trial after it commenced including any outcomes or analyses that
protocol                were not prespecified, with reason
Trial setting        11 Settings (e.g., community, hospital) and locations (e.g., countries, sites) where the trial was
                        conducted
Eligibility criteria 12a Eligibility criteria for participants
                     12b If applicable, eligibility criteria for sites and for individuals delivering the interventions (e.g.,
                         surgeons, physiotherapists)
Intervention and 13 Intervention and comparator with sufficient details to allow replication. If relevant, where
comparator          additional materials describing the intervention and comparator (e.g., intervention manual)
                    can be accessed
Outcomes             14 Prespecified primary and secondary outcomes, including the specific measurement variable
                        (e.g., systolic blood pressure), analysis metric (e.g., change from baseline, final value, time to
                        event), method of aggregation (e.g., median, proportion), and time point for each outcome
Harms                15 How harms were defined and assessed (e.g., systematically, non-systematically)
Sample size          16a How sample size was determined, including all assumptions supporting the sample size
                         calculation
                     16b Explanation of any interim analyses and stopping guidelines
Randomisation:
Sequence             17a Who generated the random allocation sequence and the method used
generation           17b Type of randomisation and details of any restriction (e.g., stratification, blocking and block
                         size)
Allocation           18 Mechanism used to implement the random allocation sequence (e.g., central computer/tele-
concealment             phone; sequentially numbered, opaque, sealed containers), describing any steps to conceal the
mechanism               sequence until interventions were assigned
Implementation       19 Whether the personnel who enrolled and those who assigned participants to the interventions
                        had access to the random allocation sequence
Blinding             20a Who was blinded after assignment to interventions (e.g., participants, care providers, outcome
                         assessors, data analysts)
                     20b If blinded, how blinding was achieved and description of the similarity of interventions

                                                                                                                   (Continued)

Table 1. (Continued)

Section/topic     No CONSORT 2025 checklist item description
Statistical       21a Statistical methods used to compare groups for primary and secondary outcomes, including
methods               harms
                  21b Definition of who is included in each analysis (e.g., all randomised participants), and in which
                      group
                  21c How missing data were handled in the analysis
                  21d Methods for any additional analyses (e.g., subgroup and sensitivity analyses), distinguishing
                      prespecified from post hoc
Results
Participant flow, 22a For each group, the numbers of participants who were randomly assigned, received intended
including flow        intervention, and were analysed for the primary outcome
diagram           22b For each group, losses and exclusions after randomisation, together with reasons
Recruitment       23a Dates defining the periods of recruitment and follow-up for outcomes of benefits and harms
                  23b If relevant, why the trial ended or was stopped
Intervention      24a Intervention and comparator as they were actually administered (e.g., where appropriate,
and comparator        who delivered the intervention/comparator, how participants adhered, whether they were
delivery              delivered as intended (fidelity))
                  24b Concomitant care received during the trial for each group
Baseline data     25 A table showing baseline demographic and clinical characteristics for each group
Numbers anal-     26 For each primary and secondary outcome, by group:• the number of participants included
ysed, outcomes          in the analysis
and estimation       • the number of participants with available data at the outcome time point
                     • result for each group, and the estimated effect size and its precision (such as 95% confi-
                        dence interval)
                     • for binary outcomes, presentation of both absolute and relative effect size
```

## What this harness can evidence

Items 2, 3, 4 and 5a (registration, protocol/SAP access, data sharing, funding) are answerable from
`project.yaml` — `obligations[]` carries the registration, `products[]` the released dataset and its
identifier. Pre-fill those and leave the trial-conduct items to the author. Nothing here judges
whether an item is *adequately* reported; that is a reviewer's call.
