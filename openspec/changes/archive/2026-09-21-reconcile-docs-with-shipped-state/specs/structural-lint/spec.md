## MODIFIED Requirements

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

## ADDED Requirements

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
