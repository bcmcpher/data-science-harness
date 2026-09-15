## MODIFIED Requirements

### Requirement: The executable article rebuilds its own figures

`disseminate/executable-article` MUST delegate scaffolding and building to the compendium doer, and
MUST declare `delegates_to: [compendium, datalad]`. The produced article's figures MUST be wired to
the provenanced data and built in the project's container environment, so the article regenerates its
results rather than embedding static images.

#### Scenario: A reproducible preprint is scaffolded

- **WHEN** an executable article is produced for a released product
- **THEN** each figure names the run that generated it, and the article builds from the pinned
  environment

#### Scenario: The build fails

- **WHEN** the compendium doer reports a build failure
- **THEN** the skill reports it and does not register the article product as buildable

### Requirement: The agent bundle exposes methods as callable tools

`disseminate/agent-bundle` MUST delegate bundle emission to the compendium doer and MUST declare
`delegates_to: [compendium, datalad]`. The bundle MUST be emitted in the harness's own skill and
manifest format alongside an MCP configuration, and MUST include tests that reproduce the product's
recorded results.

#### Scenario: Methods are made agent-callable

- **WHEN** an agent bundle is produced
- **THEN** it is loadable by an assistant as tools, and its reproduction tests check the results
  against what the provenance chain recorded

#### Scenario: A tool's result cannot be reproduced

- **WHEN** a reproduction test fails
- **THEN** the failing tool is reported and the bundle records which tools are verified
