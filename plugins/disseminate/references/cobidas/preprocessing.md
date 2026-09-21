# COBIDAS — Table D.3 — Preprocessing Reporting

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
Table D.3. Preprocessing Reporting

Aspect                     Notes                                                                                  Mandatory

Software                   For each software used, be sure to include version and revision number.                Y

Software citation          Include URL and Research Resource Identifier for each software used.                   N

T1 stabilization           Number of initial “dummy” scans discarded as part of preprocessing (if not already     Y
                           performed by scanner).

Brain extraction           If performed, report:                                                                  Y
                               ● Name of software/method (e.g., BET, recon­all in FreeSurfer, etc).
                               ● Parameter choices (e.g. BET’s fractional intensity threshold).
                               ● Any manual editing applied to the brain masks.

Segmentation               For structural images, method used to extract gray, white, CSF and other tissue        Y
                           classes.

Slice time correction      If performed, report:                                                                  Y
                               ● Name of software/method.
                               ● Whether performed after or before motion correction.
                               ● Reference slice.
                                                                      rd​
                               ● Interpolation type and order (e.g., 3​ order spline or sinc).

Motion correction          Report:                                                                                Y
                              ● Name of software/method.
                              ● Use of non­rigid registration, and if so the type of transformation.
                              ● Use of motion susceptibility correction (fieldmap­based unwarping), as well
                                  as the particular software/method.
                                                          st​
                              ● Reference scan (e.g. 1​     scan or middle scan).
                              ● Image similarity metric (e.g. normalized correlation, mutual information,
                                  etc).





                                    ●   Interpolation type (e.g., spline, sinc), and whether image transformations
                                        are combined to allow a single interpolation.
                                    ●   Use of any slice­to­volume registration methods, or integrated with slice
                                        time correction.

Gradient distortion correction   (If not already described as part of motion susceptibility correction.)                 Y

Diffusion MRI eddy current       Report:                                                                                 Y
correction                          ● Name of software/method, and if integrated with motion correction
                                    ● Image similarity / cost function.
                                    ● Type of transformation (e.g. rigid body, affine) and whether constrained
                                        only along the phase encode direction.
                                    ● Note if gradient table (b­matrix) is then re­oriented.
                                    ● Volumetric change applied for eddy current along the phase­encode axis
                                        (by the Jacobian determinant).

Diffusion estimation             For all methods, report                                                                 Y
                                     ● Model, parameterisation and number of free parameters.
                                     ● Estimation method.
                                     ● Outlier handling approach.
                                     ● Some evidence of fit quality; e.g sample of slices of diffusion weighted
                                         data, or residual maps.
                                 Items to note for particular approaches:
                                     ● Tensor or Kurtosis.
                                            ○ Any parameter constraints, like cylindrical symmetry.
                                     ● Multi-compartmental models.
                                            ○ Compartments of the model.
                                     ● Orientation distribution function.
                                            ○ Parametric (model) or nonparametric (basis function) model.
                                            ○ Whether orientation distribution function or fibre orientation density
                                                 is reported.
                                            ○ For spherical deconvolution, note how the canonical fibre response
                                                 function is derived (e.g. from the data themselves, or simulated
                                                 data).





Diffusion processing                 Report:                                                                                N
                                        ● Summary measures computed (FA, MD, AD, RD, MK, AK, RK, etc.).
                                        ● Whether a track based or voxel­wise method is used.
                                        ● Threshold used to define analysis voxels.
                                        ● Use of population reference track atlas vs. custom atlas (specify set of
                                            subjects used to create atlas).
                                        ● Standard deviation map (across subjects).

Diffusion tractography               Report:                                                                                Y
                                        ● Name of software/method.
                                        ● Step size, turning angle and stopping criteria.
                                        ● For ROI based analysis, definition of ROIs (e.g. specify the images used to
                                            draw ROIs; manual, semi-automatic or automatic definition of ROIs).
                                        ● For tracking, note step­size, turning angle, any anatomical constraints
                                            imposed, and stopping criteria.
                                        ● If a measure of path probability / “connectivity” is extracted, clearly define
                                            this measure.

Perfusion: Arterial Spin Labeling    Report modelling/post­processing scheme:                                               Y
                                        ● For subtraction, specify whether simple subtraction, running,
                                            sinc­subtraction, etc.
                                        ● For quantitative model, specify model used, number of free parameters.

Perfusion: Dynamic                      ●   How concentration time curves are calculated, e.g. use of T1 corrections (if    Y
Susceptibility Contrast MRI                 short TR) or corrections for leakage.
                                        ●   Selection of arterial input function (e.g. manual or automatic with reference
                                            to method).
                                        ●   Deconvolution method (kinetic model) to estimate residue function (e.g.
                                            SVD or parametric model).
                                        ●   Details of parameter calculations (e.g. CBF, CBV, MTT, TTP, Tmax).

Function­structure (intra­subject)   Report:                                                                                Y
coregistration                          ● Name of software/method.
                                        ● Type of transformation (rigid, nonlinear); if nonlinear, type of transformation





                               ●    Cost function (e.g., correlation ratio, mutual information, boundary­based
                                    registration, etc).
                                ● Interpolation method (e.g., spline, linear).
                            Note this step might not be necessary if direct T2* to a functional template
                            registration is used.

