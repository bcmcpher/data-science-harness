# COBIDAS — Table D.2 — Acquisition Reporting

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
Table D.2. Acquisition Reporting

Aspect                      Notes                                                                                  Mandatory

Subject preparation

Mock scanning               Use of an MRI simulator to acclimate subjects to scanner environment. Report           N
                            type of mock scanner and protocol (i.e. duration, types of simulated scans,
                            experiments).

Special accommodations      For example, for pediatric scanning, presence of parent/guardian in the room.          Y

Experimenter personnel      Whether a single or multiple experimenters interacted with the subjects.               N

MRI system description

Scanner                     Provide make, model & field strength in tesla (T).                                     Y

Coil                        Receive coil (e.g. “a 12­channel phased array coil”, but more details for a custom     Y
                            coil) and (if nonstandard) transmit coil. Additional information on the gradient
                            system, e.g. gradient strength (if non­standard for the make and model, or
                            switchable).

Significant hardware        For example, special gradient inserts/sets.                                            N
modifications





Software version               Highly recommended when sharing vendor­specific protocols or exam cards, as             N
                               version may be needed to correctly interpret that information.

MRI acquisition

Pulse sequence type            For example, gradient echo, spin echo, etc.                                             Y

Imaging type                   For example, echo planar imaging (EPI), spiral, 3D.                                     Y
                               Number of shots (if multi­shot); partial Fourier scheme & reconstruction method (if
                               used);

Essential sequence & imaging   For all acquisitions:                                                                   Y
parameters.                        ● Echo time (TE).
                                   ● Repetition time (TR).
                                          o For multi­shot acquisitions, additionally the time per volume.
                                   ● Flip angle (FA).
                                   ● Acquisition time (duration of acquisition).
                               Functional MRI:
                                   ● Number of volumes.
                                   ● Sparse sampling delay (delay in TR) if used.
                               Inversion recovery sequences:
                                   ● Inversion time (TI).
                               B0 field maps:
                                   ● Echo time difference (dTE).
                               Diffusion MRI:
                                   ● Number of directions.
                                          o Direction optimization, if used and type.
                                   ● b-values.
                                   ● Number of b=0 images.
                                   ● Number of averages (if any).
                                   ● Single shell, multi­shell (specify equal or unequal spacing).
                                   ● Single­ or dual­spin­echo, gradient mode (serial or parallel).
                                   ● If cardiac gating used.
                               Imaging parameters:





                               ●   Field of view.
                               ●   In­plane matrix size, slice thickness and interslice gap, for 2D acquisitions.
                               ●   Slice orientation:
                                       ○ Axial, sagittal, coronal or oblique.
                                       ○ Angulation: If acquistion not aligned with scanner axes, specify
                                           angulation to AC­PC line (see Slice position procedure).
                               ●   3D matrix size, for 3D acquisitions.

Phase encoding              Specify phase encoding direction (e.g. as A/P, L/R, or S/I).                              Y
                            For 3D, specify “partition encode” (aka slice) direction.
                            Phase encoding reversal: Mention if used (aka “blip­up/blip­down”).

Parallel imaging method &   Report:                                                                                   Y
parameters                     ● Method, e.g. SENSE, GRAPPA or other parallel imaging method, and
                                   acceleration factor.
                               ● Matrix coil mode, and coil combining method (if non­standard).

Multiband parameters        Multiband factor and field­of­view shift (only if applicable).                            Y

Readout parameters          Receiver bandwidth, readout duration, echo spacing.                                       N

Fat suppression             For anatomical scans, whether it was used or not.                                         Y

Shimming                    Any specialized shimming procedures.                                                      Y

Slice order & timing        For fMRI acquisitions, interleaved vs. sequential ordering and direction                  Y
                            (ascending/descending), location of 1st slice; any specialized slice timing.

Slice position procedure    For example, landmark guided vs. auto­alignment.                                          N

Brain coverage              Report whether coverage was whole­brain, and whether cerebellum and                       Y
                            brainstem were included. If not whole­brain, note the nature of the partial area of
                            coverage. If axial and co­planar with AC­PC line, the volume coverage in terms of
                            Z in mm.





Scanner­side preprocessing           Including:                                                                             Y
                                         ● Reconstruction matrix size differing from acquisition matrix size.
                                         ● Prospective-motion correction (including details of any optical tracking, and
                                             how motion parameters are used).
                                         ● Signal inhomogeneity correction.
                                         ● Distortion-correction.

Scan duration                        In seconds                                                                             N

Other non­standard procedures        Including:                                                                             N
                                         ● Turning off the cold head(s) (e.g. during EEG/fMRI or spectroscopy
                                             measurements).
                                         ● Reduce sound pressure by limiting the gradient slew rate.

T1 stabilization                     Number of initial “dummy” scans acquired and then discarded by the scanner.            Y

Diffusion MRI gradient table         Also referred to as the b­matrix (but not to be confused with the 3×3 matrix that      N
                                     describes diffusion weighting for a single diffusion weighted measurement).

Perfusion: Arterial Spin Labelling      ●   ASL Labelling method (e.g. continuous ASL (CASL), pseudo­continuous             Y
MRI                                         ASL (PCASL), Pulsed ALS (PASL), velocity selective ASL (VSASL)).
                                        ●   Use of background suppression pulses and their timing.
                                        ●   For either PCASL or CASL report:
                                               ○ Label Duration.
                                               ○ Post­labeling delay (PLD).
                                               ○ Location of the labeling plane.
                                        ●   For PCASL also report:
                                               ○ Average labeling gradient.
                                               ○ Slice­selective labeling gradient.
                                               ○ Flip angle of B1 pulses.
                                               ○ Assessment of inversion efficiency; QC used to ensure
                                                    off­resonance artifacts not problematic, signal obtained over whole
                                                    brain.
                                        ●   For CASL also report:





                                        ○ Use of a separate labeling coil.
                                        ○ Control scan/pulse used.
                                        ○ B1 amplitude.
                                 ●   For PASL report
                                        ○ TI.
                                        ○ Labeling slab thickness.
                                        ○ Use of QUIPSS pulses and their timing.
                                 ●   For VSASL
                                        ○ TI.
                                        ○ Choice of velocity selection cutoff (“VENC”).

Perfusion: Dynamic            Specify:                                                                                 Y
Susceptibility Contrast MRI      ● Number of baseline volumes.
                                 ● Type, name and manufacturer of intravenous bolus (e.g. gadobutrol,
                                     Gadavist, Bayer).
                                 ● Bolus amount and concentration (e.g. 0.1 ml/kg and 0.1 mmol/kg).
                                 ● Injection rate (e.g. 5 ml/s).
                                 ● Post­injection of saline (e.g. 20 ml).
                                 ● Injection method (e.g. power injector).

Preliminary quality control

Motion monitoring             For functional or diffusion acquisitions, any visual or quantitative checks for severe   Y
                              motion; likewise, for structural images, checks on motion or general image quality.

Incidental findings           Protocol for review of any incidental findings, and how they are handled in              N
                              particular with respect to possible exclusion of a subject’s data.
```
