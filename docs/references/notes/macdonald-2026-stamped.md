# Macdonald et al. (2026) — STAMPED principles

## Citation

Macdonald, A., Baker, M., To, I., & Halchenko, Y. O. (2026, May). *STAMPED principles for
reproducible research objects.* Center for Open Neuroscience, Dartmouth College.
Local copy: `resources/Macdonald_STAMPED_2026.pdf`. Checklist: `checklist.stamped-principles.org`;
worked examples: `examples.stamped-principles.org` — `[macdonald2026stamped]`

> The distillation this harness works from is [`docs/stamped.md`](../../stamped.md), which carries
> the normative requirements (S.1, T.1–T.4, A.1–A.2, M.1–M.3, P.1–P.3, E.1, D.1) verbatim in
> RFC 2119 form.

## Core claim

A **research object** — data, code, environment, and metadata as one re-runnable unit — has seven
properties worth naming: **S**elf-containment, **T**racking, **A**ctionability, **M**odularity,
**P**ortability, **E**phemerality, **D**istributability. Each is a *spectrum*, not a pass/fail gate,
which is what makes the framework usable as a maturity vocabulary rather than a certification.

It builds on YODA and the VAMP formulation and generalizes them: YODA remains a concrete dataset
layout; STAMPED describes the full range of properties the object should have.

## What it motivates

STAMPED is not one input among several — it is the framework the entire harness indexes into:

- **`skill-format`** — every harness skill declares a `stamped:` list of letters, and
  `tests/lint-plugins.py` validates those letters against this set. A typo in a STAMPED letter is a
  lint error, which is only meaningful because the set is closed and defined here.
- **`datalad`** — Tracking (T.1–T.4) is why DataLad is the default run path rather than one option.
  T.4's "code-driven provenance SHOULD be captured programmatically and MUST include component
  versions" is the requirement `datalad run` satisfies and a bare shell command does not.
- **`containers`** — Portability (P.1–P.3) and Ephemerality (E.1) are why a pinned `.sif` is a
  capability rather than a convenience.
- **`analyze`** — Ephemerality is the justification for exploratory comparisons having zero ledger
  footprint. The durable object is the specification; the run is disposable.
- **`disseminate`** — Distributability (D.1) is why `disseminate/publish` verifies a fresh clone can
  `datalad get` rather than reporting a successful push.
- **`govern`** — `qc-review`'s STAMPED self-assessment is a direct instantiation of the checklist,
  and the spectrum framing is why it reports per-principle positions rather than an overall verdict.
- **Two-plane architecture** — Modularity (M.1) applied to the harness itself, not just to the
  research objects it produces.

## Where it differs

STAMPED describes properties a research object should have. It does not say who produces them, or
when, or with what tooling. This harness is one answer to that: a set of skills and doers that make
the properties a by-product of ordinary work rather than a checklist applied at the end.

Two places where the harness goes beyond the framework:

- **Administration is treated as a research object.** STAMPED's normative requirements are about
  data, code, and environment. Extending Tracking to funding, ethics, obligations, and credit —
  the Manage & Comply lane — is this project's extrapolation, not a STAMPED requirement.
- **The living compendium is a specific export shape.** STAMPED says modules must be persistently
  retrievable; it does not require a re-executable article or an agent-callable bundle. Those come
  from NeuroLibre and Paper2Agent.

One genuine tension worth naming in the paper: STAMPED's spectrum framing resists exactly the kind of
scoring the `provenance` evaluation probe wants to do. A completeness percentage implies a pass mark
the framework declines to set. The probe should report per-principle evidence rather than a single
STAMPED score.

## Quoted passages

> "Each principle is a **spectrum**, not a pass/fail gate."

Normative examples, from [`docs/stamped.md`](../../stamped.md):

> "T.4: code-driven provenance SHOULD be captured programmatically and MUST include component
> versions."

> "P.1: procedures MUST NOT depend on undocumented host state."

> "D.1: all referenced modules MUST be persistently retrievable by others."
