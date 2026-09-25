## 1. History reader

- [x] 1.1 Write `plugins/datalad-cli/scripts/dsh-log.sh`: one JSON line per `DSH-Op` commit (sha, ts, subject, run, fields); stop at the run-record marker; `--legacy` merges `project.yaml` `log` in timestamp order; git + POSIX sh only
- [x] 1.2 Unit-test it on a scratch dataset (conda `datalad` env): a save commit, a run commit, a non-harness commit (excluded), and a legacy log
- [x] 1.3 Add `DSH-*` rules and the single-`-m` form to `plugins/datalad-cli/rules/datalad.md` (keep ≤ 300 words)

## 2. Ledger

- [x] 2.1 `schemas/project.schema.json`: drop `log` from `required`; mark `log` legacy in its description; `resolved_by` description prefers a commit SHA
- [x] 2.2 Update `examples/project.yaml` (no new `log` writes; keep a legacy block to prove validity) and `docs/project-ledger.md`
- [x] 2.3 `schemas/validate-ledger.py` passes on the example and on a ledger with no `log`

## 3. Consolidate the toolbox

- [ ] 3.1 Create `plugins/datalad-cli/skills/datalad/SKILL.md` (verb router, `<verb> [args]`, git-replacement trigger)
- [ ] 3.2 Move each per-verb skill body to `references/verbs/<verb>.md`, keeping constraints verbatim; delete the per-verb skill dirs; update `plugin.json`
- [ ] 3.3 Update `plugins/datalad-cli/README.md` with the old slash command → `/datalad <verb>` mapping

## 4. Retire the doer

- [ ] 4.1 Remove `plugins/datalad/` and its marketplace entry
- [ ] 4.2 Other doers (nipoppy, containers, annotate, archive, compendium, liab): hand results to the planner with `run_via`/`save_via: planner`, and add `binding` to each result block
- [ ] 4.3 `project/agents/coordinator.md`: read state + `dsh-log --legacy`; drop the log-vs-history discrepancy rule and replace it with "harness commit lacking DSH-Op"

## 5. Planners (all 37)

- [ ] 5.1 Replace every datalad-doer delegation with the direct command; collapse "save" + "log it" into one step with `DSH-*` lines; drop `datalad` from `delegates_to`
- [ ] 5.2 `log-decision` → `docs/decisions/<date>-<slug>.md` + save
- [ ] 5.3 `status-report` → read-only; optionally write `reports/status-<date>.md`
- [ ] 5.4 `templates/skill/SKILL.md`: step pattern uses a direct `datalad save` with `DSH-*` lines

## 6. Lint and tests

- [ ] 6.1 Lint: retired-term check (`plugins/`, `templates/`, `docs/` minus `docs/talk/`); selftest case
- [ ] 6.2 Fix counts the doc-claims check will flag (README 22 → 21 plugins, doer lists, marketplace prose, `paper/` "8 doers")
- [ ] 6.3 `tests/e2e-smoke.sh`: assert `DSH-Op`/`DSH-Stage` via `dsh-log` wherever it asserted `log` entries; run it in the conda `datalad` env
- [ ] 6.4 Lint, selftest, and e2e all pass

## 7. Docs and install

- [ ] 7.1 README: the Axis 1 table and prose describe DataLad as native; the workflow/capability description is updated
- [ ] 7.2 `docs/motivation.md`, `docs/end-to-end-workflow.md`, `paper/sections/03-architecture.md`: drop the datalad doer and describe commit-recorded activity
- [ ] 7.4 After archive, update the Purpose paragraphs that still name the datalad doer (`openspec/specs/datalad`, `containers`, `annotate`, `process`); deltas do not carry Purpose text
- [ ] 7.3 `bin/install.sh --prune`: remove installed files for plugins no longer in the source (the retired `datalad-doer`); dry-run shows them