Distortion correction       Use of any distortion correction due to field or gradient nonlinearity.                Y

Intersubject registration   Report:                                                                                Y
                               ● Name of software/method (e.g., FSL flirt followed by fnirt, FreeSurfer,
                                   Caret, Workbench, etc)
                               ● Whether volume and/or surface based registration is used (if not already
                                   clearly implied).
                               ● Image types registered (e.g. T2* or T1).
                               ● Any preprocessing to images; e.g. for T1, bias field correction, or
                                   segmentation of gray matter; for T2*, single image (specify image) or mean
                                   image.
                               ● Template space (e.g., MNI, Talairach, fsaverage, FS_LR), modality (e.g.,
                                   T1, T2*), resolution (e.g., 2mm, fsaverage5, 32k_FS_LR), and the specific
                                   name of template image used; note the domain of the template if not whole
                                   brain, i.e. cortical surface only, cerebellum only, CIFTI ‘grayordinates’
                                   (cortical surface vertices + subcortical gray matter voxels), etc.
                               ● Additional template transformation for reporting; e.g., if using a template in
                                   MNI space, but reporting coordinates in Talairach, clearly note and report
                                   method used (e.g., Brett’s mni2tal, Lancaster’s icbm_spm2tal).
                               ● Choice of warp (rigid, nonlinear); if nonlinear, transformation type (e.g.,
                                   B­splines, stationary velocity field, momentum, non­parametric
                                   displacement field); if a parametric transformation is used, report
                                   resolution, e.g., 10x10x10 spline control points.
                               ● Use of regularization, and the parameter(s) used to set degree of
                                   regularization.





                                   ●   Interpolation type (e.g., spline, linear); if projection from volume to surface
                                       space, how were voxels sampled from the volume (e.g., trilinear; nearest
                                       neighbor; ribbon­constrained specifying inner and outer surface used).
                                   ●   Cost function (e.g., correlation ratio, mutual information, SSD).
                                   ●   Use of cost­function masking.

Intensity correction            Bias field corrections for structural MRI, but also correction of odd versus even          Y
                                slice intensity differences attributable to interleaved EPI acquisition without gaps.

Intensity normalization         Scan­by­scan or run­wide scaling of image intensities before statistical modelling.        N
                                E.g. SPM scales each run such that the mean image will have mean intracerebral
                                intensity of 100; FSL scales each run such that the mean image will have an
                                intracerebral mode of 10,000.

Artifact and structured noise   Use of physiological noise correction method.                                              Y
removal                         Report:
                                   ● Name of software/method used (e.g. CompCor, ICA­FIX, ICA­AROMA,
                                       etc.).
                                   ● If using a nuisance regression method, specify regressors used; for each
                                       type, include key details, as follows:
                                           ○ Motion parameters.
                                                   ■ Expansion basis and order (e.g. 1st temporal derivatives;
                                                      Volterra kernel expansion)
                                           ○ Tissue signals.
                                                   ■ Tissue type (e.g., whole brain, gray matter, white matter,
                                                      ventricles).
                                                   ■ Tissue definition (e.g., a priori seed, automatic
                                                      segmentation, spatial regression).
                                                   ■ Signal definition (e.g., mean of voxels, first singular vector,
                                                      etc.).
                                           ○ Physiological signals
                                                   ■ e.g., heart rate variability, respiration.





                                               ■   Modeling choices (e.g. RETROICOR, cardiac and/or
                                                   respiratory response functions) and number of computed
                                                   regressors.

Volume censoring             Remediation of problem scans, also known as “scrubbing” or “de­spiking”.                Y
                             Report:
                                ● Name of software/method.
                                ● Criteria (e.g., frame-by-frame displacement threshold, percentage BOLD
                                    change).
                                ● Use of censoring or interpolation; if interpolation, method used (e.g., spline,
                                    spectral estimation).

Resting state fMRI feature   Creation of summary measure like ALFF, fALFF, ReHo.                                     Y
                             For ALFF, fALFF report:
                                ● Lower and upper band pass frequencies.
                             For ReHo, report:
                                ● Neighborhood size used to compute local similarity measures (e.g. 6, 18 or
                                    26).
                                ● Similarity measure (e.g. Kendall’s coefficient of concordance).

Spatial smoothing            If this preprocessing step is performed, report:                                        Y
                                  ● Name of software/method.
                                  ● Size and type of smoothing kernel.
                                  ● Filtering approach, e.g., fixed kernel or iterative smoothing until fixed
                                      FWHM.
                                  ● Space in which smoothing is performed (i.e. native volume, native surface,
                                      MNI volume, template surface).

Quality control reports      Summaries of subject motion (e.g. mean framewise displacement), image variance          N
                             (e.g. DVARS), and note of any other irregularities found (e.g. motion or poor SNR
                             not sufficiently severe to warrant exclusion). Should be included with any publically
                             shared data.
```
