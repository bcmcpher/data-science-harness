## MODIFIED Requirements

### Requirement: The containers doer authors and builds; it does not register or run

The doer MUST own the path from a project's declared environment to a runnable image: emitting a
Dockerfile from a pinned manifest, building it, and converting the result to a `.sif`. It MUST
return the built image path together with the `datalad containers-add` command needed to register
it. It MUST NOT register the image, and MUST NOT run an analysis itself.

#### Scenario: A run needs an environment

- **WHEN** `analyze/run-comparison` requires a container that does not exist yet
- **THEN** it delegates the build to the containers doer, then registers the image with the returned
  `datalad containers-add` command and runs the analysis under `datalad containers-run` itself

#### Scenario: A new project needs a recipe

- **WHEN** `project/new-project` scaffolds a project that declares a pinned environment
- **THEN** the Dockerfile is derived from that manifest by the containers doer, rather than written
  by the planner
