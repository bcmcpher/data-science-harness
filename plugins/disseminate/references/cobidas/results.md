# COBIDAS — Table D.5 — Results Reporting

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
Table D.5. Results Reporting

Aspect                             Notes/Ontology                                                                               Mandatory

Mass univariate analysis

Effects tested                     Provide a complete list of tested and omitted effects.                                       Y

Extracted data                         ●   Define how voxels/elements were selected; if region is based on the same             Y
                                           data, clarify how circularity was accounted for.
                                       ●   For any summary reported, give units. Ideally these are as interpretable as
                                           possible (e.g. percent change).
                                                          2​
                                       ●   If reporting R​ (coefficient of determination) clarify how nuisance variability
                                           is considered. For instance, in task fMRI the vast majority of variance is
                                                                                     2​
                                           explained by slow temporal drift, and R​   values for an effect of interest will
                                           be vastly different if computed with or without counting drift in the total
                                           variance.

Tables of coordinates              Provide one table of coordinates including:                                                  Y
                                      ● Contrast / effect to which it refers.
                                      ● XYZ coordinate (with coordinate system, MNI, Talairach, noted in caption;
                                          also clarify whether peak or center­of­mass location).
                                      ● Anatomical region (in caption or body text, describe source of labels, e.g.
                                          subjective, atlas, etc).





                         ●   P­value forming basis of inference (e.g. voxel­wise FWE corrected P; or
                             cluster­wise FDR corrected P).
                         ●   T/Z/F statistic (with degrees of freedom in table caption)
                         ●   In caption, state whether coordinates are from whole brain, or from a
                             specific constrained volume.
                                                                                                  3​
                         ●   If cluster­wise inference is used, the cluster size. Report in mm​     or, if in
                             voxels, be explicit about the size of voxels. If a cluster statistic other than
                             size is used (e.g. mass) it should be listed as well.
                         ●   In caption or body text, note criterion for peak per cluster reporting; e.g.
                             “one peak per cluster listed”, or “up to 3 per cluster that are at least 8mm
                             apart” (SPM default), etc.

Thresholded maps      For each effect, provide images of maps of significant regions, ensuring that each          N
                      caption describes:
                         ● Type of inference and the correction method, as well as form of any
                             sub-volume corrections applied when computing corrected significance.
                         ● Include color bars; when presenting multiple maps in a figure, use a
                             common color bar to ensure the results are comparable.

Unthresholded maps    Share, via supplementary material or repository:                                            Y
                         ● Unthresholded statistic maps.
                         ● Optionally, the thresholded statistic maps.
                         ● Optionally, the effect size map (e.g. % BOLD change, % GM change).

Extracted data        State whether data extracted from an ROI (e.g. to compute an effect size) is                Y
                      defined based on independent data, as otherwise it is susceptible to bias.
                      If ROIs are circularly defined, best not to provide any statistical summary (i.e.
                                  2​
                      P­values, R​ , etc).

Spatial features      Report the                                                                                  Y
                         ● Size of the analysis volume in voxels, mm.
                         ● Spatial smoothness of noise (e.g. FWHM) and Resel count (if using
                             Random Field Theory).





Functional connectivity

ICA analyses                      Report the total number of components (especially when estimated from the data       Y
                                  and not fixed). Report the number of these analyzed and the reason for their
                                  selection.

Graph analyses: Null hypothesis   For graph­based methods, carefully state what is the null hypothesis of the test     Y
tested                            and how the statistic distribution under the null is computed.

Multivariate modelling &
predictiveanalysis

Optimised evaluation metrics      Report the values obtained for the evaluation metrics chosen (see Evaluation         Y
                                  Metrics, above), as well as any P­values to justify above­chance performance.
```
