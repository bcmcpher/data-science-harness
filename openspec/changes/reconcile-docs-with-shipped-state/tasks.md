# Tasks

**Status:** sections 1–3 complete. Section 4 is the verification record.

## 1. Extend the lint before fixing anything

- [x] 1.1 Add the per-plugin skill-count check to `check_doc_claims`. Parses README table rows whose
      first cell is a backticked plugin name, reads `N skill(s)` from the remaining cells, and
      compares against skill directories on disk.
- [x] 1.2 Add `check_change_links`, scanning `README.md` and `docs/**/*.md` for
      `openspec/changes/<name>`. Distinguishes *archived* (names the archive path, and warns that the
      surrounding sentence is probably stale too) from *never existed*.
- [x] 1.3 Add the enumerated-doer check to `check_marketplace_claims`, via `_capability_doers()` —
      plugins with an `agents/` directory that contain no `plane: workflow` skill, which correctly
      excludes `project` (it ships `coordinator` but is a planner).
- [x] 1.4 Widen `_PLANNER_COUNT` to `planner (plugins|skills)` and make the `skills` form an error.
      The checkable number is of planner plugins; the old wording compared a skill claim against a
      plugin count and read as though 6 planner skills existed rather than 37.
- [x] 1.5 **Run the extended lint against the unfixed tree.** Result: 4 errors — the
      `compendium-cli` row, the two archived links, and the two omitted doers. Each new rule fired
      for its own reason. A rule that cannot be observed failing is not coverage.
- [x] 1.6 Add four selftest cases (stale per-plugin count, archived-change link, omitted doer,
      wrong-unit planner count). Suite: 24 → 28.

## 2. Collapse Stage 4

- [x] 2.1 Delete `## Stage 4 — Checkpoint` from `docs/end-to-end-workflow.md`; renumber 5→4, 6→5,
      7→6, 8→7, including the "When each decision must be finalized" table.
- [x] 2.2 Move checkpointing into *Ongoing — Manage & Comply*, stating what the hook does and what
      the skill adds over it.
- [x] 2.3 Rewrite the README's Research Lifecycle Model table and ASCII diagram for stages 0–7, with
      checkpointing in the lane. Record *why* the stage is gone, so it does not get re-added.
- [x] 2.4 Follow the renumber into `openspec/specs/govern/spec.md` (Stage 5 → 4),
      `openspec/specs/disseminate/spec.md` (Stages 6-8 → 5-7) and `README.md` (Stage 8 → 7).
      `curate`'s Stage 2 is unchanged.
- [x] 2.5 Confirm no machinery keys on the numbers: `schemas/project.schema.json` types `stage` as a
      free string; `examples/project.yaml` and `bench/tasks/routing-lifecycle.yaml` use names.

## 3. Correct the claims

- [x] 3.1 README: the `openspec/` section no longer says `containers` has no toolbox; the two
      archived links re-point to `changes/archive/2026-09-21-add-compendium-capability`; the
      `compendium` and `compendium-cli` rows match disk; "Where the harness stands" describes two
      built planes and names *execution* as what is open.
- [x] 3.2 `.claude-plugin/marketplace.json`: all eight doers enumerated; status sentence rewritten;
      `curate` entry gains `merge-data` and `gen-data-dict`; `containers` and `compendium` entries
      rewritten to match their specs.
- [x] 3.3 `plugins/containers/.claude-plugin/plugin.json` and
      `plugins/compendium/.claude-plugin/plugin.json`: descriptions and keywords match the shipped
      capability. The containers description now states the several-environments model, which was
      the substance of the reframe and was absent entirely.
- [x] 3.4 `docs/motivation.md`, `docs/funding/catalyst-fit.md`: 22 plugins / 77 skills.
- [x] 3.5 `docs/motivation.md`: the MyST sentence scoped to the *compendium doer's* path, since
      `tests/check-paper.sh` runs a real `myst build --strict` over `paper/` in CI. The claim was
      true of the plugin and false of the tool, and it read as the latter.
- [x] 3.6 `docs/end-to-end-workflow.md`: points at `openspec/specs/` for what exists; the containers
      callout names the real toolbox skills and the real direction of travel.
- [x] 3.7 `plugins/analyze/skills/checkpoint/SKILL.md`: the "intentionally deferred" note replaced
      with what the shipped hook actually does and how the skill differs from it.
- [x] 3.8 Narrow the "only exception" claim in `README.md:5` and `docs/motivation.md`.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings, with the extended checks.
- [x] 4.2 `python3 tests/lint-plugins-selftest.py` — 28/28, control (pristine repo) clean.
- [ ] 4.3 Remainder of the gauntlet: bench fixtures, ledger schema, `spec:validate`, `paper:check`,
      e2e.

## Scope limits

- **The lint reads prose, not meaning.** It now catches a stale count, a dead change-link and an
  omitted doer. It cannot catch a sentence that is merely wrong — "the capability plane is uneven"
  would still have passed. Six of the eleven drifts here were found by reading, not by tooling.
- **Nothing here tests a capability.** This change moves prose and extends a static lint. The gaps
  that matter for correctness — `nipoppy` and `process` have no test of any kind, ~19 e2e gate
  assertions pass whether or not the tool exists, and the e2e job never runs on push — are recorded
  in `design.md` and deliberately untouched.
