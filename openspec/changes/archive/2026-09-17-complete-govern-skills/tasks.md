## Status

Complete as of 2026-09-17. All tasks checked. Ready to archive.

## 0. Minimal working core

All of it. Four planner skills over doers that already exist, so there is no capability half to
defer. The amended depth convention in `openspec/README.md` is what makes landing them together
correct: none of the four points at something that is not there.

Deliberately **not** here: a LinkML STAMPED schema, funder DMP templates, and any modelling of
consent scope or data-use restrictions. The first two are separate changes; the third the ledger
does not carry, and these skills say so rather than implying a structured guarantee.

## 1. The skills

- [x] 1.1 `plugins/govern/skills/init-ledger/SKILL.md` — `stamped: [M, T]`, `delegates_to:
      [datalad]`. Scoped to the **brownfield** case rather than the README's "called by / extends
      `project/new-project`", which would have duplicated a skill that already writes the ledger.
      Step 1 is a refusal: if `project.yaml` exists, stop.
- [x] 1.2 `plugins/govern/skills/dmp/SKILL.md` — writes the plan, then extracts one `kind: dmp`
      obligation per commitment the plan makes. The report's required output is **the list of
      sections the user still has to fill**, because a DMP that looks finished and is not is the
      failure mode.
- [x] 1.3 `plugins/govern/skills/ethics-track/SKILL.md` — implements the ledger shape settled in
      `extend-ledger-for-planned-skills` (convention 5 of `docs/project-ledger.md`) rather than
      re-deciding it. An amendment is a new `log:` entry, never an edit.
- [x] 1.4 `plugins/govern/skills/stamped-assess/SKILL.md` — `delegates_to: [bids, datalad]`, seven
      dimensions, no total, `unassessed` as a first-class answer.
- [x] 1.5 `plugins/govern/references/stamped.md` — the normative requirement ids S.1 … D.3.
      **README has claimed this file existed since the retrofit and it did not.** An installed
      plugin cannot read the repository's `docs/` tree, so a skill citing `docs/stamped.md` would
      work in the source layout and break once installed. The file names `docs/stamped.md` as
      canonical and declares itself the bug on disagreement.
- [x] 1.6 Register all four in `plugins/govern/.claude-plugin/plugin.json`; version 0.1.0 → 0.2.0,
      description and keywords rewritten.

## 2. The refusals

These are the substance of the change. `govern` is the plugin most likely to be asked a question
whose honest answer is "a person decides that".

- [x] 2.1 `init-ledger` never overwrites, migrates or repairs an existing ledger, and **never
      backfills the log** — the first entry records where the record begins. A reconstructed history
      is indistinguishable from a kept one, and the honest gap is what makes the rest trustworthy.
- [x] 2.2 `init-ledger` creates no `obligations`, `products` or `contributors` entries. An obligation
      nobody committed to, or an author who has not confirmed their role, is a fabricated
      administrative claim.
- [x] 2.3 `dmp` never asserts a funder requirement, deadline, retention period or repository mandate
      it did not read from a supplied template or hear from the user. A recalled funder policy is
      plausible, specific, wrong often enough to matter, and goes into a document someone signs.
- [x] 2.4 `ethics-track` **never computes an expiry from an approval date**, and never infers a
      protocol number. A wrong expiry is worse than a missing one: the renewal reminder fires after
      the approval lapsed, which silently defeats the only thing the skill is for.
- [x] 2.5 `ethics-track` never rules on whether a use is within an approval's scope, and never marks
      an ethics obligation `met` itself.
- [x] 2.6 `stamped-assess` reports a dimension it could not check as **`unassessed`, never zero and
      never omitted** — the contract `annotate` established for `unavailable` vs `unannotated`.
      Silence reads as a pass and a zero reads as a failure; both are wrong when the truth is "not
      checked".
- [x] 2.7 `stamped-assess` produces **no composite score**, and writes no score into the ledger's
      structured fields — there is no schema field for one, and an assessment is an observation at a
      moment rather than a commitment.
- [x] 2.8 None of the four states that anything is compliant, approved, reproducible, FAIR or
      publication-ready.

## 3. Wire them into the surrounding documents

- [x] 3.1 `README.md` — four *(planned)* markers dropped, each entry rewritten to name its refusal.
- [x] 3.2 `.claude-plugin/marketplace.json` — the `govern` description now names all seven skills.
- [x] 3.3 `docs/end-to-end-workflow.md` — the "Recommended process" step 2 told the reader to stand
      up governance with `govern/dmp` and `govern/ethics-track` **before data exists**, which is the
      earliest instruction the harness gives and named two skills that did not exist. Now they do,
      and the greenfield/brownfield split is stated. The ranked-gap entry for STAMPED auditing and
      self-hosted distribution is updated too.
- [x] 3.4 **`add-deidentify-skill` task 3.3 closed.** It had been blocked on `ethics-track` since
      that change was written. Both ends of the contract now exist: `ethics-track` writes the
      `kind: ethics` obligation and refuses to close it; `curate/deidentify` step 7 resolves it with
      `resolved_by`. Neither can close it by assertion, because the schema requires `resolved_by`
      when status is `met`.
- [x] 3.5 Four routing tasks in `bench/tasks/routing-lifecycle.yaml`, keeping the suite's "one task
      per built planner skill" claim true. 28 → 32 tasks.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 53 → 57 skills.
- [x] 4.2 `python3 tests/check-bench-fixtures.py` — clean at 32 tasks; every new
      `expected_delegates_to` resolves to an agent-providing plugin.
- [x] 4.3 `npm run spec:validate` — passes with this change present.
- [x] 4.4 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.5 `bash tests/e2e-smoke.sh` — unchanged at 95; these are planner skills with no script and
      no new assertion. Stated rather than left implicit: **this change adds no test coverage.** Four
      skills' operating procedures are prose, and nothing in the suite exercises them.
- [x] 4.6 OpenCode install rewrite — frontmatter intact, the `references/stamped.md` path rewritten
      to the installed bundle.
