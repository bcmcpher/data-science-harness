## 1. Status hook

- [ ] 1.1 In `plugins/datalad-cli/hooks/scripts/dsh-status.sh`, replace the per-line `status: pending` count with per-entry grouping inside `obligations` (a `- ` line opens an entry; flow entries accumulate across lines), extracting `id`, `due` (only `YYYY-MM-DD`, quotes stripped) and `status` at key positions
- [ ] 1.2 Pass `today="$(date -u +%F)"` into awk with `-v`; count an entry as overdue when `status` is `pending` and `due < today`
- [ ] 1.3 Emit the open count, the overdue count and up to three overdue ids (comma-separated, `…` when more) from awk, and read them back without breaking on ids that contain spaces
- [ ] 1.4 Append ` (<N> overdue: <ids>)` to the `- ledger:` line only when N > 0; leave the line unchanged otherwise
- [ ] 1.5 Update the header comment of `dsh-status.sh` to mention overdue obligations

## 2. Selftest

- [ ] 2.1 In `tests/hooks-selftest.sh`, write a block-style `project.yaml` into a scratch dataset with four obligations: pending due 2000-01-01, pending due 2999-12-31, met due 2000-01-01, pending with no `due`
- [ ] 2.2 Assert the ledger line reads `3 open obligations (1 overdue: <past-due id>)`
- [ ] 2.3 Repeat 2.1-2.2 with the same obligations in flow style, one of them spanning two lines
- [ ] 2.4 Assert that four past-due pending obligations list three ids followed by `…`
- [ ] 2.5 Assert that a ledger with no overdue obligation prints the ledger line without a parenthetical
- [ ] 2.6 Update the selftest's header comment for `dsh-status.sh`; run the selftest in the conda `datalad` env

## 3. Planner surfaces

- [ ] 3.1 `plugins/project/skills/status-report/SKILL.md`: define overdue (pending, `due` before `date -u +%F`), list overdue first; replace "due/overdue"
- [ ] 3.2 `plugins/project/agents/coordinator.md`: the same definition in the Manage & Comply bullet; drop "near"
- [ ] 3.3 `plugins/govern/skills/obligations/SKILL.md`: the same definition in step 1; drop "near"
- [ ] 3.4 `python3 tests/lint-plugins.py --strict` and its selftest pass

## 4. Docs

- [ ] 4.1 `README.md` "Session start" bullet and `plugins/datalad-cli/README.md` hooks table: the ledger line includes overdue obligations
- [ ] 4.2 `openspec validate --all --strict` passes
