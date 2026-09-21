## ADDED Requirements

### Requirement: The lint validates the model field

`check_agent` MUST validate `model:` against a closed allowed set defined alongside the other closed
vocabularies in `tests/lint-plugins.py`, and MUST report an error for a value outside it.

#### Scenario: A typo in a model identifier

- **WHEN** an agent declares a `model:` value not in the allowed set
- **THEN** the lint reports an error naming the agent and the unrecognised value

#### Scenario: A mutating doer declares a model

- **WHEN** an agent that can mutate a dataset declares `model:`
- **THEN** the lint reports it, because pinning is restricted to read-only agents

### Requirement: The model check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include a case injecting an invalid `model:` value and
asserting the lint reports it.

#### Scenario: The model check is weakened

- **WHEN** the validation is removed or loosened
- **THEN** the selftest case fails, naming the drift that is no longer caught
