## ADDED Requirements

### Requirement: Overdue has one definition

An obligation SHALL be overdue exactly when its `status` is `pending` and its `due` is a date
earlier than today in UTC. Today SHALL be read from the clock (`date -u +%F`), not assumed. An
obligation due today, one with no `due`, and one at `met` or `waived` SHALL NOT be overdue.

Every surface that reports obligations SHALL use this definition and SHALL list overdue obligations
before other pending ones. The surfaces are the session status block (`dsh-status.sh`),
`project/status-report`, the `coordinator` agent and `govern/obligations`. None of them SHALL
report an obligation as "near" or "due soon".

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
