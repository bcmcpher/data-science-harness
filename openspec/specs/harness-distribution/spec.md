# harness-distribution

## Purpose

How the harness's Markdown content reaches a working assistant configuration. The source layout is
Claude Code-compatible and is the single authored form; installed copies are adapted only in the
target directory, never in the repository. `bin/install.sh` is deliberately a small file copier and
translator so a user in a locked-down environment can reproduce it by hand. This spec covers the
installer contract and the portability constraints it imposes on authored content.
## Requirements
### Requirement: The source layout is the only authored form

Plugin content MUST be authored once under `plugins/<name>/` in the Claude Code layout
(`.claude-plugin/plugin.json`, `skills/*/SKILL.md`, `agents/*.md`, `references/`, optional `hooks/`).
Harness-specific variants MUST NOT be committed; they are produced at install time.

#### Scenario: Adding support for another assistant

- **WHEN** a new target harness is supported
- **THEN** the change is confined to the installer's translation step, and no plugin file is duplicated

### Requirement: The installer targets both Claude Code and OpenCode

`bin/install.sh` MUST accept `--harness opencode|claude-code` and `--scope project|global`, MUST
support `--target` to override the resolved directory, and MUST support `--dry-run` that prints the
copies it would make without touching the filesystem.

#### Scenario: Default invocation

- **WHEN** `bin/install.sh` runs with no arguments
- **THEN** it installs every plugin found under `plugins/*/.claude-plugin/plugin.json` for OpenCode
  at project scope

#### Scenario: Selecting individual plugins

- **WHEN** the user passes plugin names as positional arguments
- **THEN** only those plugins are installed

#### Scenario: Unsupported harness or scope

- **WHEN** an unrecognised `--harness` or `--harness`/`--scope` combination is given
- **THEN** the installer exits non-zero with a message naming the unsupported value, installing nothing

### Requirement: Agent frontmatter is translated for OpenCode

When installing for OpenCode, each agent file's frontmatter MUST be rewritten: `name:` and `tools:`
are dropped because OpenCode derives the name from the filename and does not use that tools
vocabulary, and `mode: subagent` MUST be inserted exactly once. The body MUST pass through unchanged.

#### Scenario: A doer is installed for OpenCode

- **WHEN** `plugins/datalad/agents/datalad-doer.md` is installed with `--harness opencode`
- **THEN** the installed copy has no `name:` or `tools:` line and carries a single `mode: subagent`

#### Scenario: An agent already declares a mode

- **WHEN** the source agent already has `mode:` in its frontmatter
- **THEN** that line is preserved and no second `mode:` is inserted

### Requirement: Prompt-visible paths are rewritten in installed copies only

Installed Markdown MUST have `${CLAUDE_PLUGIN_ROOT}` and `plugins/` path references rewritten to
resolve against the install location. This rewrite MUST apply to installed copies and MUST NOT
modify the repository.

#### Scenario: A skill references a bundled reference document

- **WHEN** a skill body points at `plugins/disseminate/references/equator-guidelines.md`
- **THEN** the installed copy points at that file's path under the install target, and the repository
  file is unchanged

#### Scenario: Dry run

- **WHEN** `--dry-run` is passed
- **THEN** the planned copies are printed and no rewrite occurs

### Requirement: Content survives translation

Authored skills and agents MUST remain loadable after the OpenCode translation. Any frontmatter
field that a target harness interprets differently MUST either be translated by the installer or be
removed from the installed copy. Specifically, `model:` MUST be translated to the target harness's
identifier form, and MUST be stripped when no translation exists, so the installed agent falls back
to the harness default rather than failing to resolve.

#### Scenario: A field is passed through untranslated

- **WHEN** an authored agent declares a field whose value form differs between harnesses, such as a
  bare `model:` name where the target expects a provider-prefixed identifier
- **THEN** the installer either translates or removes it, so the installed agent resolves in the
  target harness

#### Scenario: A model value has a known translation

- **WHEN** an agent declaring an allowed `model:` value is installed for OpenCode
- **THEN** the installed copy carries the provider-prefixed form that OpenCode resolves

#### Scenario: A model value has no translation for the target

- **WHEN** no mapping exists for the target harness
- **THEN** the installer strips the field, and the installed agent runs on the harness default

#### Scenario: Installing for Claude Code

- **WHEN** the same agent is installed for Claude Code
- **THEN** the authored value is used as written, because the source layout is Claude Code-compatible
  by definition and needs no translation for that target

### Requirement: Licensing travels with the content and is resolvable

The repository MUST declare licensing separately for code and for content, using SPDX short
identifiers rather than prose descriptions, and the declaration MUST be machine-readable. Content
MUST carry a licence that permits reuse with attribution.

#### Scenario: A reuser takes a single skill

- **WHEN** someone copies one `SKILL.md` out of the repository
- **THEN** the terms covering it are determinable from the repository's declared path mapping,
  without reading prose

#### Scenario: The paper declares its own licence

- **WHEN** `paper/myst.yml` declares a content and code licence for the manuscript
- **THEN** it agrees with the repository-wide declaration rather than contradicting it

