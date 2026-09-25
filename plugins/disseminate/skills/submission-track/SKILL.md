---
name: submission-track
description: >
  Record where a product was submitted and what came back — venue, date, status, decision — as an
  append-only submissions[] history on the product, so a resubmission does not erase the first
  venue's outcome. Trigger on "track the submission", "we submitted the paper", "record the
  rejection", "revise and resubmit", "where did we send this", "submission status", "reviewer
  responses". Do NOT trigger to write the manuscript (disseminate/draft-manuscript) or to mint a DOI
  (disseminate/dataset-release).
plane: workflow
stamped: [M, T]
---

# Skill: submission-track

Keep a product's submission history in the ledger, so the path a paper took is recoverable rather
than remembered.

> Ledger shape, settled in `extend-ledger-for-planned-skills`: `submissions[]` on the
> `products[]` entry — `venue` (required), `submitted`, `status`, `decision`, `ref`. It is a
> **history, not a state**: a resubmission appends, and the product's own `status` stays
> `in-progress` throughout. A paper under review and a paper whose submission was rejected are both
> still in progress, so folding submission state into `product.status` would make one field answer
> two questions and erase the earlier attempt. See `docs/project-ledger.md` convention 4.

## When to use
- A product was submitted, or a decision came back, or it is going to a second venue.
- The user asks where something was sent and what happened.
- Do NOT use to write or revise the manuscript (`disseminate/draft-manuscript`), to release a
  dataset version (`disseminate/dataset-release`), or to cross-link products (`link-outputs`).

## Steps

1. **Identify the product** in `products[]`. A submission belongs to a product; if none exists,
   `analyze/manage-product` creates it first — do not invent one.
2. **Read the existing history** and present it: every venue, date, status and decision so far. This
   matters most at a resubmission, where the previous outcome is the context.
3. **Get the facts from the user.** The venue, the submission date, the current status, the
   manuscript id if there is one, and the decision text if one came back. Ask for each you do not
   have. Do not infer a status from elapsed time, and do not infer a decision from a status.
4. **Append or update the current entry**:
   - **New submission** — append `{ venue, submitted, status, ref? }`. Never modify a prior entry to
     point at the new venue.
   - **Status change on the current submission** — update that entry's `status`, and add `decision`
     when the venue reported one. Log what changed.
   - **Accepted** — set `status: accepted` with the decision. The product's own `status` becomes
     `released` only when a version is actually released, which is `dataset-release`'s job, not this
     one.
5. **Validate and save.**
   ```bash
   python3 schemas/validate-ledger.py project.yaml
   datalad save -m "$(printf 'submission-track: <product> -> <venue> <status>\n\nDSH-Op: submission-track\nDSH-Stage: disseminate\nDSH-Product: <product>')"
   ```
6. **Report** the full history, the current state, and what the next step would be — a preprint, a
   revision, a new venue, or a release.

## Constraints

- **Never overwrite or delete a prior submission entry.** A resubmission appends. The record of where
  a paper was rejected is part of its history, and it is the first thing a co-author or a reviewer of
  the project's process will ask about.
- **Never fold submission state into the product's `status`.** `in-progress` covers submitted, under
  review, and rejected. Only an actual release makes a product `released`.
- **Never infer a status or a decision.** Elapsed time is not evidence that a paper is under review,
  and `revision-requested` is not evidence of eventual acceptance. Ask.
- **Never record an outcome that has not happened**, and never write an anticipated decision. A
  ledger that says `accepted` before the letter arrives is a false administrative record in the file
  a funder report is generated from.
- **Never paraphrase a decision into something more favourable.** If the venue said reject, the
  `decision` says reject. This field's value is that it is quotable.
- **Never invent a venue name, a manuscript id, or a submission date.** A remembered date is a guess
  in a field that reads as a fact.
- **Never record reviewer identities**, and do not paste reviewer text that names people. The ledger
  is committed to a dataset that may be published.
- Keep the ledger schema-valid; run the save yourself.
