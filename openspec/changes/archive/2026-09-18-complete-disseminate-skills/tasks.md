## Status

The skill landed in `29d1532`; this change records the reasoning, the spec delta, the routing
fixture and the count corrections that pass deliberately left undone. Complete as of 2026-09-18.
Ready to archive.

## 0. Minimal working core

All of it, and the skill is already on disk. What this change adds is the `openspec/specs/disseminate`
delta, one routing task, and the three stale skill counts.

Deliberately **not** here: any modelling of the review process, a venue database, scope matching, or
an expected-decision date. The skill records what happened; it does not advise where to submit.

## 1. The skill

- [x] 1.1 `plugins/disseminate/skills/submission-track/SKILL.md` — `stamped: [M, T]`,
      `delegates_to: [datalad]`. Implements the `submissions[]` shape settled in
      `extend-ledger-for-planned-skills` rather than re-deciding it.
- [x] 1.2 Registered in `plugins/disseminate/.claude-plugin/plugin.json`.
- [x] 1.3 The reason the shape matters: a submission history is the part of a project's record most
      often destroyed by being updated. The natural implementation — `venue`, `status` and
      `decision` as fields on the product — loses the first rejection the moment the paper goes
      somewhere else, and that is precisely what a co-author or a funder report asks for.

## 2. The refusals

- [x] 2.1 **Never overwrite or delete a prior submission entry.** A resubmission appends.
- [x] 2.2 **Never fold submission state into `product.status`.** Submitted, under review, rejected
      and revising are all `in-progress`; only a release makes a product `released`. Overloading one
      field with two lifecycles makes a rejection read as a regression.
- [x] 2.3 **Never infer a status or decision.** Elapsed time is not evidence a paper is under review,
      and `revision-requested` is not evidence of eventual acceptance.
- [x] 2.4 **Never record an outcome that has not happened.** A ledger that says `accepted` before the
      letter arrives is a false administrative record in the file a funder report is generated from.
- [x] 2.5 **Never paraphrase a decision into something more favourable.** If the venue said reject,
      the field says reject; its whole value is that it is quotable.
- [x] 2.6 **Never invent a venue name, manuscript id or date.** A remembered date is a guess in a
      field that reads as a fact.
- [x] 2.7 **Never record reviewer identities** or paste reviewer text that names people. The ledger
      is committed to a dataset that may be published.

## 3. Wire it into the surrounding documents

- [x] 3.1 `README.md` — *(planned)* marker dropped and the entry rewritten, in `29d1532`. The table
      row that omitted `submission-track` was corrected in `complete-analyze-skills`, which
      reconciled the whole table.
- [x] 3.2 **Three stale counts corrected.** `openspec/specs/disseminate/spec.md` said "eight planner
      skills" — it is nine. The `disseminate` entry in `.claude-plugin/marketplace.json` enumerated
      eight by name and omitted this one. Both now say nine and name it.
- [x] 3.3 `docs/end-to-end-workflow.md` — the Stage-8 step and the decision-record table drop the
      marker, and the step states the append rule.
- [x] 3.4 One routing task in `bench/tasks/routing-lifecycle.yaml`. 41 → **42**, which restores the
      suite's "one task per built planner skill" claim in full for the first time since `29d1532`.
      Its near-miss note: a route that updates one venue field in place loses the rejection, which is
      the entry the history exists for.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at 67 skills.
- [x] 4.2 `python3 tests/check-bench-fixtures.py` — clean at 42 tasks.
- [x] 4.3 `npm run spec:validate` — passes with this change present.
- [x] 4.4 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.5 `python3 schemas/validate-ledger.py examples/project.yaml` — valid; `submissions[]` was
      added by `extend-ledger-for-planned-skills` and is already exercised by the example.
- [x] 4.6 `bash tests/e2e-smoke.sh` — unchanged at 95. **This change adds no test coverage.**
- [x] 4.7 Merged spec diffed after archive — addition only, no scenario dropped.
