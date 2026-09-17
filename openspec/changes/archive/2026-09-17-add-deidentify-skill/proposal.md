## Why

De-identification is the one gap in the curate stage that the repository names, ranks, and does not
own. `docs/end-to-end-workflow.md` flags it directly:

> ⚠️ **Scaffolding gap:** **de-identification has no skill.** `govern/stamped-assess` later *checks*
> for PHI exposure and `govern/dmp`/`govern/ethics-track` impose the obligation, but nothing helps
> you actually de-identify (defacing imaging, scrubbing PHI columns, date-shifting). For a
> clinical/neuro workflow this is a high-value, high-risk gap.

The same document ranks it third of the five refinements "most worth a hackathon's attention", and
the ledger's decision-timing table already locks "Ethics scope & de-identification approach" at
Stage 0–2. So the obligation is tracked, the audit exists, and the moment it has to happen is
pinned — but the step itself is unscaffolded.

This matters more than the other unbuilt curate skills because of where it sits. A researcher hits
it in Stage 2, before reaching anything the harness does well, and it is the one curate step where
doing nothing is not a neutral outcome: raw imaging carries identifiable facial anatomy and raw
phenotypic tables carry dates and identifiers. Every other capability the harness offers —
provenance, release, a DOI, a self-hostable deployment — is a way of *distributing* that data.
Making distribution easy while leaving de-identification unscaffolded points the harness's strengths
in the wrong direction.

It is also the gap most likely to stop another group adopting the harness, because most groups who
would want it work with human-subjects data.

## What Changes

- A `curate/deidentify` planner skill: decide what must be removed, drive the tools, record what was
  done and what was deliberately kept.
- Delegation to the existing `datalad` doer so every removal is a provenanced run rather than an
  untracked edit — the point being that de-identification is itself a tracked transformation, not a
  quiet fixup before the record starts.
- A ledger shape for the result: what approach was applied, to which inputs, and what residual risk
  the researcher accepted.
- An `obligations[]` link, so an ethics commitment recorded by `govern/ethics-track` can be resolved
  by an actual recorded action rather than by assertion.

## Capabilities

- `curate` — a new requirement covering de-identification as a provenanced, recorded step.

## Impact

No change to the capability plane. This is a planner skill over `datalad`, in the shape
`curate/annotate` already uses. Tooling that would make it deeper — defacing, PHI column detection,
date-shifting — is deliberately out of scope here; see `design.md`.
