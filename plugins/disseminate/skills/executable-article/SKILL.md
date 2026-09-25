---
name: executable-article
description: >
  Scaffold a NeuroLibre-style reproducible preprint for a product: a MyST/Jupyter Book that rebuilds
  its figures from the provenanced data and the project's container environment. Trigger on
  "executable article", "reproducible preprint", "NeuroLibre", "MyST article", "living paper",
  "make the figures reproducible". Produces an article-kind living product.
plane: workflow
stamped: [A, P, E]
delegates_to: [compendium]
---

# Skill: executable-article

Turn a product into a **re-executable article** — figures regenerate from the provenanced outputs in
the project's pinned container, rather than being pasted in. That makes the paper Actionable
(re-runs) and Portable/Ephemeral (rebuilt from spec). History/ledger reads and the save run
directly, in the main thread; you delegate the scaffold, figure-provenance wiring and build to the
**compendium doer**.

Load `plugins/disseminate/references/neurolibre-structure.md` for the scaffold and how each piece
maps to the harness before generating.

> Scope note: you decide *that* an article should exist, for which product, and what it must contain.
> The compendium doer owns the mechanics — MyST invocation, wiring each figure to the run that
> produced it, and building inside the pinned container. Delegate rather than running `myst`
> yourself. That doer reports a figure it could not trace to a run as **unprovenanced** rather than
> embedding it, and a partial build as **partial** rather than as a product. Both of those are
> answers you must pass on rather than smooth over: an article whose figures are pasted-in images
> builds perfectly and reproduces nothing, which is the exact failure this skill exists to prevent.

## When to use
- A product (usually a paper) is analyzed and (ideally) released, and the author wants a
  reproducible executable-article form.
- Do NOT use to write prose (`draft-manuscript`) or to release/DOI a version (`dataset-release`);
  this generates the executable build around the results.

## Steps
1. **Identify inputs** — the product `id`, its comparisons' outputs (`derivatives/cmp-<slug>/`), the
   `containers/` recipe (for the environment), and the dataset's published location (the
   `dataset-release` DOI or the DataLad sibling — from the ledger). If the dataset is unreleased,
   note that repo2data should point at the sibling and a DOI be wired at release.
2. **Scaffold the article via the compendium doer** (per the reference) at `article/` (or the
   author's path): `myst.yml`, `paper.md`, `content/` figure notebooks, and `binder/` with an
   environment derived from `containers/` plus a `data_requirement.json` (repo2data) resolving the
   published dataset. `repo2data` has no skill yet, so the doer will report that part as not built —
   declare the requirement and note it as pending rather than writing a fetch script.
   > "scaffold a MyST article for product `<id>` at `article/`, wire its figures to the runs that
   > produced `derivatives/cmp-<slug>/`, and build it in the project's container."
3. **Wire figures to provenance** — each `content/` notebook computes its figure from the
   provenanced `derivatives/…` outputs (not a static image), so the build reproduces them. The
   compendium doer resolves each figure's output path to its producing run commit and reports any it
   cannot. **Carry an `unprovenanced:` list into your own report; do not drop it** — a figure with no
   producing run is the one thing that makes the article's central claim untrue.
4. **Register + save** — add the article path to the product's `outputs[]`; save:
   ```bash
   datalad save -m "$(printf 'executable-article: scaffold NeuroLibre article for <id>\n\nDSH-Op: executable-article\nDSH-Stage: disseminate\nDSH-Product: <id>')"
   ```
   Add a `DSH-Binding:` line copied from the compendium doer's report.
5. **Report** — the article path, the compendium doer's build result (`built` / `partial` /
   `failed` / `unavailable`) and whether it was **pinned**, any `unprovenanced:` figures, what still
   needs wiring (e.g. the dataset DOI once released, the `repo2data` fetch), and the next step:
   `link-outputs` to relate the article to the dataset (`Documents`) and paper (`IsSupplementTo`).
   An unpinned build and a pinned one are different results; report which you got.

## Constraints
- Figures must regenerate from provenanced outputs + the pinned environment — do not embed static
  images as the source of truth; the article's value is re-executability.
- **Do not run `myst` yourself.** Delegate to the compendium doer, which checks the tool, wires
  provenance and builds in the container. A planner that invokes the build directly skips both
  checks and can report a green build for an article that reproduces nothing.
- **Never report an article as reproducible, or as built, on the strength of a successful `myst`
  exit.** MyST exits 0 with unresolved references and missing figures. Pass on the doer's warning
  count and its `unprovenanced:` list verbatim.
- The `binder/` environment derives from the project's container recipe/digest — keep it consistent
  with what analyses actually ran in; do not invent dependencies.
- repo2data points at the *published* dataset (DOI or sibling) — never a local absolute path.
- Record the article under the product's `outputs[]`; keep the ledger schema-valid. Run DataLad
  yourself; delegate the scaffold and build to the compendium doer.
