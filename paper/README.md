# paper/

Draft of the manuscript describing this harness.

**Status: skeleton.** Every section is an outline with the argument, the evidence it needs, and the
claims it must not make. No section is written prose yet, and **no benchmark has been run** — see
[`docs/evaluation.md`](../docs/evaluation.md).

## Why MyST

The paper argues that research products should be re-executable. Drafting it as a static document
would be a small ongoing embarrassment, and it gives
[`add-compendium-capability`](../openspec/changes/add-compendium-capability) a real target: the
first executable article this harness produces should be its own paper.

## Build

```bash
npm ci                # from the repo root; installs mystmd from package-lock.json
npm run paper:check   # build and fail on any unresolved citation
npm run paper:html    # static HTML export
npm run paper:start   # live preview
```

`npm run paper:check` is what CI runs. It uses `myst build --site` rather than `--html`, because the
static HTML export starts the theme server to crawl itself and does not terminate. It also greps for
unresolved citations, which MyST reports as warnings rather than errors — so `myst build --strict`
alone would go green with a broken bibliography.

## Venue path

**Preprint first** — arXiv or bioRxiv — then
[**Aperture Neuro**](https://www.humanbrainmapping.org/aperture-neuro), OHBM's official open-access
journal. The work began at an OHBM hackathon, which makes Aperture the natural home.

Recorded constraints (verify against the journal's current author guidelines before submitting):

| Constraint | Value |
|---|---|
| License | CC BY 4.0 — set in `myst.yml` |
| Review | Single-blind |
| Median submission → publication | ~146 days |
| Accepted article types | Includes methodological papers, code/dataset/protocol descriptions, tutorials, replication studies |
| Preprints | Preprint-first is compatible with the journal's open-access posture; **confirm the explicit policy before posting** |

## Structure

| File | Carries |
|---|---|
| `main.md` | Abstract and the one-paragraph claim |
| `sections/01-intro.md` | The problem: AI-accelerated analysis outpacing governable provenance |
| `sections/02-related.md` | Brain Researcher, STAMPED, NeuroLibre, Paper2Agent, Lab-in-a-Box — and the positioning |
| `sections/03-architecture.md` | Two planes, planner/doer, ledger, comparison→product, living compendium |
| `sections/04-evaluation.md` | The protocol as **planned work**. No results. |
| `sections/05-discussion.md` | Limitations, led by the absence of executed evaluation |

## Rules for this draft

1. **No unmeasured number.** Nothing in this paper reports a benchmark result until a probe has been
   run. The evaluation section describes a protocol and says so.
2. **No unearned complementarity.** Brain Researcher overlaps this work in scope. Section 02 states
   what each system governs and where they actually meet, rather than asserting they complement each
   other. See [the note](../docs/references/notes/chen-2026-brain-researcher.md).
3. **Cite from `docs/references/references.bib`.** Do not add a second bibliography.
4. **Describe what is built.** The README's own drift between documentation and disk
   ([`reconcile-docs-with-disk`](../openspec/changes/reconcile-docs-with-disk)) is the failure mode to
   avoid here. Every architectural claim should be checkable against `openspec/specs/`.
