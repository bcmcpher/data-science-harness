# COBIDAS — Table D.6 — Data Sharing

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
Table D.6. Data Sharing

Aspect                            Notes                                                                               Mandatory

Reporting a data sharing
resource

Material shared                   List types of images and non­imaging data provided.                                 Y
                                  Report on the completeness of the data (e.g., number of subjects where all types
                                  of imaging, demographic, and behavioral data is available).

URL, access information           Provide:                                                                            Y
                                     ● Stable URL or DOI.
                                     ● Specific instructions on how to gain access. Specifically mention whether
                                         application must be vetted for particular intended research use (e.g. to
                                         preclude multiple users investigating the same question), or whether a
                                         research collaboration must be established.





                             ●   Cost of access.

Ethics compliance        Confirm that the ethics board of the host institution generating the data approves    Y
                         the sharing of the data made available.
                         Clarify any constraints on uses of shared data, for example, whether users
                         downloading the data also need ethics approval from their own institution.

Documentation            Provide URL to documentation, and specify its scope (e.g. worked examples,            N
                         white papers, etc).

Data format              Report the format of the image data shared, e.g. DICOM, MINC, NIFTI, etc.             Y

Ontologies               Data organization structures, including Data Dictionaries and Schemas. Is the         N
                         software using an established ontology?

Visualization            Availability of in­resource visualization of the imaging or non­imaging data.         N

De-identification        How, if at all, data are de­identified.                                               N

Provenance and history   Availability of detailed provenance of preprocessing and analysis of shared data.     N

Interoperability         Ability of a repository to work in a multi­database environment, availability of      N
                         API’s and ability to connect to analysis pipelines.

Querying                 Mechanisms available for constructing queries on the repository (e.g. SQL,            N
                         SPARQL).

Versioning               How users can check version of downloaded data and compare it to the current          N
                         version at a later time.
```
