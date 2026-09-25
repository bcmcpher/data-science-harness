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
- **Planner surfaces use the same rule.** `project/status-report`, the `coordinator` agent and
  `govern/obligations` define overdue as above, take today's date from `date -u +%F` rather than
  assuming it, and list overdue items first. "Near" is dropped from their wording.
- **Tests.** `tests/hooks-selftest.sh` gains ledger fixtures for the `dsh-status.sh` block (today
  lines 78-83): a past-due pending obligation, a future-dated pending one, a met one with a past
  date, and a pending one with no date, in block and flow style.

**Not in this change:** a "due soon" warning window (see Open Questions), any change to the ledger
schema, and any change to how obligations are opened or resolved.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `datalad`: the session status block reports overdue obligations alongside the open count.
- `project-ledger`: define an overdue obligation, and require every surface that reports
  obligations to use that definition.

## Impact

- `plugins/datalad-cli/hooks/scripts/dsh-status.sh` (the ledger scan and the `- ledger:` line)
- `tests/hooks-selftest.sh` (new `dsh-status.sh` checks and fixtures)
- `plugins/project/skills/status-report/SKILL.md`, `plugins/project/agents/coordinator.md`,
  `plugins/govern/skills/obligations/SKILL.md` (wording only)
- `README.md` "Session start" bullet and `plugins/datalad-cli/README.md` hooks table: mention
  overdue obligations
- No schema change: `due` is already `format: date` in `schemas/project.schema.json` (line 110).
- The OpenCode adapter calls the same script, so it gets the new line with no change.
