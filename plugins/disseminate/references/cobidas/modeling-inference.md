# COBIDAS — Table D.4 — Statistical Modeling & Inference

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
Table D.4. Statistical Modeling & Inference

Aspect                              Notes/Ontology                                                                               Mandatory

Mass univariate analyses

Dependent variable: Data            Report the number of time points, number of subjects; specify exclusions of time             Y
submitted to statistical modeling   points / subjects, if not already specified in experimental design.

Dependent variable: Spatial         If not “Full brain”, give a specification of an anatomically or functionally defined         Y
region modeled                      mask.

Independent variables               For first level fMRI, specify:                                                               Y
                                       ● Event­related design predictors.
                                                 ○ Modeled duration, if other than zero.
                                                 ○ Parametric modulation.
                                       ● Block Design predictors.
                                                 ○ Note whether baseline was explicitly modeled.
                                       ● HRF basis, typically one of:
                                                 ○ Canonical only.
                                                 ○ Canonical plus temporal derivative.
                                                 ○ Canonical plus temporal and dispersion derivative.
                                                 ○ Smooth basis (e.g. SPM “informed” or Fourier basis; FSL’s
                                                     FLOBS).
                                                 ○ Finite Impulse Response model.
                                       ● Drift regressors (e.g. DCT basis in SPM, with specified cut­off).
                                       ● Movement regressors; specify if squares and/or temporal derivative used.
                                       ● Any other nuisance regressors, and whether they were entered as
                                             interactions (e.g. with a task effect in 1st level fMRI, or with group effect).
                                       ● Any orthogonalization of regressors, and set of other regressors used to
                                             orthogonalize against.
                                    For second level fMRI or general group model, specify:
                                       ● Group effects (patients vs. controls).





                         ●   Clearly state whether or not covariates are split by group (i.e. fit as a
                             group­by­covariate interaction).
                         ● Other between subject effects (age, sex; for VBM, total GM or ICV).
                      For group model with repeated measures, specify:
                         ● How condition effects are modeled (e.g. as factors, or as linear trends).
                         ● Whether subject effects are modeled (i.e. as regressors, as opposed to
                             with a covariance structure).

Model type            Some suggested terms include:                                                          Y
                        ● “Mass Univariate”.
                        ● “Multivariate” (e.g. ICA on whole brain data).
                        ● “Mass Multivariate” (e.g. MANOVA on diffusion or morphometry tensor
                            data).
                        ● “Local Multivariate” (e.g. “searchlight”).
                        ● “Multivariate, intra­subject predictive” (e.g. classify individual trials in
                            event­related fMRI).
                        ● “Multivariate inter­subject predictive” (e.g. classify subjects as patient vs.
                            control).
                        ● “Representational Similarity Analysis”.

Model settings        The essential details of the model. For mass­univariate, first level fMRI, these       Y
                      include:
                          ● Drift model, if not already specified as a dependent variable (e.g. locally
                             linear detrending of data & regressors, as in FSL).
                          ● Autocorrelation model (e.g. global approximate AR(1) in SPM; locally
                             regularized autocorrelation function in FSL).

                      For mass­univariate second level fMRI these include:
                         ● Fixed effects (all subjects’ data in one model).
                         ● Random or mixed­effects model, implemented with:
                                ○ Ordinary least squares (OLS, aka unweighted summary statistics
                                   approach; SPM default, FSL FEAT’s “Simple OLS”).
                                ○ weighted least squares (i.e. FSL FEAT’s “FLAME 1”), using
                                   voxel­wise estimate of between subject variance.





                                        ○ Global weighted least squares (i.e. SPM’s MFX).
                             With any group (multi­subject) model, indicate any specific variance structure, e.g.
                                ● Un­equal variance between groups (and if globally pooled, as in SPM).
                                ● If repeated measures, the specific covariance structure assumed (e.g.
                                    compound symmetric, or arbitrary; if globally pooled).

                             For local­multivariate report:
                                ● The number of voxels in the local model.
                                ● Local model used (e.g. Canonical Correlation Analysis) with any
                                    constraints (e.g. positive weights only).

