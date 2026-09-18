## Status

Complete as of 2026-09-17. All tasks checked. Ready to archive.

One thing the audit did not predict: the conditional requirement in 1.3 **failed the existing
end-to-end test**, because `tests/e2e-smoke.sh`'s govern block flipped an obligation to `met`
without recording anything — the exact failure the constraint exists to prevent, present in the
repository's own worked example. Four assertions went red (one direct, three cascading from the same
ledger). Fixed by having the test resolve the obligation with the dataset's actual commit SHA, which
is what a real resolution would carry. See task 5.2.

## 0. Minimal working core

All of it. This change is already the smallest version that works: three schema additions, each with
a named skill that needs it, and an example that exercises them. There is nothing to defer — a
partial schema pass would put the next change back in the position this one exists to avoid.

## 1. The schema

- [x] 1.1 `$defs/obligation.kind` gains `milestone`.
- [x] 1.2 `$defs/obligation` gains `resolved_by` (string) describing internal evidence — a commit
      SHA, a log entry timestamp, or a product id — and `ref`'s description is tightened to say it
      is the external reference.
- [x] 1.3 An `if`/`then` on `$defs/obligation` requiring `resolved_by` when `status` is `met`.
- [x] 1.4 `$defs/submission` with `venue` required, and `submitted`, `status` (closed set),
      `decision`, `ref` optional; `additionalProperties: false` like every sibling definition.
- [x] 1.5 `$defs/product` gains `submissions` as an array of `$defs/submission`.

## 2. The example

- [x] 2.1 `examples/project.yaml` — `main-paper` carries a two-entry `submissions` history, the
      first rejected and the second under review, so the resubmission case is exercised rather than
      asserted.
- [x] 2.2 Added `ms-first-submission` with `kind: milestone` and a `due` date.
- [x] 2.3 `prereg-h1` moved to `status: met` with `resolved_by: a1b2c3d`, and `ethics-renewal` added
      as a pending `kind: ethics` entry carrying its protocol number in `ref` — the shape
      `govern/ethics-track` will read.
- [x] 2.4 Four `log:` entries appended covering the ethics approval, the first submission, its
      rejection, and the resubmission.

## 3. Documentation

- [x] 3.1 `docs/project-ledger.md` — `resolved_by` and the `ref`/`resolved_by` distinction, the
      `milestone` kind, and `submissions[]` as a history. The conventions list grew from four to six
      and the skill-routing table names the new writers.
- [x] 3.2 Recorded the decision that ethics protocol data is an `obligations[]` entry plus `log:`
      entries, as convention 5, so `govern/ethics-track` has one place to read it from.
- [x] 3.3 The Evolution section now states when the same-commit rule inverts, and points at
      `openspec/README.md`'s ledger-first convention.

## 4. Verify

- [x] 4.1 `python3 schemas/validate-ledger.py examples/project.yaml` → `VALID`.
- [x] 4.2 Negative check by hand, both new constraints: a `met` obligation with no `resolved_by` is
      rejected with `at obligations/0: 'resolved_by' is a required property`, and a submission with
      no `venue` with `at products/0/submissions/1: 'venue' is a required property`. Both name the
      field.
- [x] 4.3 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings.
- [x] 4.4 `npm run spec:validate` — 25 passed, 0 failed.
- [x] 4.5 `bash tests/e2e-smoke.sh` — see task 5.2; it failed first, then passed at 77.

## 5. The e2e fallout (not predicted; added during implementation)

- [x] 5.1 Diagnosed: 4 assertions red, all from one ledger whose obligation was set to `met` with no
      evidence. The three later failures were the same file re-validated, not separate defects.
- [x] 5.2 `tests/e2e-smoke.sh` now resolves the obligation with `git rev-parse --short HEAD`, so the
      test records checkable evidence the way a real resolution would, and asserts `resolved_by:`
      names it.
- [x] 5.3 Added a negative assertion in the same block: `resolved_by` is stripped in a throwaway
      copy and the validator is required to reject it, gated to skip when the validator's
      dependencies are absent. A conditional requirement nothing has seen fail is not known to work.
- [x] 5.4 `PATH="$HOME/miniconda3/envs/datalad/bin:$PATH" bash tests/e2e-smoke.sh` → **77 passed,
      0 failed** (was 75; +2 assertions).

## 6. Delta authoring defect caught after archiving

- [x] 6.1 The `MODIFIED Requirements` delta for "Products group kept comparisons into deliverables"
      replaced the whole requirement block, which is how OpenSpec applies a MODIFIED delta — so its
      two original scenarios ("A comparison is promoted into a product", "A product is released")
      were silently dropped when the change archived. The release scenario is load-bearing:
      `tests/e2e-smoke.sh` asserts exactly that path.
- [x] 6.2 Both scenarios restored in `openspec/specs/project-ledger/spec.md` and in this change's
      own delta, so the archived record matches what shipped. The new submission scenario is kept
      alongside them.
- [x] 6.3 Rule for the five skill changes that follow: **a MODIFIED requirement must carry forward
      every scenario it is not deliberately changing.** `npm run spec:validate` does not catch a
      dropped scenario — it validates structure, not coverage. Diff the merged spec after every
      archive.
