# EQUATOR reporting guidelines (reference)

Pick the guideline by **study design**. The EQUATOR Network catalogues reporting guidelines; the
common ones (plus COBIDAS for neuroimaging) are below.

**Bundled** means the guideline's item text is in this repository, so a checklist can be instantiated
from it. **Not bundled** means it is not, and `disseminate/reporting-checklist` will refuse to write
a checklist for it rather than reconstruct the items from memory — which is the exact failure these
guidelines exist to prevent. Whether a guideline is bundled is a licensing fact, not a judgement
about the guideline.

| Study design | Guideline | Bundled | File |
|---|---|---|---|
| Randomized controlled trial | **CONSORT 2025** | yes | [`equator/consort-2025.md`](equator/consort-2025.md) |
| Observational (cohort/case-control/cross-sectional) | **STROBE** | yes | [`equator/strobe.md`](equator/strobe.md) |
| Systematic review / meta-analysis | **PRISMA 2020** | yes | [`equator/prisma-2020.md`](equator/prisma-2020.md) |
| Animal (in vivo) research | **ARRIVE 2.0** | yes | [`equator/arrive-2.0.md`](equator/arrive-2.0.md) |
| **Neuroimaging methods reporting** | **COBIDAS** | yes | [`cobidas/`](cobidas) — seven tables |
| Diagnostic accuracy | **STARD** | no | — |
| Prediction model | **TRIPOD** | no | — |
| Case report | **CARE** | no | — |

## Notes

- **CONSORT 2025 supersedes CONSORT 2010**, whose authors state it should no longer be used. A
  journal whose instructions still name 2010 is behind the guideline, not ahead of it; report against
  2025 and say which version was used.
- **COBIDAS is a companion, not an alternative.** Use it *alongside* the design guideline — STROBE +
  COBIDAS for an observational fMRI study — because it covers acquisition, preprocessing, modeling,
  inference and sharing, which no design guideline does.
- **Where the bundled text comes from.** Each file names its source and its redistribution basis, and
  each was checked on 2026-09-18. In three cases the licensed source is *not* the one a search
  returns first: the STROBE checklist PDFs on strobe-statement.org carry no licence, and the ARRIVE
  checklists on arriveguidelines.org carry only a copyright line — but both guidelines were published
  in PLOS journals under CC BY, and that is what is bundled. Likewise COBIDAS is taken from the CC BY
  bioRxiv preprint rather than the Nature Neuroscience version.
- **Several items are provenance-evidenced by this harness** — data and code availability (ledger
  DOIs plus DataLad), analysis reproducibility (`datalad run` records), and pre-registration
  (`obligations[]`). Pre-fill those; leave the design and clinical items to the author. Each bundled
  file ends with a short section naming which of its items this harness can evidence.
- **STARD, TRIPOD and CARE are not bundled**, so a study of one of those designs gets a refusal and
  a pointer to the EQUATOR library rather than a checklist. Adding one is a reference change: find
  the openly licensed publication of the checklist, transcribe it verbatim, and state the basis.