Inference: Contrast/effect      ●   Specification of the precise effect tested, often as a linear contrast of         Y
                                    parameters in a model. When possible, define these in terms of the task or
                                    stimulus conditions instead of psychological concepts (See T   ​ask
                                    Specification​   ​xperimental Design Reporting)​
                                                  in E                                 .
                                ●   Provide tables/figures on main effects (e.g. in supplement), not just
                                    differences or interactions. For example, an inference on a difference of
                                    two fMRI conditions, A­B, doesn’t indicate if both A & B induced positive
                                    changes; likewise, to fully interpret an interaction requires knowledge of the
                                    main effects.
                                ●   Indicate any use of any omnibus ANOVA tests.
                                ●   All contrasts explored as part of the research should be fully described in
                                    the methods section, whether or not they are considered in the results.
                                ●   If performing a two­sided test via two one­sided tests, double the one­sided
                                    p­values to convert them into two­sided p­values. For example, if looking at
                                    both a contrast [­1 1] and [1 ­1] together, each with cluster­forming
                                    threshold p=0.001, double the FWE cluster p­values from each contrast to
                                    obtain two­sided inferences.

Inference: Search region        ●   Whole brain or “small volume”; carefully describe any small volume                Y
                                    correction used for each contrast.
                                ●   If a small-volume correction mask is defined anatomically, provide named
                                    anatomical regions from a publicly available ROI atlas.





                                    ●   If small-volume correction mask is functionally defined, clearly describe the
                                        functional task and identify any risk of circularity.
                                    ●   All small-volume corrections should be fully described in the methods
                                        section, not just mentioned in passing in the results.

Inference: Statistic type        Typically one of:                                                                      Y
                                    ● Voxel­wise (aka peak­wise in SPM).
                                    ● Cluster-wise.
                                             ○ Cluster size.
                                             ○ Cluster mass.
                                             ○ Threshold­free Cluster Enhancement (TFCE).
                                 For cluster size or mass, report:
                                    ● Cluster-forming threshold.
                                 For all cluster­wise methods, report:
                                    ● Neighborhood size used to form clusters (e.g. 6, 18 or 26).
                                 For TFCE, report:
                                    ● Use of non­default TFCE parameters.

Inference: P­value computation   Report if anything but standard parametric inference used to obtain (uncorrected)      Y
                                 P­values. If nonparametric method was used, report method (e.g. permutation or
                                 bootstrap) and number of permutations/samples used.

Inference: Multiple testing      For mass­univariate, specify the type of correction and how it is obtained,            Y
correction                       especially if not the typical usage. Usually one of:
                                    ● Familywise Error.
                                             ○ Random Field Theory (typical).
                                             ○ Permutation.
                                             ○ Monte Carlo.
                                             ○ Bonferroni.
                                    ● False Discovery Rate.
                                             ○ Benjamini & Hochberg FDR (typical).
                                             ○ Positive FDR.
                                             ○ Local FDR.
                                             ○ Cluster­level FDR.





                                      ● None/Uncorrected.
                                  If permutation or Monte Carlo, report the number of permutations/samples. If
                                  Monte Carlo, note the brain mask and smoothness used, and how smoothness
                                  was estimated.

Functional connectivity

Confound adjustment & filtering   Report:                                                                             Y
                                     ● Method for detecting movement artifacts, movement­related variation, and
                                         remediation (e.g. ‘scrubbing’, ‘despiking’, etc).
                                     ● Use of global signal regression, exact type of global signal used and how it
                                         was computed.
                                     ● Whether a high­ or low­pass temporal filtering is applied to data, and at
                                         which point in the analysis pipeline. Note, any temporal regression model
                                         using filtered data should have it’s regressors likewise filtered.

Multivariate method:              Report:                                                                             Y
Independent Component                ● Algorithm to estimate components.
Analysis                             ● Number of components (if fixed), or algorithm for estimating number of
                                         components.
                                     ● If used, method to synthesize multiple runs.
                                     ● Sorting method of IC’s, if any.
                                     ● Detailed description of how components were chosen for further analysis.

Dependent variable definition     For seed­based analyses report:                                                     Y
                                     ● Definition of the seed region(s).
                                     ● Rationale for choosing these regions.
                                  For region­based analyses report:
                                     ● Number of ROIs.
                                     ● How the ROI’s are defined (e.g. citable anatomical atlas; auxiliary fMRI
                                         experiments); note if ROIs overlap.
                                     ● Assignment of signals to regions (i.e. how a time series is obtained from
                                         each region, e.g. averaging or first singular vector)
                                     ● Note if considering only bilateral (L+R) merged regions.





                                      ●   Note if considering only interhemispheric homotopic connectivity.

Functional connectivity measure/   Report:                                                                                   Y
model                                 ● Measure of dependence used, e.g. Pearson’s (full) correlation, partial
                                          correlation, mutual information, etc; also specify:
                                              ○ Use of Fisher’s Z-transform (Yes/No) and, if standardised, effective
                                                  N is used to compute standard error (to account for any filtering
                                                  operations on the data).
                                              ○ Estimator used for partial correlation.
                                              ○ Estimator used for mutual information.
                                      ● Regression model used to remove confounding effects (Pearson or partial
                                          correlation).

