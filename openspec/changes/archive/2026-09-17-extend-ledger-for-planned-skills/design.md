## Context

`schemas/project.schema.json` is closed at every level, and five changes are about to want fields in
it. This change audits what the fifteen planned skills write, decides the shape once, and leaves the
skill changes with nothing to negotiate.

The audit result is the important part: the schema already covers most of it. `obligation.kind` has
`dmp` and `ethics`; `logEntry.op` has no enum. Six of the fifteen skills need no schema at all. That
makes this a small, deliberate change rather than a redesign.

## Goals / Non-Goals

**Goals:**
- One schema edit for the whole breadth pass.
- An obligation that is `met` says what met it, checkably.
- Submission history that survives a rejection and a resubmission.

**Non-Goals:**
- **The richer aspirational ledger sketched in the README.** Still tracked as documentation drift,
  per the spec's Purpose. This change adds three things, not a v2.
- **Enumerating `logEntry.op`.** It is open, deliberately, and closing it would make every new skill
  a schema change — the exact problem this change exists to avoid.
- **Writing any skill.** Five later changes do that.
- **A structured ethics record.** See the decision below.

## Decisions

- **`submissions[]` on the product, not new `product.status` values.** A submission is orthogonal to
  a product's lifecycle: a paper under review is `in-progress`, and so is the same paper after a
  rejection. Extending `status` would force one field to answer two questions and would erase the
  first submission when a second one starts. An array keeps the history, which is what
  `submission-track` exists to track.

  Each entry carries `venue` (required — a submission with no destination is not a submission),
  `submitted` (date), `status` from a closed set (`preparing`, `submitted`, `under-review`,
  `revision-requested`, `accepted`, `rejected`, `withdrawn`), `decision` for the free-text outcome,
  and `ref` for a manuscript id or URL.

- **`resolved_by` is separate from `ref`, and required when `status: met`.** `ref` is documented as
  "Pre-registration id / URL or other external reference". A commit SHA, a log entry's timestamp or
  a product id is internal evidence, and an auditor needs to know which kind they are looking at —
  an external URL can rot or be fabricated, a commit SHA can be checked against the dataset in hand.
  Reusing `ref` for both would make the two indistinguishable.

  It is enforced with JSON Schema `if`/`then` rather than left as prose, because this repository's
  own convention is to ground a requirement in a check that exists. A status flip that records
  nothing is precisely the failure the ledger exists to prevent, and it is trivial to do by accident.

- **Ethics protocol data is an `obligations[]` entry plus `log:` entries, not a new structured
  field.** `kind: ethics` already exists; `due` carries the expiry, which is the date that drives a
  renewal reminder; `ref` carries the protocol number or URL. Approval and amendments are appended to
  `log:`, where the append-only rule already gives an amendment history for free. A dedicated
  `ethics:` block would duplicate three fields to gain one (the approval date) and would need its own
  append-only discipline to match what `log:` already guarantees.

  This is the decision most likely to want revisiting. If `govern/ethics-track` turns out to need
  multi-protocol tracking or per-amendment scope changes, that is a later change with evidence behind
  it, not a guess made now.

- **`kind: milestone` rather than a `milestones:` registry.** A milestone is a commitment with a
  date, which is what an obligation is. A parallel registry would duplicate `id`/`description`/`due`/
  `status` and would need `govern/obligations` taught to read two places.

## Risks / Trade-offs

- **`met` implies `resolved_by` can reject an existing ledger.** Nothing in the repository has a
  `met` obligation, so the blast radius today is zero — but a user with a hand-written ledger would
  see a validation error on upgrade. Accepted: the error names the field, and the alternative is an
  obligation registry where "met" means nothing in particular.
- **Three additions is three chances to guess wrong.** Mitigated by each one having a named skill
  that needs it. Nothing here is speculative; a field with no skill behind it was left out.
- **Deciding ahead of the skills inverts a stated convention.** The proposal argues why, and the
  amended depth convention in `openspec/README.md` now says the same thing about planes. If a later
  skill needs a field this pass missed, it grows the schema in its own commit — the original rule
  still applies to the one-skill case.
