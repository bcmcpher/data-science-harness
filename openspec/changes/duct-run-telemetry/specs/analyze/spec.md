## ADDED Requirements

### Requirement: Comparison runs capture resource usage when the image provides duct

`analyze/run-comparison` SHALL ask, in words, for the containerized run to capture resource usage
when the comparison's environment provides duct, following the `datalad` skill's container-run
reference. When the environment's pinned manifest does not list `con-duct`, the run SHALL proceed
unmeasured and the report SHALL say so. The skill SHALL NOT quote a duct command line.

#### Scenario: The environment pins con-duct

- **WHEN** the environment's manifest pins `con-duct` and a comparison is run
- **THEN** the run commit contains the run's duct logs and a `DSH-Binding:
  datalad-cli/duct@<pinned version>` line

#### Scenario: The environment lacks duct

- **WHEN** the environment's manifest does not list `con-duct`
- **THEN** the comparison runs as before, and the report states that resource usage was not
  captured