Effectivity connectivity           Report:                                                                                   Y
                                      ● Model.
                                      ● Algorithm used to fit model.
                                      ● If per­subject model, method used to generalize inferences to population.
                                      ● Itemize models considered, and method used for model comparison.

Graph analysis                     Report the ‘dependent variable’ and ‘functional connectivity measure’ used (see           Y
                                   above).
                                   Specify either:
                                       ● Weighted graph analysis or,
                                       ● Binarized graph analysis is used, clarifying the method used for
                                          thresholding (e.g. a 10% density threshold, or a statistically­defined
                                          threshold); consider the sensitivity of your findings to the particular choice
                                          of threshold used.
                                   Itemise the graph summaries used (e.g. clustering coefficient, efficiency, etc),
                                   whether these are global or per­node/per­edge summaries. In particular with fMRI
                                   or EEG, clarify if measures applied to individual subject networks or group
                                   networks.

Multivariate modelling &
predictive analysis





Independent variables     Specify:                                                                             Y
                              ● Variable type (discrete or continuous).
                              ● Class proportions in classification settings.
                              ● Variable dimension.
                                      o For whole­brain prediction, this is a voxel count.
                                      o For searchlight analyses, the exact number of voxels in the search
                                           region, not just a radius.
                                      o Provide dimension before and after any feature selection and/or
                                           dimension reduction.
                          If available, report on population stratification:
                              ● Information on how the target values relate to the population (e.g.
                                   male/female frequency or age distribution by group).
                              ● Specify how this is taken into account in the predictive model.

Features extraction and   Specify the use of any:                                                              Y
dimension reduction          ● Feature transformation.
                             ● Feature selection.
                             ● Dimension reduction.
                          When these techniques are data­driven, specify the procedures used to learn the
                          parameters involved.

Model                     For traditional multivariate analyses, report:                                       Y
                             ● Type of model, e.g. MANOVA.
                             ● Assumptions made on the covariance structure, e.g. independence, or a
                                  common arbitrary covariance between groups.
                             ● Statistic used to assess significance, e.g. Wilk’s lambda, Hotelling­Lawley
                                  trace, etc.
                          For predictive models, report:
                             ● Type of model, e.g. Linear discriminant analysis, support vector machines,
                                  logistic regression, etc.
                             ● For kernel­based methods (i.e. SVM) report type of kernel used, type and
                                  number of parameters needed to be estimated.

Learning method           Report:                                                                              Y





                                    ●   Figure-of-merit optimised.
                                    ●   Fitting method.
                                    ●   Parameter settings, those fixed and those estimated; specify how fixed
                                        parameter values were chosen.
                                    ●   How the convergence of the learning method is monitored.

Training procedure               Describe:                                                                              Y
                                    ● Pipeline structure applied uniformly to all cases (e.g. that could be
                                        independently applied to a new case).
                                    ● Method for hyper­parameter setting.
                                    ● Data splitting (cross validation).

Evaluation metrics: Discrete     Describe the evaluation metrics that are to be computed. Always compute:               Y
response                            ● Accuracy.
                                    ● If group sizes unequal, balanced (or average) accuracy.
                                 When there are only 2 classes, and one can be labeled “positive”:
                                    ● Precision (1 − false discovery rate).
                                    ● Recall (sensitivity).
                                    ● False positive rate (1­specificity).
                                    ● F1 (incorporates both precision and recall).
                                    ● Receiver operating characteristic (ROC) curves, e.g. summarised by area
                                        under the curve (AUC); AUC for only high specificity (e.g. false positive
                                        rates no greater than 10%) are also useful.
                                 When there are 3 or more classes:
                                    ● Report the confusion matrix.
                                               2​
Evaluation metrics: Continuous   “Prediction R​ ”, the percentage of variance explained by prediction, computed as      Y
response                         one minus the ratio of prediction sum­of­squares to total sum­of­squares. (Note
                                       s not​
                                 this i​    the squared correlation coefficient between true and predicted values).

Evaluation metrics:              Report the Kendall Tau statistic for each candidate model considered.                  Y
Representational similarity
analysis





Evaluation metrics: Significance   When possible use formal test to obtain P­value to assess whether evaluation                 Y
                                   metric is “significant” or consistent with noise.

Fit interpretation                 Procedure used to interpret the fit of the classifier, identifying the relative              N
                                   importance of the features (e.g. the weight vector in linear discriminant).
```
