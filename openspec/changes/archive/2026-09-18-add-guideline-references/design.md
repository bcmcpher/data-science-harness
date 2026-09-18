## Context

Two planner skills cite reporting guidelines they cannot read. The fix is obvious — bundle the text —
and the interesting part is what happens when you check whether you are allowed to.

Reporting guidelines are published by initiatives, not publishers, and distributed as PDFs from their
own websites. Those PDFs mostly carry a copyright line and no licence. The same checklists, however,
were published in open-access journals, and those versions are CC BY. Which copy you take the text
from decides whether bundling it is redistribution or infringement, and the copy a search returns
first is usually the unlicensed one.

## Goals / Non-Goals

**Goals:**
- Every checklist item this harness writes into an artifact is traceable to a file on disk, and that
  file is traceable to a licensed publication.
- An unbundled guideline produces a refusal with a pointer, not a partial checklist.
- The licensing work is recorded where the next person will find it, so it is not redone from
  scratch or, worse, assumed.

**Non-Goals:**
- **Judging whether an item is adequately reported.** The skill records where each item is addressed.
  Whether what is written there is sufficient is the author's and the reviewer's, and the skill says
  so with 🔧.
- **Bundling every guideline.** STARD, TRIPOD and CARE are catalogued and not bundled. Each is a
  separate piece of licensing work.
- **Bundling the Explanation and Elaboration documents.** They are where the per-item guidance lives,
  and they are long. The checklist is what an author fills in.
- **Reformatting the checklists into Markdown tables.** See the decision below.
- **Auto-filling items from the manuscript text.** Pre-filling is limited to items the *ledger* can
  evidence — registration, funding, data availability — where the evidence is a field, not a reading.

## Decisions

- **Take the text from the licensed publication, and say which one.** Verified 2026-09-18:
  - **CONSORT 2025** — PLOS Medicine 2025;22(4):e1004587, CC BY. Published simultaneously in five
    journals; only this one's licence permits redistribution.
  - **STROBE** — PLoS Medicine 2007;4(10):e296, CC BY. The checklist PDFs on strobe-statement.org
    carry *"Copyright © STROBE"* and no licence.
  - **PRISMA 2020** — prisma-statement.org states CC BY 4.0 for the checklists explicitly. The one
    case where the initiative's own distribution is licensed.
  - **ARRIVE 2.0** — PLOS Biology 2020;18(7):e3000410, which is *"free of all copyright"*. The
    arriveguidelines.org checklists carry *"© NC3Rs"* and no licence.
  - **COBIDAS** — the bioRxiv preprint, doi 10.1101/054262, CC BY 4.0. The Nature Neuroscience
    version is not openly licensed.
  Each reference file states its basis and the date it was checked, because a licence is a fact about
  a moment and this one will need rechecking.
- **Transcribe verbatim, preserving the source's layout, inside a fenced block.** The alternative —
  reflowing each checklist into a Markdown table — is an edit, performed by the same process that
  would otherwise be recalling the items. Reflowing is where two items get merged, a sub-item loses
  its letter, or a hyphenated line break becomes a word boundary. The layout is ugly and the fidelity
  is the point. Words the typesetter broke across lines are left broken for the same reason.
- **A guideline that is not bundled is a refusal, not a smaller checklist.** "Here are the items I
  could recall" is worse than nothing, because it is submitted. The skill names the guideline and the
  EQUATOR library and stops.
- **`qc-review` reads two of COBIDAS's seven tables, and says so.** Data sharing and reproducibility
  are the items a *dataset* can answer before a paper exists; acquisition, preprocessing, modeling,
  inference and results describe a study and belong to submission-time review. A review that read all
  seven would report a dataset as failing items it is not yet in a position to answer.
- **The COBIDAS reference lives in `disseminate`, and `govern` reaches across to it.** The
  alternative is a second copy in `govern`, and two copies of a checklist is how they diverge.
  `qc-review` therefore handles the file's absence explicitly: installed without `disseminate`, the
  check is skipped with that reason. That is the same shape as every other absent-capability path in
  the harness.
- **Version the guideline in the filename.** `consort-2025.md`, `prisma-2020.md`, `arrive-2.0.md`.
  CONSORT 2010 was superseded while the index still said "CONSORT", and an unversioned filename is
  how that goes unnoticed for another five years. `strobe.md` is unversioned because STROBE has had
  no revision.
