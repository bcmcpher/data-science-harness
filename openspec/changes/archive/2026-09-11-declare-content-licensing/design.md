## Context

The root `LICENSE` predates the repository having substantial prose content. `paper/myst.yml` was
the first place the split became unavoidable, because a journal requires a content licence, and it
was solved locally rather than repository-wide.

## Goals / Non-Goals

**Goals:**
- A reuser can tell, per path, which terms apply, without reading the README.
- The identifiers are resolvable — SPDX short identifiers, not prose descriptions.
- The repository complies with the STAMPED requirement it publishes.

**Non-Goals:**
- **Full REUSE compliance.** That requires verbatim licence texts under `LICENSES/`, and the CC BY
  4.0 legal code must be reproduced exactly or not at all. Transcribing it from a summary would
  produce a document that looks authoritative and is not. `REUSE.toml` plus the CC-specified notice
  is correct and sufficient for marking; adding `LICENSES/` with verbatim texts is a follow-up that
  should copy from the canonical source.
- Relicensing anything. MIT stays on the code; the content was never separately licensed, so
  declaring CC BY 4.0 on it is a clarification by the sole copyright holder, not a change of terms.

## Decisions

- **Content is CC BY 4.0, not CC0.** Attribution is the point: the harness's argument is that credit
  and provenance should travel with a work, and CC0 would waive exactly that for its own content.
  CC BY 4.0 also matches `paper/myst.yml` and Aperture Neuro's requirement, so the paper and the
  repository agree.
- **The boundary is by path, not by file type.** `bin/`, `tests/`, `schemas/*.py` and the JSON
  manifests are code; `plugins/**/*.md`, `docs/`, `templates/`, `openspec/`, `paper/` are content.
  A `SKILL.md` is prose that instructs a model, and treating it as code would make the boundary
  turn on what reads the file rather than what the file is.
- **`REUSE.toml` rather than `.reuse/dep5`.** It is the current REUSE spec's format, and a
  single-file declaration a human can read is more useful here than a Debian-derived one.

## Risks / Trade-offs

- **Two licences means a reuser has to check which applies.** Unavoidable once the content is not
  software, and the alternative — leaving MIT to cover prose by implication — is the ambiguity this
  change exists to remove.
- **Declaring `REUSE.toml` without `LICENSES/` will fail the `reuse lint` tool.** Stated as a
  non-goal above rather than hidden; the file is still correct as a declaration.
