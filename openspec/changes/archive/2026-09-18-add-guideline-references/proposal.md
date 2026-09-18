## Why

`disseminate/reporting-checklist` and `govern/qc-review` name EQUATOR and COBIDAS with nothing to
cite from. The only material on disk was a one-page index naming which guideline suits which design —
useful for choosing, useless for filling one in. So the skill's operating procedure said "instantiate
the checklist", and the only way to do that was from recall.

A checklist assembled from recall is the exact failure these guidelines exist to prevent, and it is a
failure with no surface. It looks complete. It contains the items everyone remembers — the ones the
author would have covered anyway — and omits the ones nobody does, which are the items the guideline
was written for. Nothing about the artifact says which kind it is, and it ships with the submission.

This change bundles the item text so the checklist is copied rather than recomposed, and makes the
absence of bundled text a refusal rather than an invitation to improvise.

## What Changes

- **Five guidelines bundled verbatim**, each in its own file with its source and its redistribution
  basis: CONSORT 2025, STROBE, PRISMA 2020, ARRIVE 2.0, and COBIDAS as seven tables under
  `references/cobidas/`.
- **CONSORT 2010 → CONSORT 2025.** The index named CONSORT without a version; 2025 superseded 2010 in
  April 2025 and its authors state 2010 should no longer be used.
- `disseminate/reporting-checklist` copies items from the bundled text, refuses for an unbundled
  guideline, and no longer states that a product is compliant.
- `govern/qc-review` reads the two COBIDAS tables a *dataset* can answer — data sharing and
  reproducibility — and reports the check as skipped when the reference is not installed.
- The index records, per guideline, whether it is bundled, and says plainly that this is a licensing
  fact rather than a judgement about the guideline. STARD, TRIPOD and CARE remain unbundled.

## Capabilities

### Modified Capabilities

- `disseminate`: `reporting-checklist` cites bundled guideline text rather than recalling it, and
  each reference file must state its redistribution basis.
- `govern`: `qc-review` reads dataset-level COBIDAS items rather than recalling them, and skips
  rather than improvises when the reference is absent.

## Impact

- New: `plugins/disseminate/references/equator/{consort-2025,strobe,prisma-2020,arrive-2.0}.md`,
  `plugins/disseminate/references/cobidas/*.md` (seven tables)
- Modified: `plugins/disseminate/references/equator-guidelines.md`,
  `plugins/disseminate/skills/reporting-checklist/SKILL.md`,
  `plugins/govern/skills/qc-review/SKILL.md`
- No new plugin, skill, agent or schema. Skill and plugin counts do not move.
- Split out of `deepen-bids-nipoppy`, whose task list predicted it: "a references change bundled into
  a toolbox change - if it grows, it belongs in its own change rather than here."
