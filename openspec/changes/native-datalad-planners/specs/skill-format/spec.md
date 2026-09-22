## MODIFIED Requirements

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
