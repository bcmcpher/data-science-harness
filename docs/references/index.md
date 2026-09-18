# Motivating literature

Why this harness is built the way it is. Each source below names at least one capability in
[`openspec/specs/`](../../openspec/specs) that it bears on; a source that motivates nothing
identifiable does not belong here.

This is distinct from [`docs/writing/index.md`](../writing/index.md), which collects guidance on
*how to write a manuscript*. That table is about craft. This one is about the problem.

Local copies of PDFs live in [`../../resources/`](../../resources), which is git-ignored
(copyrighted / large files). Web-only sources are linked with an access date. Citation records live
in [`references.bib`](references.bib) — the single source of truth, cited directly by
[`paper/`](../../paper). Do not maintain a second copy.

## Sources

| Cite | Source | Local file | Motivates | Note |
|------|--------|-----------|-----------|------|
| Chen, Lu, Li, … Poldrack (2026), *arXiv:2608.19902* | [Bringing analytic rigor to agentic AI for science: The Brain Researcher platform for neuroimaging data analysis](https://arxiv.org/abs/2608.19902) | *(web)* | `evaluation-protocol`, `publication`, `analyze`, `govern` | [notes](notes/chen-2026-brain-researcher.md) — overlapping scope, not merely adjacent |
| Botes (2026), *Biolawgic* | [The Law Inside the Machine: Building the NeuroAI Future by Design](https://biolawgic.substack.com/p/the-law-inside-the-machine-building) | *(web)* | `project-ledger`, `govern`, `curate`, `liab` | [notes](notes/botes-2026-law-inside-machine.md) |
| Macdonald, Baker, To & Halchenko (2026), Center for Open Neuroscience | STAMPED principles for reproducible research objects | `Macdonald_STAMPED_2026.pdf` | every spec — the framework the whole harness indexes into | [notes](notes/macdonald-2026-stamped.md) |

## Standards and tools integrated by the harness

These are named throughout `README.md` and the plugin bodies. They are recorded in
[`references.bib`](references.bib) so that nothing ships uncited, but most entries are placeholders
pending verification — see the `TODO` notes in the file. Verify each before submission.

BIDS · DataLad · Nipoppy · Neurobagel · NeuroLibre · Paper2Agent · Lab-in-a-Box · EQUATOR · COBIDAS
(Nichols et al. 2017) · ORCID · CRediT · DataCite

## What a note contains

Each file in [`notes/`](notes) follows one shape:

1. **Citation** — full, matching the BibTeX key.
2. **Core claim** — what the source actually argues, in its own terms.
3. **What it motivates** — at least one named `openspec/specs/` capability or plugin, with the
   specific design decision it bears on.
4. **Where it differs** — how this project's approach diverges. For a source with overlapping scope,
   this section states the overlap explicitly rather than describing the work as complementary by
   default.
5. **Quoted passages** — short, attributed.

> Attribution note: these notes paraphrase and use only short quotations from the sources above.
> Where a claim is a direct statement of one source, it is quoted and cited inline.
