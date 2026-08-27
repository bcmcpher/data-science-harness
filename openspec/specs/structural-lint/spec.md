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
