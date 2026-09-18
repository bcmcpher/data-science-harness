## Status

Both skills landed in `29d1532`; this change records the reasoning, the spec delta and the routing
fixtures that pass deliberately left undone. Complete as of 2026-09-18. Ready to archive.

## 0. Minimal working core

All of it, and the skills are already on disk. What this change adds is `openspec/specs/curate`
deltas, two routing tasks, and the Stage-2 document's marker cleanup.

Deliberately **not** here: fuzzy or probabilistic key matching, a value-precedence rule for
conflicting sources, imputation of any kind, and controlled-term lookup (delegated to the `annotate`
doer, whose refusal to recall an identifier `gen-data-dict` inherits).

## 1. The skills

- [x] 1.1 `plugins/curate/skills/merge-data/SKILL.md` — `stamped: [S, T]`, `delegates_to:
      [datalad]`. Produces a new file through `datalad run`; the sources stay as they are so the
      derivation is checkable.
- [x] 1.2 `plugins/curate/skills/gen-data-dict/SKILL.md` — `stamped: [M, A]`, `delegates_to:
      [annotate, datalad]`. Skeleton from the data, meanings from the user or the annotate doer.
- [x] 1.3 Registered in `plugins/curate/.claude-plugin/plugin.json`.
- [x] 1.4 A note on why these two are one change: they share a failure mode. Neither fails loudly.
      A wrong join produces a table; a guessed level coding produces documentation. Both outputs are
      the expected shape, so what must be specified is not the operation but **what is reported
      alongside it**.

## 2. The refusals

- [x] 2.1 `merge-data` **never infers the join key.** A column called `id`, `subject` or
      `participant_id` in two files is not evidence they mean the same thing — one may be a scanner
      id and the other a study id.
- [x] 2.2 `merge-data` **never reports a merge without its row and column arithmetic.** Rows in,
      rows out, keys matched, keys dropped per side. Joining on a mistyped id silently drops every
      row; joining on a non-unique key silently multiplies them. The arithmetic is the only way
      either is visible.
- [x] 2.3 `merge-data` **stops at a zero or near-zero key overlap** and reports an identifier-format
      mismatch. Merging anyway produces an empty or tiny table that will be mistaken for a real one.
- [x] 2.4 `merge-data` never resolves a column-name collision by picking a side, and never reconciles
      conflicting values silently — a disagreement about a participant's age is a data-quality
      finding for the user, not a precedence rule for the harness.
- [x] 2.5 `merge-data` never imputes, forward-fills or converts a unit it was not told about. An
      imputed cell is indistinguishable from a measured one once written.
- [x] 2.6 `merge-data` never edits a source table in place.
- [x] 2.7 `gen-data-dict` **never invents a column's meaning, units or level coding** — not from the
      name, not from what such a variable usually means, not from the distribution. `1 = male` and
      `1 = female` are both common, so a guess is a coin flip written into documentation.
- [x] 2.8 `gen-data-dict` **never restates a column name as its Description.** It adds no
      information and hides the gap, which is worse than leaving the entry out: a column that looks
      described will not be revisited.
- [x] 2.9 `gen-data-dict` never overwrites an existing description, never assumes a unit, and never
      silently drops a level that occurs in the data.
- [x] 2.10 `gen-data-dict` **never emits a controlled-term identifier the annotate doer did not
      return**, and never reports a dictionary as complete while columns are undescribed. The
      undescribed list is a required part of the report — the contract `annotate` set with
      `unannotated` and `stamped-assess` with `unassessed`.

## 3. Wire them into the surrounding documents

- [x] 3.1 `README.md` — both *(planned)* markers dropped and the entries rewritten, in `29d1532`.
- [x] 3.2 `openspec/specs/curate/spec.md` Purpose — now names `merge-data` and `gen-data-dict` and
      what each refuses.
- [x] 3.3 `docs/end-to-end-workflow.md` Stage 2 — markers dropped, and **a stale claim removed**:
      the entry read "`curate/merge-data` *(planned)* *(Agent: `merge-agent`)*". There is no
      `merge-agent` anywhere in `plugins/`; `merge-data` is a planner over the datalad doer. The
      decision-record table's `gen-data-dict` row is updated too.
- [x] 3.4 Two routing tasks in `bench/tasks/routing-lifecycle.yaml`. 39 → 41. Both carry near-miss
      notes: a merge reported without arithmetic looks correct either way, and `gen-data-dict` sits
      next to `curate/annotate`, which is the whole metadata pass.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at 67 skills.
- [x] 4.2 `python3 tests/check-bench-fixtures.py` — clean at 41 tasks.
- [x] 4.3 `npm run spec:validate` — passes with this change present.
- [x] 4.4 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.5 `python3 schemas/validate-ledger.py examples/project.yaml` — valid; no schema change.
- [x] 4.6 `bash tests/e2e-smoke.sh` — unchanged at 95. **This change adds no test coverage.** The
      row arithmetic these skills must report is prose, not an assertion the suite can check.
- [x] 4.7 Merged spec diffed after archive — addition only, no scenario dropped.
