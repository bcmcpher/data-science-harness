## MODIFIED Requirements

### Requirement: Content survives translation

Authored skills and agents MUST remain loadable after the OpenCode translation. Any frontmatter
field that a target harness interprets differently MUST either be translated by the installer or be
removed from the installed copy. Specifically, `model:` MUST be translated to the target harness's
identifier form, and MUST be stripped when no translation exists, so the installed agent falls back
to the harness default rather than failing to resolve.

#### Scenario: A model value has a known translation

- **WHEN** an agent declaring an allowed `model:` value is installed for OpenCode
- **THEN** the installed copy carries the provider-prefixed form that OpenCode resolves

#### Scenario: A model value has no translation for the target

- **WHEN** no mapping exists for the target harness
- **THEN** the installer strips the field, and the installed agent runs on the harness default

#### Scenario: Installing for Claude Code

- **WHEN** the same agent is installed for Claude Code
- **THEN** the authored value is used as written, because it is drawn from that harness's vocabulary
