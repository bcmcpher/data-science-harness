## ADDED Requirements

### Requirement: The lint checks mechanically verifiable documentation claims

The lint MUST verify that the manifest filename the README's Contributing steps instruct a
contributor to edit is the filename the lint itself requires, and that any stated plugin count
matches the number of plugin directories on disk.

#### Scenario: The README names a manifest file that does not exist

- **WHEN** the Contributing steps tell a contributor to add a path to `plugin.yaml` while the lint
  requires `.claude-plugin/plugin.json`
- **THEN** the lint reports an error, because a first contribution following those steps would fail

#### Scenario: A plugin is added without updating the documented count

- **WHEN** a new plugin directory is created and the README still states the previous count
- **THEN** the lint reports the mismatch

#### Scenario: Claims and disk agree

- **WHEN** the documented manifest filename and plugin count match the repository
- **THEN** the check passes silently

### Requirement: The doc-claims check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include a case injecting a documentation claim that contradicts
disk and asserting the lint reports it.

#### Scenario: The doc-claims check is weakened

- **WHEN** the check is removed or loosened
- **THEN** the selftest case fails
