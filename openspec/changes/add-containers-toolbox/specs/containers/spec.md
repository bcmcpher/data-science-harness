## RENAMED Requirements

- FROM: `### Requirement: The containers doer builds images and nothing else`
- TO: `### Requirement: The containers doer authors and builds; it does not register or run`

## MODIFIED Requirements

### Requirement: The containers doer authors and builds; it does not register or run

The doer MUST own the path from a project's declared environment to a runnable image: emitting a
Dockerfile from a pinned manifest, building it, and converting the result to a `.sif`. It MUST
return the built image path together with the `datalad containers-add` command needed to register
it. It MUST NOT register the image, and MUST NOT run an analysis itself.

#### Scenario: A run needs an environment

- **WHEN** `analyze/run-comparison` requires a container that does not exist yet
- **THEN** it delegates the build to the containers doer, then delegates registration and the run to
  the datalad doer

#### Scenario: A new project needs a recipe

- **WHEN** `project/new-project` scaffolds a project that declares a pinned environment
- **THEN** the Dockerfile is derived from that manifest by the containers doer, rather than written
  by the planner

### Requirement: The build path is selected from the source and the target

The doer MUST choose its path from what the source actually is — a Dockerfile, an Apptainer
definition file, a local OCI image, or a remote reference — and from which artifact the caller needs,
rather than assuming one form. A request that names no target MUST resolve to a `.sif`, because that
is what `datalad containers-run` registers.

#### Scenario: Building from a Dockerfile

- **WHEN** the project provides a `Dockerfile` and a `.sif` is needed
- **THEN** the doer builds an OCI image, then converts that image to a `.sif`, reporting both steps

#### Scenario: Building from a definition file

- **WHEN** the project provides `containers/Apptainer.def`
- **THEN** the doer builds directly from that definition

#### Scenario: Building from a local OCI image

- **WHEN** the source is an image in the local Docker or Podman store
- **THEN** the doer routes through a saved archive rather than reading the daemon directly, because
  Apptainer speaks too old a Docker API for the direct path

### Requirement: Absent or ambiguous tooling is reported, not worked around silently

When no container runtime is available for a requested step, the doer MUST report that plainly so
the caller can skip or install, rather than substituting an unpinned environment. When more than one
OCI runtime is present, it MUST report which one it selected.

#### Scenario: No container runtime present

- **WHEN** a build is requested on a host with no runtime
- **THEN** the doer reports the missing dependency and builds nothing

#### Scenario: Only part of the path is available

- **WHEN** an OCI runtime is present but Apptainer is not, and a `.sif` was requested
- **THEN** the doer reports the OCI image it produced and states that the conversion did not run,
  rather than presenting the OCI image as the requested artifact

## ADDED Requirements

### Requirement: A Dockerfile is derived from a pinned manifest, never from recall

The toolbox MUST emit a Dockerfile only from a committed, version-pinned environment manifest, and
MUST NOT select a package or resolve a version itself. When the manifest is absent or unpinned, it
MUST refuse and name what would pin it.

This is what separates a rebuildable image from one that merely runs: an image built from guessed
pins is indistinguishable on inspection from one built from declared pins, and the difference
surfaces only when the rebuild produces something else.

#### Scenario: The environment is pinned

- **WHEN** the project declares a pinned `environment.yml`, `pyproject.toml` with `uv.lock`, or
  `renv.lock`
- **THEN** the emitted Dockerfile installs from that manifest, and names it as the source it was
  derived from

#### Scenario: The environment is not pinned

- **WHEN** the manifest names dependencies without resolved versions
- **THEN** the toolbox refuses to emit a Dockerfile, names the manifest, and states the command that
  would pin it

#### Scenario: No manifest exists

- **WHEN** the project declares no environment manifest
- **THEN** the toolbox reports that there is nothing to translate, rather than proposing a set of
  packages

### Requirement: The build runtime is reported, because it changes what the image requires

The toolbox MUST support Docker and Podman for OCI builds, MUST report which runtime performed a
build, and MUST report whether that build was rootless.

Podman and Docker produce the same layers, so the artifact does not differ — but a rootful build
implies privileges on the next machine that the user may not have, and that belongs in the report
rather than being discovered on a cluster.

#### Scenario: Both runtimes are available

- **WHEN** both Docker and Podman are present
- **THEN** the toolbox selects one, states which, and states why

#### Scenario: Only a rootful runtime is available

- **WHEN** the only available runtime requires privileges the user may lack
- **THEN** the gate reports that requirement explicitly rather than reporting the runtime as simply
  available

### Requirement: A cluster-bound image is a .sif, and the claim stops at what was verified

Converting an OCI image for cluster use MUST produce a `.sif` and MUST verify it before reporting
success. The toolbox MUST NOT claim that an image runs on a cluster it did not reach.

#### Scenario: An image is converted for a cluster

- **WHEN** a built OCI image is converted for use on a compute cluster
- **THEN** the `.sif` is verified locally, and the report distinguishes what was verified here from
  what was only transferred

#### Scenario: The destination was never contacted

- **WHEN** no transfer was performed
- **THEN** the report says the image is cluster-ready in form only, naming the transfer as not run

### Requirement: The toolbox is split by job, and each job owns one refusal

The `containers-cli` toolbox MUST provide one skill per job — authoring a Dockerfile, building an
OCI image, and converting or shipping to Apptainer — rather than one skill per binary, and MUST
provide an offline check reporting which runtimes are usable.

#### Scenario: A runtime is CLI-compatible with another

- **WHEN** a runtime such as Podman accepts the same commands as Docker
- **THEN** it is handled as a variant within the build skill, not duplicated as a separate skill

#### Scenario: A caller asks which runtimes are usable

- **WHEN** the offline check is run
- **THEN** it reports each runtime as available or unavailable with a stated reason, and answers a
  request for an unknown tool as a usage error
