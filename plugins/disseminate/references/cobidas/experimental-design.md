# COBIDAS — Table D.1 — Experimental Design Reporting

Neuroimaging (MRI) reporting items. Use **alongside** the design guideline, not instead of it: an
observational fMRI study reports against STROBE *and* COBIDAS.

> **Transcribed, not summarised.** Reproduced verbatim from the openly licensed source named below,
> wrapped as its PDF renders it. Nothing has been added, reordered or paraphrased.

## Provenance

Nichols TE, Das S, Eickhoff SB, Evans AC, Glatard T, Hanke M, et al. Best Practices in Data Analysis
and Sharing in Neuroimaging using MRI. *bioRxiv* 054262 (v2, 2017); published as *Nat Neurosci*
2017;20(3):299-303, <https://doi.org/10.1038/nn.4500>. The committee report is
**OHBM COBIDAS Report v1.0, 2016/5/19**; the tables below are from its Appendix D, *Itemized lists of
best practices and reporting items*.

**Redistribution basis:** the bioRxiv preprint (<https://doi.org/10.1101/054262>) is *"made available
under a CC-BY 4.0 International license."* **This file derives from the preprint, not from the Nature
Neuroscience version**, which is not openly licensed. Verified 2026-09-18.

The `Mandatory` column is the report's own: `Y` marks an item it considers crucial — *"a published
work cannot be considered complete without such information"* — `N` an item to strive for. A blank
cell is a section heading rather than an item.

## Items

```
Table D.1. Experimental Design Reporting

Aspect                            Notes                                                                                 Mandatory

Number of subjects                Elaborate each by group if have more than one group.

Subjects approached                                                                                                     N

Subjects consented                                                                                                      N

Subjects refused to participate   Provide reasons.                                                                      N

Subjects excluded                 Subjects excluded after consenting but before data acquisition; provide reasons.      N

Subjects participated and         Provide the number of subjects scanned, number excluded after acquisition, and        Y
analyzed                          the number included in the data analysis. If they differ, note the number of
                                  subjects in each particular analysis.

Inclusion criteria and            Elaborate each by group if have more than one group.
descriptive statistics

Age                               Mean, standard deviation and range.                                                   Y

Sex                               Absolute counts or relative frequencies.                                              Y

Race & ethnicity                  Per guidelines of NIH or other relevant agency.                                       N

Education, SES                    Education is essential for studies comparing patient and control groups; complete     Y
                                  SES reporting less important for single­group studies, but still useful.
                                  Specify measurement instrument used; may be parental SES and education if
                                  study has minors.

IQ                                Specify measurement instrument used.                                                  N





Handedness                 Absolute or relative frequencies; basis of handedness­attribution (self­report, EHI,        Y
                           other tests). (Important for fMRI, may be less important for structural studies.)

Exclusion criteria         Describe any screening criteria, including those applied to “normal” sample such            Y
                           as MRI exclusion criteria.

Clinical criteria          Detail the area of recruitment (in­ vs. outpatient setting, community hospital vs.          Y
                           tertiary referral center etc.) as well as whether patients were currently in treatment.

Clinical instruments       Describe the instruments used to obtain the diagnosis and provide tests of intra­ or        Y
                           inter­rater reliability. Clarify whether a “clinical diagnosis” or “inventory diagnosis”
                           was used (if applicable). State the diagnostic system (ICD, DSM etc) that was
                           used.

Matching strategy          If applicable.                                                                              Y

Population & recruitment   Population from which subjects were drawn, and how and where recruitment took               Y
strategy                   place, e.g., schools, clinics, etc. If possible, note if subjects are research­naive or
                           have participated in other studies before.

Subject scanning order     With multiple groups, information on ordering and or balance over time; especially          Y
                           report relative to scanner changes/upgrades. (Ideally, use randomized or
                           interleaved order to avoid bias due to scanner changes/upgrades.)

Neurocognitive measures    All measures collected on subjects should be described and reported.                        Y

Ethical considerations

Ethical approval           Describe approval given, including the particular institutional review board,               Y
                           medical ethics committee or equivalent that granted the approval. When data is
                           shared, describe the ethics/institutional approvals required from either the author
                           (source) or recipient.

Informed consent           Record whether subjects provided informed consent or, if applicable, informed               Y
                           assent.





Design specifications

Design type                   Task or resting state. Event­related or block design. (See body text for usage of           Y
                              ‘block design’ terminology.)

Condition & stimuli           Clearly describe each condition and the stimuli used. Be sure to completely                 Y
                              describe baseline (e.g. blank white/black screen, presence of fixation cross, or any
                              other text), especially for resting­state studies. When possible provide images or
                              screen snapshots of the stimuli.

Number of blocks, trials or   Specify per session, and if differing by subject, summary statistics (mean, range           Y
experimental units            and/or standard deviation) of such counts.

Timing and duration           Length of each trial or block (both, if trials are blocked), and interval between trials.   Y
                              Provide the timing structure of the events in the task, whether a random/jittered
                              pattern or a regular arrangement; any jittering of block onsets.

Length of the experiment      Describe the total length of the scanning session, as well as the duration of each          Y
                              run. (Important to assess subject fatigue.)

Design optimization           Whether design was optimized for efficiency, and how.                                       Y

Presentation software         Name software, version and operating system on which the stimulus presentation              Y
                              was run. When possible, provide code used to drive experiment.

Task specification

Condition                     Enumerate the conditions and fully describe and reference each. Consider using a            Y
                              shorthand name, e.g. AUDSTIM, VISSTIM, to refer to each condition, to clarify the
                              distinction between a specific modeled effect and a psychological construct.
                              Naming should reflect the distinction between instruction periods and actual
                              stimuli, and between single parameters and contrasts of parameters.

Instructions                  Specify the instructions given to subjects for each condition (ideally the exact text       Y
                              in supplement or appendix). For resting­state, be sure to indicate eyes­closed,





                          eyes­open, any fixation. Describe if the subjects received any rewards during the
                          task, and state if there was a familiarization / training inside or outside the
                          scanner.

Stimuli                   Specifics of stimuli used in each run. For example, the unique number of stimuli        Y
                          used, and whether/how stimuli were repeated over trials or conditions.

Randomization             Describe block or event ordering as deterministic, or report manner of                  Y
                          randomization, in terms of order and timing. If pseudo­randomized, i.e. under
                          constraints, describe how and the criteria used to constrain the orders/timings.

Stimulus presentation &   Specify the presentation hardware (e.g. back projection, in­room display, goggles,      Y
response collection.      etc), and the response systems (e.g. button boxes, eye tracking, physiology).
                          Note how equipment was synched to the scanner (e.g. scanner TTL, or manual
                          sync.)

Run order                 Order in which tasks runs are conducted in the scanner.                                 Y

Power analysis

Outcome                   Specify the type of outcome used as the basis of power computations, e.g. signal        Y
                          in a pre­specified ROI, or whole image voxelwise (or cluster­wise, peak­wise, etc.).

Power parameters          Specify                                                                                 Y
                             ● Effect size (or effect magnitude and standard deviation separately).
                             ● Source of predicted effect size (previous literature with citation; pilot data
                                 with description, etc).
                             ● Significance level (e.g. uncorrected alpha 0.05 for an ROI, or
                                 FWE­corrected significance
                             ● Target power (typically 80%).
                             ● Any other parameters set (e.g., for spatial methods a brain volume and
                                 smoothness may be needed to be specified).

Behavioral performance





Variables recorded          State number of type of variables recorded (e.g. correct button press, response        Y
                            time).

Summary statistics          Summaries of behavior sufficient to establish that subjects were performing the        Y
                            task as expected. For example, correct response rates and/or response times,
                            summarized over subjects (e.g. mean, range and/or standard deviation).
```
