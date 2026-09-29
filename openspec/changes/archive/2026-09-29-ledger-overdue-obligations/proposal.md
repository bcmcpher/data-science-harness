## Why

The ledger records a `due` date on an obligation, and nothing reads it mechanically. The session
status block (`plugins/datalad-cli/hooks/scripts/dsh-status.sh`, lines 86-97) scans `project.yaml`
with awk and counts obligations whose line matches `status: pending`. It never reads `due`. An
ethics renewal that lapsed last month therefore looks the same at session start as one due next
year: "3 open obligations".

The planner surfaces do mention dates, but each in its own words and none with a rule:

- `project/status-report` says "pending (highlight due/overdue)" (`SKILL.md` line 37);
- the `coordinator` agent says "highlight ones with a `due` date that is near or past" (line 43-44);
- `govern/obligations` says "highlight anything with a `due` date that is near or past" (line 28).

"Near" is undefined, and "past" is judged by whatever date the model believes it is. A missed
ethics or funder deadline is the failure the obligations registry exists to prevent, so the one
date-bearing field in it should be checked the same way everywhere, from the real clock.

## What Changes

- **The status block reports overdue obligations.** The awk scan in `dsh-status.sh` groups each
  `obligations` entry and reads its `id`, `due` and `status`, in both block style (`- id: …` then
  `due: …` lines) and flow style (`- { id: …, due: …, status: … }`, possibly spanning lines). It
  reuses the entry-splitting approach of the `--legacy` parser in
  `plugins/datalad-cli/scripts/dsh-log.sh` (lines 87-133).
- **One definition of overdue.** An obligation is overdue when its `status` is `pending` and its
  `due` date is earlier than today in UTC (`date -u +%F`). ISO dates compare correctly as strings,
  so no date arithmetic is needed. An obligation with no `due`, or at `met` or `waived`, is never
  overdue.
- **Output.** When at least one obligation is overdue, the ledger line gains a parenthetical:
  `- ledger: analyze stage; 3 open obligations (1 overdue: ethics-renewal)`. At most three ids are
  listed, then `…`. With none overdue the line is unchanged.
- **An opt-in "due soon" window.** A new ledger key, `project.due_warn_days` (integer, default 0 =
  off), names a window in days. When it is above 0, a `pending` obligation whose `due` falls between
  today and today + N days, inclusive, is due soon, and the parenthetical gains a second group:
  `(1 overdue: ethics-renewal; 2 due within 14d: funder-report, dmp-update)`. Each group appears only
  when it is non-empty. With the key unset, the output is exactly the overdue-only output.
- **Planner surfaces use the same rule.** `project/status-report`, the `coordinator` agent and
  `govern/obligations` define overdue as above, take today's date from `date -u +%F` rather than
  assuming it, and list overdue items first. "Near" is dropped from their wording.
- **Tests.** `tests/hooks-selftest.sh` gains ledger fixtures for the `dsh-status.sh` block (today
  lines 78-83): a past-due pending obligation, a future-dated pending one, a met one with a past
  date, and a pending one with no date, in block and flow style; and the window unset, set, and at
  its boundaries.

**Not in this change:** any change to how obligations are opened or resolved, and any per-obligation
window.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `datalad`: the session status block reports overdue obligations, and due-soon ones when the
  window is set, alongside the open count.
- `project-ledger`: define overdue and due-soon obligations and the `project.due_warn_days` key,
  and require every surface that reports obligations to use those definitions.

## Impact

- `plugins/datalad-cli/hooks/scripts/dsh-status.sh` (the ledger scan and the `- ledger:` line)
- `tests/hooks-selftest.sh` (new `dsh-status.sh` checks and fixtures)
- `plugins/project/skills/status-report/SKILL.md`, `plugins/project/agents/coordinator.md`,
  `plugins/govern/skills/obligations/SKILL.md` (wording only)
- `README.md` "Session start" bullet and `plugins/datalad-cli/README.md` hooks table: mention
  overdue obligations
- `schemas/project.schema.json`: add `due_warn_days` (integer, minimum 0) to the `project` header,
  which is `additionalProperties: false`. `due` is already `format: date` (line 110).
- `docs/project-ledger.md`: document `due_warn_days`.
- The OpenCode adapter calls the same script, so it gets the new line with no change.
