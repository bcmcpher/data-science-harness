## ADDED Requirements

### Requirement: The compendium doer owns build mechanics

The compendium doer MUST own MyST and Jupyter Book invocation, `repo2data` configuration, and MCP
server scaffolding. Planner skills MUST NOT invoke those tools directly.

#### Scenario: An article is scaffolded

- **WHEN** `disseminate/executable-article` needs a MyST project created for a product
- **THEN** it delegates the scaffold and build to the compendium doer

### Requirement: A produced article builds from the project's pinned environment

The compendium doer MUST build a produced article inside the project's container, not the host
environment, and MUST report the build result.

#### Scenario: The article is built

- **WHEN** a build is requested for a scaffolded article
- **THEN** the build runs in the pinned environment and either succeeds or reports the failure with
  the failing step

#### Scenario: No container image exists

- **WHEN** the project has no built image
- **THEN** the doer reports that the build cannot be pinned, rather than falling back to the host

### Requirement: Figures are wired to the runs that produced them

Each figure in a produced article MUST name the provenanced run that generated it, so the rebuild is
checkable against the DataLad history.

#### Scenario: A figure is added to an article

- **WHEN** a figure is wired into the article
- **THEN** it references the run commit that produced its underlying output

#### Scenario: A figure has no recorded run

- **WHEN** a figure's output cannot be traced to a run
- **THEN** the doer reports it as unprovenanced rather than embedding it silently

### Requirement: Data is fetched declaratively

External data an article needs MUST be declared for `repo2data` rather than fetched by ad hoc script,
so a reader rebuilding the article obtains the same inputs.

#### Scenario: An article depends on a released dataset

- **WHEN** the article's data lives in a released, DOI'd product
- **THEN** the fetch is declared against that identifier

### Requirement: Agent bundles are emitted in the harness's own format

An emitted agent bundle MUST consist of skill files, a plugin manifest, and an MCP configuration in
the same universal format the harness uses, so a published bundle is installable by `bin/install.sh`.

#### Scenario: A bundle is produced

- **WHEN** the doer emits a bundle for a product
- **THEN** the result passes the same structural lint the harness applies to its own plugins

### Requirement: Bundles carry reproduction tests

An emitted agent bundle MUST include tests that reproduce the product's recorded results, and the
doer MUST report which tools are covered.

#### Scenario: A tool does not reproduce its recorded result

- **WHEN** a reproduction test fails
- **THEN** the doer reports the failing tool, and the bundle is not presented as reproducing the paper

### Requirement: Every operation returns a structured result

The compendium doer MUST report the operation, the command executed, `result`, the artifact path,
and notes naming any unprovenanced figure, uncovered tool, or missing dependency.

#### Scenario: A build dependency is absent

- **WHEN** MyST or a container runtime is unavailable
- **THEN** the doer reports the missing dependency and produces no partial artifact presented as
  complete
