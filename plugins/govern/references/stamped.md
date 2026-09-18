# STAMPED normative requirements (reference)

The checklist backbone `govern/stamped-assess` scores against. Requirement ids are stable and are
what a report cites — score against `P.1`, not against "Portability", because a dimension usually
has more than one requirement and they fail independently.

**Canonical source: [`docs/stamped.md`](../../../docs/stamped.md).** This file exists because an
installed plugin has no access to the repository's `docs/` tree, so a skill that cited it would
work in the source layout and break once installed. If the two disagree, `docs/stamped.md` wins and
this copy is the bug.

## Self-containment (S)

- **S.1** — all modules essential to replicate execution MUST be reachable within one top-level
  research object (literally, or by explicit reference: subdatasets, registered URLs).
- **S.2** — license declarations MUST be retrievable alongside what they govern.

## Tracking (T)

- **T.1** — persistent content identification MUST be recorded for all components.
- **T.2** — all components SHOULD use the same content-addressed VCS.
- **T.3** — provenance of all modifications MUST be recorded.
- **T.4** — code-driven provenance SHOULD be captured programmatically, and MUST include component
  versions.

## Actionability (A)

- **A.1** — sufficient instructions to reproduce all results MUST be present.
- **A.2** — procedures SHOULD be executable specifications (`git clone`, `datalad rerun`,
  `conda env create`, `docker compose`) rather than prose.

## Modularity (M)

- **M.1** — components SHOULD be organized modularly.
- **M.2** — modules MAY be included directly or linked as subdatasets.
- **M.3** — each module's license SHOULD be declared independently and checked for compatibility at
  combination boundaries.

## Portability (P)

- **P.1** — procedures MUST NOT depend on undocumented host state.
- **P.2** — computational environments MUST be explicitly specified.
- **P.3** — environment definitions MUST be version controlled.

## Ephemerality (E)

- **E.1** — results SHOULD be produced in ephemeral environments rebuilt from spec.

## Distributability (D)

- **D.1** — all referenced modules MUST be persistently retrievable by others.
- **D.2** — environment specs SHOULD support reproducible builds.
- **D.3** — each module SHOULD carry an explicit license with a resolvable identifier (SPDX/REUSE).

## How to score these

Three things matter more than the score itself:

1. **MUST and SHOULD are different findings.** An unmet MUST is a gap; an unmet SHOULD is a
   trade-off the project may have made deliberately. Report which it is.
2. **Evidence, not inference.** `P.1` is about undocumented host state, and the presence of a
   container recipe does not establish that runs used it — only the run records do. A score whose
   evidence line reads "there is a Dockerfile" is not a score for `P.1`.
3. **No evidence means `unassessed`.** Not zero. A zero claims the requirement was checked and
   failed; `unassessed` says it could not be checked, and names what would make it checkable. The
   difference is the same one `annotate` draws between `unannotated` and `unavailable`.

There is deliberately **no total**. `docs/stamped.md` treats each principle as a spectrum rather
than a pass/fail gate, so averaging the dimensions implies a pass mark the framework declines to
set.
