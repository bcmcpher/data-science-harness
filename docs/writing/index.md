# Academic manuscript writing — consolidated guidance

Reference material for drafting and reviewing academic manuscripts, distilled from a set of
writing guides and methodological papers (listed below). It is organized so it can be baked
into skill prompts and loaded by a dedicated **manuscript** writing/review sub-agent (see
[`SPEC.md`](SPEC.md)). The emphasis is on the three article types this project cares about:
**primary research articles, narrative/literature reviews, and (neuroimaging) meta-analyses.**

## What's here

| Doc | Scope |
|-----|-------|
| [`article-anatomy.md`](article-anatomy.md) | Primary research article: which sections exist, the purpose and internal structure of each, the recommended order to write them, per-section templates, and figure/submission guidance. |
| [`prose-craft.md`](prose-craft.md) | Sub-section craft: paragraph structure (topic sentence → evidence → analysis → transition), sentence-level flow (old→new information), word choice, and the macro/micro revision process. |
| [`reviews-and-meta-analyses.md`](reviews-and-meta-analyses.md) | Specialized guidance for **narrative/literature reviews** (Baumeister) and **systematic reviews & meta-analyses** (PRISMA; Müller "ten simple rules" for neuroimaging meta-analysis; the Neurosynth Compose / NiMARE / NiMADS tooling stack). |
| [`reviewing-manuscripts.md`](reviewing-manuscripts.md) | The **review** side: critiquing a draft and writing an effective, ethical journal-article review (Drotar et al.; Kazdin's reviewer criteria) — the counterpart to the authoring docs. |
| [`SPEC.md`](SPEC.md) | Spec (not live files) for the resource skills and the dedicated `manuscript` sub-agent that loads them; how they slot into the `disseminate` plugin. |

## How to use

- **Drafting:** pick the article type, open the relevant anatomy doc, and follow the writing
  order (it is not top-to-bottom). Use `prose-craft.md` while writing any paragraph.
- **Reviewing:** run the checklists at the end of each doc against the draft; flag structural
  problems (missing moves, buried take-home) before line-editing prose.
- **The one rule under all of them:** *the burden of clarity is the writer's, not the
  reader's* (Carandini). A rushed reader should be able to follow the argument from the
  **title, abstract, topic sentences, and figures** alone.

## Sources

Local copies live in [`../../resources/`](../../resources); web-only sources are linked.

| Cite | Source | Local file | Best for |
|------|--------|-----------|----------|
| Schwabe, López-Bendito & Ribeiro (2016), *EJN* | "Getting published: how to write a successful neuroscience paper" | `Schwabe_2016.pdf` | Section-by-section; funnel intro; figures-as-storyboard; cover letter; revision |
| Carandini (2022), *eNeuro* | "Some Tips for Writing Science" | `Cardinini_2022.pdf` | Topic sentences; old→new sentences; figure minimal-ink; word choice |
| Kallestinova (2011), *Yale J Biol Med* | "How to Write Your First Research Paper" | `Kallestinova_2011.pdf` | CARS three-move intro/discussion; macro/micro revision |
| Fried (2021), Harvard GSE Comm Lab | "The Structure of an Academic Paper" | `Fried_2021.pdf` | Hourglass; hook/thesis/roadmap; paragraph 4-part structure |
| Miami U Libraries | "Writing Your Paper" (neuroscience LibGuide) | *(web)* | Section purposes; recommended writing order |
| Baumeister (2013), in Prinstein (ed.) *The Portable Mentor* ch. 8 | "Writing a Literature Review" | `Baumeister_2013.pdf` (book: `Prinstein_2013.pdf`) | Narrative vs meta-analytic reviews; conclusion types; common review errors |
| Kazdin (2013), *The Portable Mentor* ch. 10 | "Publishing Your Research" | `Prinstein_2013.pdf` (pp. 145–161) | Three tasks (describe/explain/contextualize); section question-checklist (Table 10.1); reporting standards; journal choice |
| Drotar, Wu & Rohan (2013), *The Portable Mentor* ch. 11 | "How to Write an Effective Journal Article Review" | `Prinstein_2013.pdf` (pp. 163–172) | Peer-review strategy (Table 11.1) and section-by-section critique checklist (Table 11.2); review ethics |
| Müller, Cieslik, Laird, Fox, … Eickhoff (2018), *Neurosci Biobehav Rev* 84:151–161 | "Ten simple rules for neuroimaging meta-analysis" | `Muller_2018.pdf` | Coordinate-based meta-analysis best practice + checklist |
| Kent, Lee, Laird, … de la Vega (2026), *Imaging Neuroscience* | "Neurosynth Compose: a web-based platform for flexible and reproducible neuroimaging meta-analysis" | `Kent_2026.pdf` | Reproducible meta-analysis tooling (NiMADS, NiMARE, NeuroStore) |

> Attribution note: these docs paraphrase and use only short quotations from the sources above.
> Where a rule is a direct recommendation of one source, it is cited inline by author/year.
