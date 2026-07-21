# STAMPED principles (distilled)

> Distillation of Macdonald, Baker, To & Halchenko, *STAMPED principles for reproducible
> research objects*, Center for Open Neuroscience, Dartmouth (May 2026) —
> `resources/Macdonald_STAMPED_2026.pdf`. Interactive checklist:
> `checklist.stamped-principles.org`; worked examples: `examples.stamped-principles.org`.

STAMPED is the **operating principle framework** for `data-science-harness`. It gives a shared
vocabulary for the *operational maturity* of a **research object** — a collection of data,
code, environment, and metadata that together represent the research as a complete, re-runnable
unit. It builds on the **YODA** principles and the **VAMP** formulation, and generalizes them:
YODA remains our concrete *dataset layout* (STAMPED's Self-containment + Modularity origin),
while STAMPED describes the full spectrum of properties a research object should have.

Each principle is a **spectrum**, not a pass/fail gate. Requirements use RFC 2119 keywords:
**MUST** = the practical minimum (often what a careful researcher already does), **SHOULD** /
**MAY** = progressively more aspirational, tool-automated practice.

## The seven principles

| Letter | Principle | One-line meaning |
|--------|-----------|------------------|
| **S** | Self-containment | A complete retrieval unit — obtainable and understandable in scope without implicit external state ("don't look up"). |
| **T** | Tracking | The identity and provenance of every component is recorded (content-addressed versions + history). |
| **A** | Actionability | Machine-actionable instructions carry out the procedures — executable specs, not just prose. |
| **M** | Modularity | Independent, composable modules with clear boundaries (separation of concerns). |
| **P** | Portability | Runs on a different host while retaining its STAMPED properties — no undocumented host state. |
| **E** | Ephemerality | Execution happens in disposable environments rebuilt from spec each run. |
| **D** | Distributability | All modules are persistently retrievable by others in a frozen, licensed state. |

## Normative requirements (the checklist backbone)

- **Self-containment** — S.1: all modules essential to replicate execution MUST be reachable
  within one top-level research object (literally or by explicit reference — subdatasets,
  registered URLs). S.2: license declarations MUST be retrievable alongside what they govern.
- **Tracking** — T.1: persistent content identification MUST be recorded for all components.
  T.2: all components SHOULD use the same content-addressed VCS. T.3: provenance of all
  modifications MUST be recorded. T.4: code-driven provenance SHOULD be captured programmatically
  and MUST include component versions.
- **Actionability** — A.1: sufficient instructions to reproduce all results MUST be present.
  A.2: procedures SHOULD be executable specifications (`git clone`, `datalad rerun`,
  `conda env create`, `docker compose`).
- **Modularity** — M.1: components SHOULD be organized modularly. M.2: modules MAY be included
  directly or linked as subdatasets. M.3: each module's license SHOULD be declared independently
  and checked for compatibility at combination boundaries.
- **Portability** — P.1: procedures MUST NOT depend on undocumented host state. P.2: computational
  environments MUST be explicitly specified. P.3: environment definitions MUST be version
  controlled.
- **Ephemerality** — E.1: results SHOULD be produced in ephemeral environments rebuilt from spec.
- **Distributability** — D.1: all referenced modules MUST be persistently retrievable by others.
  D.2: environment specs SHOULD support reproducible builds. D.3: each module SHOULD carry an
  explicit license with a resolvable identifier (SPDX / REUSE).

## Enabling tools (illustrative, tool-agnostic)

STAMPED is tool-agnostic; one tool often serves several principles.

| Principle | Example tooling |
|-----------|-----------------|
| S | git submodules, DataLad, git-annex, DVC, Git LFS |
| T | git, git-annex, DataLad, `datalad run`, OSF/Zenodo DOIs |
| A | Make, Snakemake, Nextflow, CWL, `datalad run`, `git annex addcomputed` |
| M | git submodules, DataLad subdatasets, Kedro |
| P | Docker, Singularity/Apptainer, Nix, conda, `pyproject.toml` |
| E | Docker Compose, Slurm, cloud/CI disposable environments |
| D | Zenodo, PyPI, conda-forge, RO-Crate, DANDI, Software Heritage, signed releases |

## Why STAMPED anchors this harness

- **Modularity (M) justifies the two-plane plugin split.** STAMPED defines a module as a
  separately-distributable unit and calls for separating *analysis code, input data,
  environments, licenses, and results*. We apply the same separation of concerns to the harness
  itself: **capability plugins** (tool mechanics) vs **workflow plugins** (research process).
- **Specification-centric research objects (§3.12.1) ground pre-registered comparisons.** The
  durable object is the *specification* (Self-contained, Tracked, Actionable, Distributable);
  the running code is *Ephemeral*, rebuilt from spec each run. This generalizes pre-registration
  and is the backbone of the confirmatory end of our comparison spectrum.
- **AI-era tracking (§3.12.5) fits an agent-driven harness.** Agent actions are recorded by
  wrapping the invocation in a provenance command (`datalad run`) that captures model, prompt,
  and resulting changes — exactly how our `datalad` capability plugin operates.
- **Assessment is a first-class skill.** `govern/stamped-assess` scores a research object against
  this checklist (the paper ships a LinkML-backed, version-tracked schema), subsuming the older
  compliance-audit + reproducibility-audit ideas into one graded, STAMPED-aligned readout.

## Mapping the Design Rules to STAMPED

Each harness Design Rule is tagged with the STAMPED letter(s) it serves (see README §Design
Rules). For example: "DataLad is the default run path" → **T, A**; "environments are pinned and
containerized" → **P, E**; "research products are persistently retrievable and licensed" →
**D**; "capability vs workflow separation" → **M**.
