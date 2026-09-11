## 0. Minimal working core

All of it. This change is already the smallest version that works — a planner over an existing doer,
with no new capability plugin. The deferred half is the tooling (defacing, PHI detection,
date-shifting), which is a separate change and is not required for this one to land.

## 1. The skill

- [ ] 1.1 `plugins/curate/skills/deidentify/SKILL.md` with `plane: workflow`, `stamped: [M, T]`,
      `delegates_to: [datalad]`, and the three required sections.
- [ ] 1.2 Write `## Steps` as: establish what identifiers are present, decide the approach per
      category, run each removal through the datalad doer, record the result and the residual risk.
- [ ] 1.3 Write `## Constraints` with the refusal rule — no statement that data is de-identified
      unless a recorded action produced it, and residual risk is required, never blank.
- [ ] 1.4 Mark the tool-running itself as 🔧 Do-it-yourself, matching the convention in
      `docs/end-to-end-workflow.md`. The skill scaffolds the decision and the record.
- [ ] 1.5 Register it in `plugins/curate/.claude-plugin/plugin.json` — the lint requires
      bidirectional registration.

## 2. The ledger shape

- [ ] 2.1 Decide whether the record is a `log:` entry alone or also an `obligations[]` resolution,
      and state it in the skill body with the field names spelled out.
- [ ] 2.2 If a new field is needed, extend `schemas/project.schema.json` in this change, per the
      ledger's own rule that the schema grows in the same commit as the skill that writes to it.
- [ ] 2.3 Confirm `examples/project.yaml` still validates.

## 3. Wire it into the surrounding documents

- [ ] 3.1 `docs/end-to-end-workflow.md` Stage 2 — replace the ⚠️ Scaffolding gap callout with the
      skill, and keep a 🔧 Do-it-yourself note for the tooling that is still the researcher's.
- [ ] 3.2 Remove `curate/deidentify` from the ranked gap list in the same file, or move it down to
      name the remaining tooling gap rather than the whole step.
- [ ] 3.3 Point `govern/ethics-track`'s obligation at the skill once it exists. (Blocked: that skill
      is not built — record the intended link in this change's notes instead.)

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors; skill count grows by 1.
- [ ] 4.2 `python3 schemas/validate-ledger.py examples/project.yaml` passes.
- [ ] 4.3 Read the skill body and confirm no sentence in it can be quoted as a compliance claim.
- [ ] 4.4 Confirm `docs/end-to-end-workflow.md` no longer lists de-identification as having no skill.
