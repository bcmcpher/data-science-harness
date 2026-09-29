## 1. Status hook

- [x] 1.1 In `plugins/datalad-cli/hooks/scripts/dsh-status.sh`, replace the per-line `status: pending` count with per-entry grouping inside `obligations` (a `- ` line opens an entry; flow entries accumulate across lines), extracting `id`, `due` (only `YYYY-MM-DD`, quotes stripped) and `status` at key positions
- [x] 1.2 Pass `today="$(date -u +%F)"` into awk with `-v`; count an entry as overdue when `status` is `pending` and `due < today`
- [x] 1.3 Emit the open count, the overdue count and up to three overdue ids (comma-separated, `…` when more) from awk, and read them back without breaking on ids that contain spaces
- [x] 1.4 Append ` (<N> overdue: <ids>)` to the `- ledger:` line only when N > 0; leave the line unchanged otherwise
- [x] 1.5 Read `due_warn_days` from the `project` section in a short awk pass (non-integer → 0); when N > 0 compute `cutoff` with GNU `date -u -d "+N days" +%F`, else BSD `date -u -v+Nd +%F`, else stdlib `python3`, else skip the window
- [x] 1.6 Pass `cutoff` into the main awk scan; count a pending entry as due soon when `today <= due <= cutoff`; emit the due-soon count and up to three ids
- [x] 1.7 Build the parenthetical from the non-empty groups, overdue first, joined by `; ` (`<M> due within <N>d: <ids>`)
- [x] 1.8 Update the header comment of `dsh-status.sh` to mention overdue and due-soon obligations

## 2. Selftest

- [x] 2.1 In `tests/hooks-selftest.sh`, write a block-style `project.yaml` into a scratch dataset with four obligations: pending due 2000-01-01, pending due 2999-12-31, met due 2000-01-01, pending with no `due`
- [x] 2.2 Assert the ledger line reads `3 open obligations (1 overdue: <past-due id>)`
- [x] 2.3 Repeat 2.1-2.2 with the same obligations in flow style, one of them spanning two lines
- [x] 2.4 Assert that four past-due pending obligations list three ids followed by `…`
- [x] 2.5 Assert that a ledger with no overdue obligation prints the ledger line without a parenthetical
- [x] 2.6 Assert that a ledger without `due_warn_days` and a pending obligation due tomorrow prints no parenthetical
- [x] 2.7 With `due_warn_days: 14`, generate dates from `date -u` and assert: due today and due in 14 days are due soon, due in 15 days is not, and a past-due one is overdue, giving `(1 overdue: …; 2 due within 14d: …)`
- [x] 2.8 Assert that a non-integer `due_warn_days` behaves as unset
- [x] 2.9 Update the selftest's header comment for `dsh-status.sh`; run the selftest in the conda `datalad` env

## 2b. Schema and ledger docs

- [x] 2b.1 `schemas/project.schema.json`: add `due_warn_days` (`integer`, `minimum: 0`, with a description) to the `project` properties
- [x] 2b.2 Check `schemas/validate-ledger.py` accepts `due_warn_days: 14` and rejects `-3` and `"two weeks"`; `examples/project.yaml` still validates
- [x] 2b.3 `docs/project-ledger.md`: document `due_warn_days`, the overdue and due-soon definitions, and the default of off

## 3. Planner surfaces

- [x] 3.1 `plugins/project/skills/status-report/SKILL.md`: define overdue (pending, `due` before `date -u +%F`) and due soon (pending, within `project.due_warn_days` days, when set); list overdue first, then due soon; replace "due/overdue"
- [x] 3.2 `plugins/project/agents/coordinator.md`: the same definitions in the Manage & Comply bullet; drop "near"
- [x] 3.3 `plugins/govern/skills/obligations/SKILL.md`: the same definitions in step 1; drop "near"
- [x] 3.4 `python3 tests/lint-plugins.py --strict` and its selftest pass

## 4. Docs

- [x] 4.1 `README.md` "Session start" bullet and `plugins/datalad-cli/README.md` hooks table: the ledger line includes overdue obligations, and due-soon ones when `due_warn_days` is set
- [x] 4.2 `openspec validate --all --strict` passes
