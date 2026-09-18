# structural-lint

## Purpose

The self-check that keeps the harness's own structure honest. Nothing else validates it: a skill can
name a doer that does not exist, or be added to disk but never registered in its `plugin.json` and
therefore silently never load. `tests/lint-plugins.py` is a static pass over `plugins/` and
`.claude-plugin/` that catches both, and `tests/lint-plugins-selftest.py` injects one kind of drift
per case into a throwaway copy to prove the lint still reacts. This spec covers the checker itself —
the rules it enforces about skill and agent content live in `skill-format`.
## Requirements
### Requirement: The lint runs offline against the working tree

The lint MUST require no network, no dataset, and no external tool beyond Python and PyYAML. When
PyYAML is absent it SHALL exit with status 2 to signal "skipped, dependency absent" rather than
failing, matching the contract `schemas/validate-ledger.py` already uses.

#### Scenario: PyYAML is not installed

- **WHEN** `python3 tests/lint-plugins.py` runs in an environment without PyYAML
- **THEN** it exits 2 and a caller can distinguish a skip from a failure

#### Scenario: Clean tree

- **WHEN** the lint runs against an unmodified repository
- **THEN** it exits 0 and reports the plugin, skill, and agent counts it examined

### Requirement: Exit status distinguishes errors from warnings

The lint SHALL exit 1 when any error is found, exit 0 when only warnings are found, and SHALL exit 1
on warnings when invoked with `--strict`.

#### Scenario: Warnings only, default mode

- **WHEN** the tree has warnings but no errors
- **THEN** the lint prints them and exits 0

#### Scenario: Warnings only, strict mode

- **WHEN** the same tree is linted with `--strict`
- **THEN** the lint exits 1

### Requirement: Plugin manifests and on-disk content agree bidirectionally

Each `plugins/<name>/.claude-plugin/plugin.json` MUST be valid JSON whose `name` equals its
directory. Every skill and agent path it lists MUST exist on disk, and every `skills/*/SKILL.md` and
`agents/*.md` on disk MUST be listed in the manifest.

#### Scenario: A skill exists but is unregistered

- **WHEN** `plugins/govern/skills/new-thing/SKILL.md` is added without editing the manifest
- **THEN** the lint reports an error stating the skill will not load

#### Scenario: A manifest lists a path that was deleted

- **WHEN** a manifest names an agent file that is no longer present
- **THEN** the lint reports an error

### Requirement: The marketplace lists every plugin

`.claude-plugin/marketplace.json` MUST reference a source for every directory under `plugins/`, and
each entry's name MUST match that plugin's own `plugin.json`.

#### Scenario: A new plugin is not registered in the marketplace

- **WHEN** `plugins/annotate/` is created with a valid manifest but no marketplace entry
- **THEN** the lint reports an error stating the plugin is not installable

### Requirement: Vendored CLI toolboxes are held to universal checks only

Plugins whose directory name ends in `-cli` are vendored single-CLI toolboxes. They SHALL be checked
for frontmatter validity, name/directory agreement, description, and manifest registration, and
SHALL NOT be required to declare `plane`, `stamped`, `delegates_to`, or planner sections.

#### Scenario: A datalad-cli verb skill omits plane

- **WHEN** `plugins/datalad-cli/skills/datalad-save/SKILL.md` declares no `plane`
- **THEN** the lint accepts it, because it is a CLI verb wrapper rather than a harness skill

### Requirement: The lint is itself tested

`tests/lint-plugins-selftest.py` SHALL copy the repository to a scratch directory, inject exactly one
kind of drift per case, and assert the lint reports it; and SHALL include a pristine control asserting
the unmodified tree is clean.

#### Scenario: A drift case stops being detected

- **WHEN** a lint rule is weakened or removed
- **THEN** the corresponding selftest case fails, naming the drift that is no longer caught

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

### Requirement: The lint checks STAMPED letters wherever they are claimed

The lint MUST validate STAMPED letters named in `.claude-plugin/marketplace.json` against the same
closed set it enforces on skills' `stamped:` frontmatter. A principle named in prose that is not one
of the seven MUST be an error, because the marketplace description is the first statement of the
framework most readers meet.

#### Scenario: The marketplace names a principle outside the closed set

- **WHEN** a marketplace description claims a STAMPED dimension that is not one of the seven letters
- **THEN** the lint errors, naming the invalid dimension and the valid set

#### Scenario: The marketplace names valid letters

- **WHEN** a description refers to STAMPED dimensions that are all in the closed set
- **THEN** the lint reports nothing

### Requirement: The lint checks the marketplace's plane counts against disk

The lint MUST verify that a workflow-planner count stated in the marketplace description matches the
number of plugins on disk containing a workflow-plane skill, in the same way it already verifies the
README's plugin count. A count that cannot be read MUST be a warning rather than silence, so an
unreadable claim is distinguishable from an absent one.

#### Scenario: The stated planner count disagrees with disk

- **WHEN** the marketplace description names fewer workflow planners than exist
- **THEN** the lint errors, giving both numbers

#### Scenario: A new workflow plugin is added

- **WHEN** a workflow-plane plugin is added without updating the marketplace description
- **THEN** the lint errors rather than allowing the description to go stale

### Requirement: Each doc-claim check is covered by the self-test

Every check added to `check_doc_claims` MUST have a self-test case that injects the specific drift it
detects into a throwaway copy of the repository and asserts the check reports it. A check whose
reaction is assumed rather than proven does not count as coverage.

#### Scenario: The self-test suite runs

- **WHEN** `tests/lint-plugins-selftest.py` runs
- **THEN** each doc-claim check has a case that fails the lint for exactly its own reason

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

