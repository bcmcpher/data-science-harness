## ADDED Requirements

### Requirement: BIDS validation is a first-class toolbox skill

`plugins/bids-cli/` MUST provide a `user-invocable: true` `bids-validator` skill with an
`argument-hint` and `allowed-tools` scoped to running the validator. The bids doer MUST consult it
rather than carrying invocation detail inline.

#### Scenario: A user validates a dataset directly

- **WHEN** a user invokes the `bids-validator` skill without a planner
- **THEN** the skill runs standalone and reports errors and warnings

#### Scenario: The doer validates on a planner's behalf

- **WHEN** `govern/qc-review` delegates validation
- **THEN** the doer follows the toolbox skill's steps and returns its structured result

### Requirement: Validation is assertable in the end-to-end test

`tests/e2e-smoke.sh` MUST assert BIDS validation against the scaffolded dataset, gated to skip
cleanly when no validator is installed.

#### Scenario: No validator on the host

- **WHEN** the e2e test runs without a BIDS validator
- **THEN** the block skips with a stated reason rather than failing or silently passing
