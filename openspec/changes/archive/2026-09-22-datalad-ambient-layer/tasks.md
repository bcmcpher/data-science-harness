## 1. Rules and status

- [x] 1.1 Write `plugins/datalad-cli/rules/datalad.md` (≤ 300 words; save/run/push/clean-tree/quiet-output/fallback-to-status rules)
- [x] 1.2 Write `plugins/datalad-cli/hooks/scripts/dsh-status.sh` (innermost dataset, branch, dirty counts, subdatasets, siblings ahead/behind from local refs, ledger stage + open obligations; silent outside a dataset)
- [x] 1.3 Register it as SessionStart in `hooks.json`; stdout = rules file + status block

## 2. Guard

- [x] 2.1 Write `dsh-guard.sh`: parse the PreToolUse JSON, split segments, token-match, exit 2 with a redirect message, and warn on annex verbs and on a repeated `-m` to `datalad save`/`run`; honour `DSH_GUARD=0`
- [x] 2.2 Register it as PreToolUse with a `Bash` matcher

## 3. Stop rework

- [x] 3.1 Rework `datalad-checkpoint.sh`: status hash vs `.git/dsh-last-reminded`, a block decision with a reason, `stop_hook_active` guard, `DATALAD_AUTOSAVE=1` silent save, `=0` no-op
- [x] 3.2 Document all three hooks in `plugins/datalad-cli/README.md` and the README hooks section (fires when / does / never does / env var)

## 4. OpenCode

- [x] 4.1 Verify against current OpenCode docs and a live install how `session.created`/`session.idle` deliver a message to the session (the SDK call), and whether `opencode.json` `instructions` accepts absolute paths; record the answer in design.md
- [x] 4.2 Add hook translation to `bin/install.sh`: generate `plugins/dsh-<plugin>.js` from `hooks.json`; warn on unmapped events; honour `--dry-run`
- [x] 4.3 Add `rules/` → `opencode.json` `instructions` registration (create/merge/idempotent)

## 5. Tests

- [x] 5.1 `tests/hooks-selftest.sh`: feed each script fixture payloads in a scratch dataset (conda `datalad` env). Cover: guard chained commit, quoted mention, plain repo; checkpoint remind once, repeat silent, autosave=1, autosave=0; status outside/inside a dataset
- [x] 5.2 Installer dry-run test for OpenCode: generated plugin listed, `instructions` merge idempotent
- [x] 5.3 Lint: rules-file word budget; lint and selftest still pass
