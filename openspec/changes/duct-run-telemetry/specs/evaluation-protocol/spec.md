## ADDED Requirements

### Requirement: Committed duct logs are a compute-cost input to the cost probe

The cost probe MAY read duct logs committed by provenanced runs (`*_info.json` and
`*_usage.jsonl` under `.duct/logs/`) as a `compute_usage` metric: peak memory, CPU time and
wall-clock per run commit in a lifecycle stage. `compute_usage` MUST be reported beside agent
cost and MUST NOT be summed into agent `wall_clock`. A stage whose run commits carry no duct
binding MUST report `compute_usage` as unmeasured, not as zero.

#### Scenario: A stage with measured runs

- **WHEN** the cost probe reports a Process stage whose run commits carry duct bindings
- **THEN** it reports compute usage per run from the committed logs, next to and separate from the
  stage's token cost and agent wall-clock

#### Scenario: A stage without telemetry

- **WHEN** a stage's run commits carry no duct binding
- **THEN** `compute_usage` for that stage is reported as unmeasured
