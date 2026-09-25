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

#### Scenario: A datalad-cli toolbox skill omits plane

- **WHEN** `plugins/datalad-cli/skills/datalad/SKILL.md` declares no `plane`
- **THEN** the lint accepts it, because it is a CLI toolbox skill rather than a harness skill

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
contributor to edit is the filename the lint itself requires, that any stated plugin count matches
the number of plugin directories on disk, and that a per-plugin skill count stated in a README table
row matches the skills that plugin has on disk.

The repo-wide count is not sufficient on its own. It stays correct while an individual plugin's row
goes stale, which is how `compendium-cli` sat at "1 skill" through two changes that took it to four.

#### Scenario: The README names a manifest file that does not exist

- **WHEN** the Contributing steps tell a contributor to add a path to `plugin.yaml` while the lint
  requires `.claude-plugin/plugin.json`
- **THEN** the lint reports an error, because a first contribution following those steps would fail

#### Scenario: A plugin is added without updating the documented count

- **WHEN** a new plugin directory is created and the README still states the previous count
- **THEN** the lint reports the mismatch

#### Scenario: A plugin gains skills without its table row moving

- **WHEN** a README table row for a plugin claims a skill count that differs from the number of
  skill directories that plugin has on disk
- **THEN** the lint errors, naming the plugin, the claimed count and the actual count

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

The lint MUST also check the doers the description enumerates by name against the plugins that
provide a doer agent and are not planners. A count alone does not catch a capability that shipped
after the sentence was written.

Because the checkable number is of planner *plugins* and not of planner skills — the two differ by
roughly a factor of six — a description stating the count as "planner skills" MUST be an error
naming the confusion, rather than a silent comparison of a skill claim against a plugin count.

#### Scenario: The stated planner count disagrees with disk

- **WHEN** the marketplace description names fewer workflow planners than exist
- **THEN** the lint errors, giving both numbers

#### Scenario: A new workflow plugin is added

- **WHEN** a workflow-plane plugin is added without updating the marketplace description
- **THEN** the lint errors rather than allowing the description to go stale

#### Scenario: A capability ships after the description was written

- **WHEN** the description enumerates the capability-plane doers and a doer on disk is absent from
  that list
- **THEN** the lint errors, naming the omitted doer

#### Scenario: The count is stated in the wrong unit

- **WHEN** the description says `N workflow-plane planner skills`
- **THEN** the lint errors, because the number it can check is of planner plugins

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

### Requirement: A documentation link into openspec/changes resolves

The lint MUST check every link of the form `openspec/changes/<name>` in `README.md` and under
`docs/` against the changes directory, and MUST error when the named change is not open. When the
change has archived, the error MUST name the archive path it moved to.

A link to an open change is a promise that the work is pending. When the change archives, the link
404s — but the sentence wrapped around it is the real defect, because it goes on describing shipped
work as planned and nothing about it looks broken.

#### Scenario: A change archives while a doc still links to it

- **WHEN** `README.md` links to `openspec/changes/add-compendium-capability` and that change now
  lives under `openspec/changes/archive/`
- **THEN** the lint errors, names the archive path, and says the surrounding sentence likely still
  describes the work as pending

#### Scenario: A doc links to a change that never existed

- **WHEN** a link names a change that is neither open nor archived
- **THEN** the lint errors

#### Scenario: A doc links to an open change

- **WHEN** the named change is a directory under `openspec/changes/`
- **THEN** the check passes silently

### Requirement: The new doc-claim checks are covered by the selftest

`tests/lint-plugins-selftest.py` MUST include one case per rule added here — a stale per-plugin
skill count, a link to an archived change, and a doer omitted from the marketplace's enumerated
list — each injecting only its own drift into a throwaway copy and asserting the lint reports it.

#### Scenario: A new doc-claim check is weakened

- **WHEN** any of the three checks is removed or loosened
- **THEN** its selftest case fails

### Requirement: The retired datalad doer is not referenced

The lint MUST report an error for the phrase "datalad doer", or the identifier `datalad-doer`,
matched case-insensitively and ignoring emphasis markers. It MUST scan every file under `plugins/`,
`templates/`, and `docs/` except `docs/talk/`. Archived OpenSpec changes MUST NOT be scanned.

#### Scenario: An instruction to the retired doer creeps back

- **WHEN** a planner body says "delegate to the **datalad doer**"
- **THEN** the lint errors, naming the file and line, and states that DataLad runs in the main thread

#### Scenario: History mentions it

- **WHEN** an archived change under `openspec/changes/archive/` names the datalad doer
- **THEN** nothing is reported

### Requirement: The retired-doer check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include a case that injects "datalad doer" into a planner
body and asserts the lint reports it.

#### Scenario: The check is weakened

- **WHEN** the retired-term check is removed or loosened
- **THEN** the selftest case fails

### Requirement: The lint rejects peripheral command lines in planner bodies

The lint MUST report an error for each workflow-plane skill whose body contains a peripheral
command span. A span is either:

- an inline code span whose first token is in a closed set of peripheral tool binaries;
- a line inside a fenced code block whose first token is in that set.

The set MUST be defined alongside the other closed vocabularies in `tests/lint-plugins.py`, and
MUST NOT include `datalad`, `git` or `git-annex`. Spans that run the harness's own scripts MUST
NOT be counted. The error MUST name the skill, the line and the binary.

#### Scenario: A planner quotes a nipoppy command

- **WHEN** a planner body contains `` `nipoppy process --pipeline fmriprep` ``
- **THEN** the lint errors, naming the skill, the line and `nipoppy`

#### Scenario: A planner saves with DataLad

- **WHEN** a planner body contains `` `datalad save -m "…"` ``
- **THEN** nothing is reported

#### Scenario: A planner runs a gate script

- **WHEN** `project/env-check` runs `bash plugins/bids-cli/scripts/check-validator.sh`
- **THEN** nothing is reported

#### Scenario: Toolbox skills

- **WHEN** a `*-cli` toolbox skill contains peripheral command lines
- **THEN** nothing is reported, because toolboxes are where command lines belong

### Requirement: The peripheral-syntax check is covered by the selftest

`tests/lint-plugins-selftest.py` MUST include an error case that injects a peripheral command span
into a planner, and MUST keep the pristine control at zero errors and zero warnings.

#### Scenario: The check is weakened

- **WHEN** the check is removed or its binary set is emptied
- **THEN** the selftest case fails
