## ADDED Requirements

### Requirement: The lint verifies that imported dependencies are declared

The lint MUST check that every third-party module imported by a script under `tests/` or `schemas/`
is declared in `pyproject.toml`, and MUST report an undeclared import as an error.

#### Scenario: A check script imports an undeclared module

- **WHEN** a script under `tests/` imports a third-party module absent from `pyproject.toml`
- **THEN** the lint reports an error naming the script and the module

#### Scenario: A standard-library import

- **WHEN** a script imports from the standard library
- **THEN** the lint ignores it

### Requirement: The dependency check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include a case injecting an undeclared import and asserting the
lint reports it.

#### Scenario: The dependency check is weakened

- **WHEN** the check is removed or loosened
- **THEN** the selftest case fails
