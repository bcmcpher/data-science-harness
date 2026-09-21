## ADDED Requirements

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
