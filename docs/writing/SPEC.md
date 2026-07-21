# SPEC — manuscript writing skills + `manuscript` sub-agent

Design spec (**not live files** — the seed-repo rule defers plugin/agent implementation to the
hackathon). It defines the resource skills that surface the [`docs/writing/`](index.md) bundle
and the dedicated **`manuscript`** writing/review sub-agent that loads them, and how both slot
into the existing architecture.

## Placement in the architecture

- **Plane:** these are **workflow** skills (research process, not tool mechanics) — they live in
  the **`disseminate`** workflow plugin (see the root README's two-plane taxonomy). They extend
  the plugin's existing `draft-manuscript` and `reporting-checklist` skills.
- **References bundle:** at build time the five reference docs move to
  `plugins/disseminate/references/writing/` (mirroring how `docs/stamped.md` becomes
  `plugins/govern/references/stamped.md`). Skills and the sub-agent cite them; per Design Rule 7,
  the large domain knowledge stays in `references/`, not in skill bodies.
- **Cross-links:** the meta-analysis material couples to the **`analyze`** plugin's
  `literature-search` / meta-analysis tooling (NiMARE, Neurosynth Compose) and to the *living
  research product* goal — a meta-analysis authored here can become an `executable-article` /
  updatable synthesis, not a frozen table.

## Resource skills (universal `SKILL.md`)

| Skill | Status | Loads | Does |
|-------|--------|-------|------|
| `draft-manuscript` | **enhance** existing | `article-anatomy`, `prose-craft` | Scaffold/redraft a **primary research article**; backbone = Kazdin Table 10.1 section questions; auto-fill Methods/Data-availability from the ledger + `datalad log` (existing behavior). |
| `draft-review` | **new** | `reviews-and-meta-analyses` (Baumeister part) | Scaffold a **narrative/literature review**: force an explicit thesis, organize by ideas not papers, drive the four-conclusion and counterexample passes. |
| `draft-meta-analysis` | **new** | `reviews-and-meta-analyses` (Müller part) | Structure a **(neuroimaging) meta-analysis** report against the ten rules; wire to `analyze` meta-analysis tooling (NiMARE / Neurosynth Compose). |
| `reporting-checklist` | **enhance** existing | `reviews-and-meta-analyses`, `article-anatomy` | Apply the right standard — EQUATOR (CONSORT/STROBE/PRISMA/ARRIVE), COBIDAS, and the **Müller Table-1** neuroimaging-meta-analysis checklist. |
| `review-manuscript` | **new** | `reviewing-manuscripts` + all checklists | **Reviewer-side** critique of a draft: section-organized, numbered points, major-vs-minor, revision-potential judgment, ethics. |
| `polish-prose` | **new (optional)** | `prose-craft` | A focused sentence/paragraph pass (topic sentences, old→new flow, concision, terminology consistency) on a selected passage. |

**Example universal frontmatter** (`review-manuscript`):

```yaml
---
name: review-manuscript
plane: workflow
category: disseminate
description: >
  Critique a manuscript draft and write an effective, ethical review — section-organized,
  numbered points, major vs minor, revision-potential judgment. Triggers on "review this
  manuscript", "critique this draft", "write a peer review", "is this ready to submit".
when:
  always: false
  globs: ["*.md", "*.tex", "*.docx"]
tools: [Read, Grep]
uses_references: [writing/reviewing-manuscripts.md, writing/article-anatomy.md,
                  writing/reviews-and-meta-analyses.md]
version: "0.1.0"
harnesses: [all]
---
```

## The `manuscript` sub-agent

A dedicated writing/review sub-agent — the user's "bound to a sub-agent" intent. It is the
natural entry point for all six skills and holds the writing bundle as standing context.

**Definition (universal spec; adapters translate per harness):**

```yaml
---
name: manuscript
description: >
  Specialist for drafting and reviewing academic manuscript text — research articles,
  narrative/literature reviews, and meta-analyses. Use to draft or tighten a section, or to
  critique a full draft as a reviewer.
plane: workflow
plugin: disseminate
tools: [Read, Edit, Write, Grep]        # text-focused; no analysis/provenance tools
model: strong-writing                    # e.g. a top-tier Claude model
loads:                                   # standing knowledge (the references bundle)
  - references/writing/index.md
  - references/writing/article-anatomy.md
  - references/writing/prose-craft.md
  - references/writing/reviews-and-meta-analyses.md
  - references/writing/reviewing-manuscripts.md
harnesses: [all]
---
```

**Two modes** (the agent picks from the request):
- **Author mode** — draft or improve text. Respects the article type (research / review /
  meta-analysis), follows the relevant anatomy + prose-craft, and *never fabricates results,
  citations, or statistics* — it scaffolds structure and prose around the author's real content.
- **Reviewer mode** — critique per [`reviewing-manuscripts.md`](reviewing-manuscripts.md):
  section-organized, numbered, major-points-first, constructive tone, revision-potential verdict.

**Harness translation:** Claude Code → `.claude/agents/manuscript.md` sub-agent; Cursor → a
scoped rule/mode; other harnesses → the closest agent/persona construct. Where a harness has no
sub-agent concept, the six skills still work standalone (graceful degradation, Design Rule 2/13
spirit).

**Invocation triggers:** "draft the Introduction," "tighten this Discussion," "turn these notes
into a Methods section," "write a literature review on X," "structure this meta-analysis,"
"review this manuscript / is it ready to submit," "check reporting-guideline compliance."

**Boundaries (what it does NOT do):** it does not run analyses, generate figures, fabricate
data/citations, or make submission decisions — it works on **text**. Analysis lives in `analyze`;
provenance in `datalad`; figure generation is a known scaffolding gap (see the workflow doc).

## Guardrails baked into every skill/agent prompt
- Burden of clarity is the writer's, not the reader's (Carandini).
- Never invent results, statistics, citations, or sources; flag missing evidence instead.
- Keep the author's terminology consistent; do not silently change claims' strength
  (claim vs. proof).
- Reviewer mode stays constructive, focuses on major points, and respects confidentiality/COI.

## Build/deferral note
Per the seed-repo constraint, this session ships the **references + this spec** only. Live SKILL.md
files and the sub-agent definition are created during the hackathon (Phase 2 — workflow plane),
at which point the `docs/writing/` bundle relocates to `plugins/disseminate/references/writing/`.
