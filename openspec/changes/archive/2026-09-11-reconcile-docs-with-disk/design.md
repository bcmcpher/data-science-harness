## Context

Three kinds of drift are mixed together in the README, and they need different treatments:

1. **Wrong facts** — the plugin count, `plugin.yaml`, the STAMPED expansion. These are simply
   incorrect and get corrected.
2. **Aspirational content presented as current** — the unbuilt skill tables, `harness.yaml`, the rich
   ledger example, `analyze/literature-search`. These describe a plausible future; presenting them in
   the present tense is what makes them a problem.
3. **Omissions** — the Repository Structure block, the Install section's silence about OpenCode.

## Goals / Non-Goals

**Goals:**
- A contributor following the README's Contributing steps succeeds.
- One STAMPED expansion, everywhere.
- The mechanical subset of this drift caught by the lint rather than by reading.

**Non-Goals:**
- Building the unbuilt skills. Marking them as planned is in scope; implementing them is not.
- Rewriting the README's argument. The conceptual sections are accurate and stay.
- Shrinking the file. Length is not the problem.

## Decisions

- **Aspirational content is marked, not deleted.** The unbuilt skill tables communicate design
  intent, which is worth keeping — but in a section labelled as planned, with the built-versus-planned
  distinction visible per row. Deleting them would lose real design work.
- **The ledger example is regenerated from `examples/project.yaml`**, which already validates against
  the schema, rather than hand-corrected. That makes the example verifiable by running the validator
  the repo already ships.
- **`docs/stamped.md` wins the acronym conflict**, because it is the distillation of the source paper
  and the letters are load-bearing — every skill's `stamped:` field indexes into them, and the lint
  validates against that set.
- **`harness.yaml` and `analyze/literature-search` are marked planned**, not deleted, since both are
  referenced in the design narrative.
- **The lint check covers only what is mechanically checkable** — the manifest filename the README
  tells contributors to edit, and the plugin count. Checking prose claims in general is not
  tractable, and a check that half-works would be its own drift.
- **The roadmap section is deleted, as it instructs.** Its content now lives in
  `openspec/changes/`, where it is validated and tracked.

## Risks / Trade-offs

- **A doc-claims lint check is unusual and could become brittle** if the README is restructured. It
  is scoped to two specific, stable claims for that reason.
- **Marking content as planned invites it to stay unbuilt indefinitely.** That is a real cost, and
  the honest alternative — deleting it — loses the design intent. The OpenSpec change list is where
  planned work should actually live going forward.
