---
name: reporting-checklist
description: >
  Apply the right reporting guideline to a manuscript product — an EQUATOR checklist (CONSORT,
  STROBE, PRISMA, ARRIVE) or, for neuroimaging, COBIDAS — and record item-by-item compliance.
  Trigger on "reporting checklist", "CONSORT", "STROBE", "PRISMA", "ARRIVE", "COBIDAS", "reporting
  guideline", "is the paper compliant", "checklist for submission". Produces a completed checklist
  artifact for the product.
plane: workflow
stamped: [M]
---

# Skill: reporting-checklist

Attach the correct reporting guideline to a manuscript and work through it item by item, so the
paper meets the standard its study type requires and the checklist ships with submission. This is
completeness **Metadata** — a machine-and-reviewer-checkable record of what the paper reports. The
save runs directly, in the main thread.

Load `plugins/disseminate/references/equator-guidelines.md` to pick the right guideline before
starting. Its table also says which guidelines are **bundled** — whose item text is on disk — and
that is what decides whether this skill can produce a checklist at all.

> 🔧 **Whether an item is *adequately* reported is the author's judgement, and a reviewer's.** This
> skill records where each item is addressed and which are not addressed yet. It does not assess the
> quality of what is written there.

## When to use
- A manuscript product exists (`disseminate/draft-manuscript`) and needs a reporting-guideline pass,
  typically before submission.
- Do NOT use to write the manuscript (`draft-manuscript`) or to release/cite it (`dataset-release`).

## Steps
1. **Pick the guideline** — from the study design (see the reference): RCT → **CONSORT 2025**;
   observational → **STROBE**; systematic review/meta-analysis → **PRISMA 2020**; animal research →
   **ARRIVE 2.0**; neuroimaging methods reporting → **COBIDAS**, *in addition to* the design
   guideline rather than instead of it. Confirm with the author if ambiguous.
2. **Open the bundled file, and stop if there is none.**
   ```bash
   ls plugins/disseminate/references/equator/ plugins/disseminate/references/cobidas/
   ```
   STARD, TRIPOD and CARE are catalogued in the reference and **not bundled**. If the applicable
   guideline is one of those, report that no checklist can be produced, name the guideline and the
   EQUATOR library as the place to get it, and stop. Do not reconstruct the items.
3. **Instantiate the checklist from the bundled text** — write `manuscript/checklists/<guideline>.md`
   with each item **copied from the reference file**, in its order, with its number, and a status
   (`reported: <section/page>` | `not-applicable: <why>` | `TODO`). The item wording is the
   guideline's; only the status column is yours. Pre-fill items the harness can evidence from the
   manuscript and ledger — the bundled file's closing section names which ones those are — and leave
   the rest `TODO` for the author.
4. **Register + save** — add the checklist path to the product's `outputs[]`; save:
   ```bash
   datalad save -m "$(printf 'reporting-checklist: <guideline> checklist for <id>\n\nDSH-Op: reporting-checklist\nDSH-Stage: disseminate\nDSH-Product: <id>')"
   ```
5. **Report** — the guideline chosen **and its version**, how many items are `reported`,
   `not-applicable` and `TODO`, and the gaps the author must close before submission (e.g. a missing
   pre-registration → `govern/preregister`). A checklist whose items are mostly `TODO` is a
   successful outcome of this skill and an unfinished paper; say both.

## Constraints
- **Never write a checklist item from memory.** Every item comes from a bundled reference file,
  copied, in order. A checklist assembled from recall is the precise failure these guidelines exist
  to prevent: it looks complete, it is missing the items the author would have most wanted to be
  reminded of, and nothing about the artifact reveals which.
- **Never produce a partial checklist for an unbundled guideline.** Report that it is not bundled and
  name the source. "Here are the items I could recall" is worse than nothing, because it will be
  submitted.
- **Never edit an item's wording** to fit the paper — not to shorten it, not to make it applicable.
  The wording is the standard; the status column is the assessment.
- Choose the guideline by study design, not convenience; when in doubt, ask.
- **Mark an item `reported` only with a real section or page pointer.** Never claim compliance you
  cannot evidence; unknowns stay `TODO`. `not-applicable` needs a reason, because an item marked
  not-applicable without one is indistinguishable from an item skipped.
- **Never state that the paper is compliant, ready, or meets the guideline.** This skill produces a
  record of where things are reported. Whether that reporting is adequate is the author's and the
  reviewer's judgement.
- Record the checklist under the product's `outputs[]`; keep the ledger schema-valid. Run the save
  yourself.
