# skill-format

## Purpose

The universal on-disk contract every harness skill and doer agent obeys, independent of which
assistant loads it. This is the two-plane discipline made mechanical: a planner skill holds
research process and never touches a CLI, a doer agent owns tool mechanics and is the only thing
that runs tools, and delegation between them is declared in frontmatter *and* stated in prose so it
survives translation to harnesses that have no frontmatter vocabulary. Every requirement below is
enforced today by `tests/lint-plugins.py`; `templates/skill/SKILL.md` is the authored form.

## Requirements

### Requirement: Skill identity matches its location

Every skill SHALL declare a `name` in YAML frontmatter, and that name SHALL equal the name of the
directory containing its `SKILL.md`. The name SHOULD be kebab-case.

#### Scenario: Name and directory agree

- **WHEN** `tests/lint-plugins.py` reads `plugins/<plugin>/skills/<dir>/SKILL.md`
- **THEN** it reports an error unless the frontmatter `name` is present and equal to `<dir>`

#### Scenario: Name is not kebab-case

- **WHEN** a skill declares `name: Raw_To_BIDS`
- **THEN** the lint emits a warning, because harnesses differ in how they slugify skill names

### Requirement: Skills declare a discoverable description

Every skill SHALL declare a `description`. A planner skill's description SHOULD embed quoted
trigger phrases, since that text is the only signal an assistant has when deciding whether to load
the skill. Descriptions SHOULD stay under 1024 characters.

#### Scenario: Description absent

- **WHEN** a `SKILL.md` has no `description` field
- **THEN** the lint reports an error and the skill is treated as unloadable

#### Scenario: Description carries no trigger phrases

- **WHEN** a planner description contains no quoted phrase
- **THEN** the lint emits a warning, because the skill will rarely be selected in practice

### Requirement: Skills declare a plane and STAMPED coverage

A harness skill SHALL declare `plane` as either `workflow` or `capability`, and SHOULD declare
`stamped` as a list of the letters `S T A M P E D` naming which STAMPED principles it advances.
Vendored `*-cli` toolbox plugins are exempt: they wrap a single CLI verb and carry
`user-invocable: true` plus an `argument-hint` instead.

#### Scenario: Invalid plane value

- **WHEN** a skill declares `plane: technical`
- **THEN** the lint reports an error, because only `workflow` and `capability` are defined

#### Scenario: Invalid or duplicated STAMPED letter

- **WHEN** a skill declares `stamped: [S, S, X]`
- **THEN** the lint reports an error for `X` and a warning for the duplicated `S`

### Requirement: Delegation is declared and resolvable

A planner skill SHALL express every delegation to a doer twice: once as a `delegates_to` list in
frontmatter, and once in the instruction body as prose naming the doer. Each entry in
`delegates_to` SHALL name a plugin that actually provides an agent. DataLad is not a delegation
target. A planner runs DataLad directly and SHALL NOT refer to a "datalad doer".

#### Scenario: Delegating to a plugin with no doer

- **WHEN** a skill declares `delegates_to: [annotate]` and no `plugins/annotate/agents/` exists
- **THEN** the lint reports an error, because the planner would delegate into nothing at runtime

#### Scenario: Prose and frontmatter disagree

- **WHEN** a skill body says "delegate to the **containers** doer" but `delegates_to` omits `containers`
- **THEN** the lint reports an error; and **WHEN** `delegates_to` lists a doer the body never names,
  the lint emits a warning

#### Scenario: A planner saves its work

- **WHEN** a planner's step records a change
- **THEN** it runs `datalad save` in its own steps, and declares no DataLad delegation

### Requirement: Planner skills carry the standard instruction sections

A planner skill body SHALL be checked for the sections `## When to use`, `## Steps`, and
`## Constraints`, and each missing section SHALL be reported, so an assistant reading a truncated
skill still knows the boundary conditions.

#### Scenario: A planner omits Constraints

- **WHEN** a workflow-plane skill has no `## Constraints` section
- **THEN** the lint emits a warning naming the missing section

### Requirement: Doer agents declare identity and a tool budget

Every agent file SHALL declare a `name` equal to its filename stem and a `description`. It SHOULD
declare `tools`, scoped to what the doer actually needs.

#### Scenario: Agent name does not match its filename

- **WHEN** `plugins/bids/agents/bids-doer.md` declares `name: bids`
- **THEN** the lint reports an error

#### Scenario: Agent omits a tools list

- **WHEN** an agent declares no `tools`
- **THEN** the lint emits a warning, because the agent inherits an unbounded tool set

### Requirement: Frontmatter parses as strict YAML

Skill and agent frontmatter SHALL parse under a strict YAML loader, not only under Claude Code's
lenient parser, so the same file loads unchanged in every target harness. Frontmatter that parses
only under the lenient reading SHALL be reported as a portability defect rather than a hard failure.

#### Scenario: Two unquoted flow sequences on one line

- **WHEN** a skill declares `argument-hint: [a] [b]`, which strict YAML rejects but Claude Code accepts
- **THEN** the lint re-parses with a relaxed pass and emits a portability warning rather than failing

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
