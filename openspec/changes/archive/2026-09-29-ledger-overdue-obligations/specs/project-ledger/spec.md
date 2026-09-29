## ADDED Requirements

### Requirement: Overdue has one definition

An obligation SHALL be overdue exactly when its `status` is `pending` and its `due` is a date
earlier than today in UTC. Today SHALL be read from the clock (`date -u +%F`), not assumed. An
obligation due today, one with no `due`, and one at `met` or `waived` SHALL NOT be overdue.

Every surface that reports obligations SHALL use this definition and SHALL list overdue obligations
before other pending ones. The surfaces are the session status block (`dsh-status.sh`),
`project/status-report`, the `coordinator` agent and `govern/obligations`. None of them SHALL
report an obligation as "near"; "due soon" SHALL mean only what the next requirement defines.

#### Scenario: A lapsed ethics renewal

- **WHEN** the ledger holds `ethics-renewal` with `status: pending` and a `due` date before today
- **THEN** the status block, a status report, the coordinator and `govern/obligations` all report
  it as overdue, and list it before the other pending obligations

#### Scenario: A met obligation with a past date

- **WHEN** `prereg-h1` has `status: met` and a `due` date in the past
- **THEN** no surface reports it as overdue

#### Scenario: The model's sense of the date is wrong

- **WHEN** a planner surface reports obligations
- **THEN** it compares against the date printed by `date -u +%F`, not against a date it infers

### Requirement: The due-soon window is set in the ledger

The `project` header SHALL accept an optional `due_warn_days`, an integer of 0 or more, and the
ledger schema SHALL validate it. When it is absent or 0, no surface SHALL report obligations as due
soon. When it is N > 0, an obligation SHALL be due soon exactly when its `status` is `pending` and
its `due` is on or after today and on or before today + N days, in UTC. An obligation is never both
overdue and due soon.

Every surface named in the overdue requirement SHALL use this definition, and SHALL list due-soon
obligations after overdue ones and before the other pending ones.

#### Scenario: A window of 14 days

- **WHEN** `due_warn_days` is 14 and `funder-report` is `pending` and due in 10 days
- **THEN** the status block, a status report, the coordinator and `govern/obligations` all report it
  as due soon

#### Scenario: No window

- **WHEN** `due_warn_days` is absent
- **THEN** no surface reports any obligation as due soon

#### Scenario: The schema rejects a bad window

- **WHEN** `due_warn_days` is -3 or `"two weeks"`
- **THEN** `schemas/validate-ledger.py` reports the ledger as invalid
