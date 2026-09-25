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

### Requirement: The overdue report is covered by the hooks selftest

`tests/hooks-selftest.sh` MUST exercise the overdue report with ledger fixtures covering a past-due
`pending` obligation, a future-dated `pending` one, a `met` one with a past date and a `pending`
one with no date, in both block and flow style.

#### Scenario: The date check is removed

- **WHEN** `dsh-status.sh` stops reading `due`
- **THEN** the selftest fails
