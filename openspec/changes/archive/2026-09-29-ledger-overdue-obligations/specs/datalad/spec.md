## ADDED Requirements

### Requirement: The session status reports overdue obligations

When `project.yaml` exists, `dsh-status.sh` MUST read each entry of `obligations` as a unit, in
both block and flow YAML style, and MUST take its `id`, `due` and `status`. It MUST count an entry
as overdue when its `status` is `pending` and its `due` is a date earlier than today in UTC
(`date -u +%F`). An entry with no `due`, or whose `status` is `met` or `waived`, MUST NOT be counted
as overdue.

When one or more obligations are overdue, the ledger line MUST append the overdue count and the ids
of at most three overdue obligations, followed by `…` when there are more, for example
`- ledger: analyze stage; 3 open obligations (1 overdue: ethics-renewal)`. When none is overdue,
the ledger line MUST be unchanged. The scan MUST use only the shell, awk and `date`, and MUST NOT
touch the network.

#### Scenario: A pending obligation is past its date

- **WHEN** the ledger holds a `pending` obligation `ethics-renewal` due 2000-01-01, a `pending` one
  due 2999-12-31, a `met` one due 2000-01-01 and a `pending` one with no `due`
- **THEN** the ledger line reads `3 open obligations (1 overdue: ethics-renewal)`

#### Scenario: Flow-style entries

- **WHEN** the same obligations are written as `- { id: …, due: …, status: … }`, one of them
  spanning two lines
- **THEN** the ledger line is the same as for block style

#### Scenario: Many overdue obligations

- **WHEN** four `pending` obligations are past their dates
- **THEN** the line names the first three in file order, followed by `…`

#### Scenario: Nothing is overdue

- **WHEN** every `pending` obligation is due today or later, or has no `due`
- **THEN** the ledger line carries no overdue parenthetical

### Requirement: The session status reports obligations due soon when a window is set

When the `project` header of `project.yaml` sets `due_warn_days` to an integer N greater than 0,
`dsh-status.sh` MUST count a `pending` obligation as due soon when its `due` is on or after today and
on or before today + N days, both in UTC. When `due_warn_days` is absent, 0, or not a plain integer,
the hook MUST NOT report anything as due soon.

When one or more obligations are due soon, the parenthetical on the ledger line MUST include a group
`<M> due within <N>d: <ids>`, with at most three ids followed by `…` when there are more. When both
groups are present, the overdue group MUST come first and the two MUST be separated by `; `. When
neither is present, the ledger line MUST carry no parenthetical.

The hook MUST compute today + N days without the network, trying GNU `date`, then BSD `date`, then
`python3` with the standard library. If none works, it MUST omit the due-soon group and still print
the overdue report.

#### Scenario: The window is unset

- **WHEN** `project.yaml` has no `due_warn_days` and a `pending` obligation is due tomorrow
- **THEN** the ledger line carries no parenthetical

#### Scenario: An obligation falls inside the window

- **WHEN** `due_warn_days` is 14, `funder-report` is `pending` and due in 10 days, and
  `ethics-renewal` is `pending` and past its date
- **THEN** the ledger line ends `(1 overdue: ethics-renewal; 1 due within 14d: funder-report)`

#### Scenario: The window boundaries

- **WHEN** `due_warn_days` is 14 and `pending` obligations are due today, in 14 days and in 15 days
- **THEN** the first two are due soon and the third is not

### Requirement: The overdue report is covered by the hooks selftest

`tests/hooks-selftest.sh` MUST exercise the overdue report with ledger fixtures covering a past-due
`pending` obligation, a future-dated `pending` one, a `met` one with a past date and a `pending`
one with no date, in both block and flow style. It MUST also exercise the due-soon window unset,
set, and at its boundaries: due today, due on the last day of the window and due the day after.

#### Scenario: The date check is removed

- **WHEN** `dsh-status.sh` stops reading `due`
- **THEN** the selftest fails
