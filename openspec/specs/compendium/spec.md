# compendium

## Purpose

The capability-plane wrapper over the build mechanics of a *living* research product — MyST and
Jupyter Book projects, `repo2data` fetches, and Paper2Agent-style agent bundles. It exists for
Actionability and Ephemerality: a compendium that does not rebuild is just a directory, and the two
`disseminate` planners that promise one could previously describe a MyST tree or an MCP server and
commit whatever the assistant wrote, and nothing more.

Its governing discipline is that **a green build is not reproducibility.** MyST will compile a
document whose figures are committed images and report success; Jupyter Book renders a notebook's
traceback into the page and exits 0. So the properties this capability actually owns are the two a
build cannot establish on its own: every figure traces to a provenanced run, and the build ran in
the project's pinned container. A figure that cannot be traced is reported as unprovenanced rather
than embedded, and with no registered image the doer reports that the build cannot be pinned rather
than falling back to the host — an unpinned build reported as success is a false claim about
Portability.

The same discipline shapes the bundle path. A bundle is emitted in the harness's **own** format —
marketplace manifest, plugin manifest, skills, MCP config — so a published bundle is installable by
`bin/install.sh` and checkable by the same lint the harness applies to itself; a format claim made
without running that lint is an assertion. Tool parameters are read from each script's real argument
parser rather than inferred, because an invented default produces a tool that runs and returns a
plausible number. Reproduction tests are part of the bundle rather than optional, and emitting a
server is not starting one.

The line it does not cross: this capability **builds, it does not author.** Figure content, narrative
and tool semantics come from the planner and the user.

## Requirements
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

