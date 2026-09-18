## Status

Complete as of 2026-09-18. Ready to archive.

## 0. Minimal working core

The spec delta and the three documents that describe the runner as deferred work
(`docs/evaluation.md`, `bench/README.md`, `docs/funding/catalyst-fit.md`). The paper's stale count
and the README drift ride along because they were found while checking the same claims.

Deliberately **not** here: any edit to `bench/`, any probe run, a fifth probe, and any dependency on
`wikiskill`.

## 1. The spec delta

- [x] 1.1 `specs/evaluation-protocol/spec.md` — pure `## ADDED Requirements`, two requirements: the
      runner may live outside this repository, and the fixtures are a stable contract whose expected
      outcomes stay repository-derived.
- [x] 1.2 No `## MODIFIED Requirements` block. "The four probes are routing, provenance,
      reproducibility, and cost" already reads *at least*, so nothing existing needs rewriting — and
      a MODIFIED block replaces a whole requirement, which is how scenarios get dropped silently.

## 2. The documents that owe a runner

- [x] 2.1 `docs/evaluation.md` — the closing "There is no runner" paragraph names the external
      instrument. The four open questions and the status banner are untouched.
- [x] 2.2 `bench/README.md` — same sentence, same treatment. "Nothing in this directory has been
      executed" stays, because it is still true.
- [x] 2.3 `docs/funding/catalyst-fit.md` feasibility row — "Only the runner is missing" becomes what
      is actually missing, which is a run. Fixture count 27 → 42.
- [x] 2.4 Same file, deliverables 1 and 2 — the deliverable is executed results, not a runner build.
- [x] 2.5 Same file, budget proportionality — "sizing depends on the runner's shape, which is not
      settled" no longer holds; sizing depends on model spend for the runs.

## 3. The drift found while checking

- [x] 3.1 `paper/sections/04-evaluation.md` — 27 tasks → 42, twice, and a drafting note that the
      section is not blocked on building a runner.
- [x] 3.2 `docs/motivation.md` evaluation row — still "Specified, unrun", which is correct; it now
      names the instrument.
- [x] 3.3 `README.md` — the open-change list names `add-deidentify-skill`, archived 2026-09-17.
- [x] 3.4 `README.md` — the **Planned** capability table is a header with zero rows and the prose
      beneath still points at it. Drop the table, repoint the prose.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at 21 plugins / 67 skills.
- [x] 4.2 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.3 `python3 tests/check-bench-fixtures.py` — clean at 42, and `bench/` is untouched by this
      change.
- [x] 4.4 `npm run spec:validate` — 24/24 with this change present. `npm run paper:check` — builds, all references resolve.
- [x] 4.5 `bash tests/e2e-smoke.sh` — 95 passed, unchanged. **This change adds no test coverage**;
      it edits prose and one spec.
- [x] 4.6 Merged spec diffed after archive — addition only, no scenario dropped.
- [x] 4.7 Every "nothing has been run" statement still present and unqualified.
