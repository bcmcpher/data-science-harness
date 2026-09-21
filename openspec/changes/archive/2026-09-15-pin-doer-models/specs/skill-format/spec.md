## ADDED Requirements

### Requirement: The model field is defined and optional

`model:` MUST be a documented optional frontmatter field on agent files, naming the model an agent
should run on. Its absence MUST mean "use the harness default". `templates/skill/SKILL.md` and the
README's Universal Skill Format section MUST both describe it.

#### Scenario: An agent omits model

- **WHEN** an agent declares no `model:`
- **THEN** it runs on whatever the harness defaults to, and the lint reports nothing

#### Scenario: A contributor looks up the field

- **WHEN** a contributor reads the skill template or the Universal Skill Format section
- **THEN** `model:` is listed among the optional fields with its allowed values

### Requirement: Authored model values use the source layout's vocabulary

An authored `model:` value MUST be drawn from the allowed set, which uses the bare-alias form the
Claude Code source layout accepts, because `harness-distribution` makes that layout the single
authored form. It MUST NOT be a provider-prefixed identifier: translating the authored value into a
target harness's syntax is the installer's job, and an authored value that is already in one target's
syntax cannot be translated for the others.

#### Scenario: An author writes a provider-prefixed value

- **WHEN** an agent declares a value in a target harness's native identifier syntax rather than the
  authored bare-alias form
- **THEN** the lint rejects it, because the installer — not the author — produces target-specific forms

### Requirement: Only read-only agents are pinned

An agent that can mutate a dataset or publish to an external service MUST NOT declare `model:`.
Pinning MUST be limited to agents that only read and report.

#### Scenario: A mutating doer

- **WHEN** the datalad, archive, containers, or nipoppy doer is authored
- **THEN** it declares no `model:` and runs on the session default

#### Scenario: A read-only agent

- **WHEN** the bids doer or the coordinator is authored
- **THEN** it may declare a pinned `model:` from the allowed set
