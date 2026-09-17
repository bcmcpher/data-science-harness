## Status

Complete as of 2026-09-17. All 16 tasks checked. Task 3.3 was blocked on `govern/ethics-track`,
which landed the same day in `complete-govern-skills`; the link is real rather than recorded as an
intention. Ready to archive.

Task 2.1/2.2's open question was settled ahead of this change by
`extend-ledger-for-planned-skills`, which added `resolved_by` to `$defs/obligation` and made it
required when `status: met`. The skill therefore resolves an obligation by naming the run, and the
schema refuses a status flip that records nothing.

## 0. Minimal working core

All of it. This change is already the smallest version that works — a planner over an existing doer,
with no new capability plugin. The deferred half is the tooling (defacing, PHI detection,
date-shifting), which is a separate change and is not required for this one to land.

## 1. The skill

- [x] 1.1 `plugins/curate/skills/deidentify/SKILL.md` with `plane: workflow`, `stamped: [M, T]`,
      `delegates_to: [datalad]`, and the three required sections.
- [x] 1.2 Write `## Steps` as: establish what identifiers are present, decide the approach per
      category, run each removal through the datalad doer, record the result and the residual risk.
      Eight steps; step 1 insists on inspecting rather than assuming, and names facial anatomy in
      structural imaging as an identifier that is not a metadata field. Step 3 records the plan
      *before* running anything, so an interrupted removal still leaves the intent on the record.
      Step 5 separates "the command exited 0" from "the field is gone".
- [x] 1.3 Write `## Constraints` with the refusal rule — no statement that data is de-identified
      unless a recorded action produced it, and residual risk is required, never blank. Also: never
      a compliance determination, never an answer to "can I share this?", never a self-selected
      tool or invented command line, and never deleting an original unasked (git-annex will not
      return content dropped before it was committed).
- [x] 1.4 Mark the tool-running itself as 🔧 Do-it-yourself, matching the convention in
      `docs/end-to-end-workflow.md`. The skill scaffolds the decision and the record.
- [x] 1.5 Register it in `plugins/curate/.claude-plugin/plugin.json` — the lint requires
      bidirectional registration. Plugin description and keywords updated; version 0.1.0 → 0.2.0.

## 2. The ledger shape

- [x] 2.1 Decided: **both.** A `log:` entry always (the plan in step 3, the result in step 6), and
      an `obligations[]` resolution only when such an obligation exists — step 7 refuses to create
      one retroactively. Field names are spelled out in the skill body.
- [x] 2.2 The field was needed and landed in `extend-ledger-for-planned-skills` instead, because
      four concurrent changes wanted the same closed schema. `resolved_by` is required when
      `status: met`, enforced by JSON Schema `if`/`then` — so this skill's obligation resolution is
      checkable rather than conventional.
- [x] 2.3 `python3 schemas/validate-ledger.py examples/project.yaml` → `VALID`.

## 3. Wire it into the surrounding documents

- [x] 3.1 `docs/end-to-end-workflow.md` Stage 2 — the callout is replaced by a numbered step 6 for
      the skill, a 🔧 note naming the tools and why the skill will not pick one, and a narrowed ⚠️
      gap that now says the *tooling* is unscaffolded rather than the step.
- [x] 3.2 Ranked gap 3 rewritten to name the remaining tooling gap rather than the whole step.
- [x] 3.3 Point `govern/ethics-track`'s obligation at the skill. **Closed by
      `complete-govern-skills`, same day.** `ethics-track` writes the `obligations[]` entry with
      `kind: ethics`, the protocol number or URL in `ref` and the expiry in `due`, and explicitly
      refuses to mark it `met` itself — it names `curate/deidentify` resolving it with `resolved_by`,
      or `govern/obligations` waiving it with a reason. `curate/deidentify` step 7 is the other half.
      Both ends of the contract now exist and neither can close the obligation by assertion, because
      the schema requires `resolved_by` when status is `met`.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 50 → 51 skills.
- [x] 4.2 `python3 schemas/validate-ledger.py examples/project.yaml` → `VALID`.
- [x] 4.3 Read the skill body: no sentence asserts compliance, anonymization, or fitness to share.
      The constraints name HIPAA, GDPR and Safe Harbor explicitly as things not to claim, because
      the pull toward that language comes from the user's question, not from the skill.
- [x] 4.4 Confirmed: the file now attributes the gap to the tooling, not the step.
- [x] 4.5 **Added:** a `curate-deidentify` routing task in `bench/tasks/routing-lifecycle.yaml`, so
      the suite's "one task per built planner skill" claim stays true. 27 → 28 tasks, fixtures clean.
