## Context

`dsh-status.sh` runs at session start and prints a short block into context. Its ledger scan
(lines 86-97) is a single awk pass over `project.yaml`:

- it tracks the current top-level section from lines like `obligations:`;
- in `log`, it keeps the last `stage:` value as a fallback stage;
- in `obligations`, it increments a counter for every line matching `status:[[:space:]]*pending`.

The counter is line-based, which works because each entry has exactly one `status:` key. Reading
`due` needs the scan to know which `due` belongs to which `status`, so it has to group lines into
entries. The `--legacy` parser in `dsh-log.sh` already does this for `log` entries: a line starting
with `- ` opens an entry, and a flow entry (`{ … }`) is accumulated across lines until the next
`- ` or the end of the section.

The ledger schema (`schemas/project.schema.json` lines 102-114) defines an obligation's `status`
as `pending`, `met` or `waived`, and an optional `due` with `format: date`. `examples/project.yaml`
writes obligations in block style, one of them `met` with a past `due` (`prereg-h1`, 2026-09-01).
Skills that append obligations write whichever style the model produces, so both styles occur.

## Goals / Non-Goals

**Goals:**
- A lapsed deadline is visible at session start, without the user asking.
- Overdue has one definition, from the real clock, used by the hook and by every planner surface.
- The status block stays short: one line for the ledger, as today.

**Non-Goals:**
- A YAML parser in the hook. The hook must stay dependency-free (awk, git, date) and fast.
- Validating the ledger. `schemas/validate-ledger.py` does that; the hook reads what is there and
  ignores what it cannot parse.
- Reminders, notifications, or anything that runs outside a session.
- A warning window for obligations due soon (see Open Questions).

## Decisions

**D1. Group entries the way `dsh-log.sh --legacy` does.** Inside `obligations`, a line matching
`^[ \t]*- ` closes the previous entry and opens a new one. Every following line up to the next
entry or the next top-level key is appended to it. On close, the scan extracts three keys from the
accumulated text: `id`, `due` and `status`. Each key is matched only where it starts a key, that is,
after the line start, whitespace, `{` or `,`, so that `resolved_by:` never matches `id:`. Values
may be quoted. `due` is taken only if it has the shape `YYYY-MM-DD`; anything else is treated as
absent.

*Alternative: keep the line-based count and look for `due:` on the same line.* This works for
one-line flow entries only. In block style, the house style of `examples/project.yaml`, `due` and
`status` are on different lines, so it would miss every block-style obligation.

*Alternative: call `python3` with PyYAML.* Correct, but the hook would then depend on PyYAML being
installed in whatever Python is on `PATH` at session start. The hook currently needs only git and
datalad, and a missing module would silently drop the whole ledger line.

**D2. Overdue is `status: pending` and `due` < today in UTC, compared as strings.** Today is
`date -u +%F`, passed into awk with `-v`. ISO 8601 dates of fixed width sort lexically in date
order, so `due < today` is a string comparison. A date equal to today is not overdue: the deadline
is today, not past. UTC rather than local time keeps the hook, CI and a remote session in agreement;
the cost is that near midnight an obligation can turn overdue a few hours early or late in the
user's timezone.

*Alternative: local time (`date +%F`).* Matches the user's calendar, but two machines looking at
the same ledger could disagree, and the hooks selftest would depend on the runner's timezone.

**D3. The ledger line gains a parenthetical only when something is overdue.** With N overdue:
`- ledger: <stage> stage; <open> open obligation(s) (<N> overdue: <id>, <id>, <id>, …)`. At most
three ids are listed, in file order, followed by `…` when there are more. With none overdue the
line is byte-for-byte what it is today, so the common case adds nothing to context.

*Alternative: a separate `- overdue:` line.* Clearer to scan, but it adds a line to every status
block that has an overdue item, and the overdue items are a subset of the open count already on the
ledger line.

**D4. Planner surfaces state the rule, not a copy of the code.** `status-report`, the
`coordinator` and `govern/obligations` each say: overdue means pending with a `due` before today
in UTC, and today comes from `date -u +%F`. They list overdue items first, then the rest of the
pending items by date. They do not parse the status block's text.

*Alternative: have the planners read the hook's output.* The coordinator and status-report already
parse `project.yaml` themselves, and the hook's line is truncated at three ids by design.

## Risks / Trade-offs

- [An unusual YAML layout is misread, for example an obligation entry written as a nested mapping
  with `id` on a later line than `- `] → The entry is still grouped from `- ` to the next `- `, so
  key order inside it does not matter. A layout the scan cannot group produces a lower count, never
  a false overdue. The selftest covers both styles.
- [A `description:` containing the text `status: pending` or `due: 2020-01-01`] → The same
  weakness exists in today's line count. D1 anchors each key to a key position, which excludes the
  common case of the text appearing mid-sentence after other words; a description beginning with
  such text inside a flow entry after a comma could still match. Accepted: descriptions are prose
  and the failure is a wrong count in a hint line.
- [The machine clock is wrong] → Overdue is wrong in the same direction as everything else on the
  machine. Not worth guarding.

## Migration Plan

Additive output on one line of the status block. Rollback means reverting the awk scan. No ledger
changes and no stored state.

## Open Questions

- **Warn on obligations due within N days?** Default: **no, overdue only.** The status block is
  loaded into every session and is meant to stay short, and a window needs a number that suits both
  a funder report and an ethics renewal. `govern/obligations` and `status-report` already list
  pending items by date on request. Revisit when users ask for it.
