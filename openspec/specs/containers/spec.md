# containers

## Purpose

The capability-plane wrapper over Apptainer/Singularity image builds. Its single job is to turn a
project's container recipe into a pinned, rebuildable `.sif` so analyses execute in a fixed
environment — STAMPED Portability and Ephemerality made concrete. The boundary with `datalad` is
deliberate and narrow: this capability builds the image, while registering it into the dataset
(`datalad containers-add`) and running inside it (`container-run`) stay with the datalad doer, so
provenance has exactly one owner. Today the whole surface is
`plugins/containers/agents/containers-doer.md`.

## Requirements

### Requirement: The containers doer builds images and nothing else

The doer MUST build a `.sif` from a recipe and return the built image path together with the
`datalad containers-add` command needed to register it. It MUST NOT register the image or run an
analysis itself.

#### Scenario: A run needs an environment

- **WHEN** `analyze/run-comparison` requires a container that does not exist yet
- **THEN** it delegates the build to the containers doer, then delegates registration and the run to
  the datalad doer

### Requirement: The build path is selected from the recipe

The doer MUST choose its build path from what the recipe actually is — an Apptainer definition file,
a local Docker image, or another supported source — rather than assuming one form.

#### Scenario: Building from a definition file

- **WHEN** the project provides `containers/Apptainer.def`
- **THEN** the doer builds directly from that definition

#### Scenario: Building from a local Docker image

- **WHEN** the source is an image in the local Docker daemon
- **THEN** the doer routes through a `docker save` archive rather than reading the daemon directly,
  because older Apptainer releases speak too old a Docker API for the direct path

### Requirement: The built image is reported, not assumed

The doer MUST report the operation, the exact build command, `result`, and the resulting image path,
and MUST show the constructed command before building.

#### Scenario: A build fails

- **WHEN** the build returns non-zero
- **THEN** the doer surfaces the error, returns `result: failed`, and leaves no partial image
  presented as usable

### Requirement: Absent tooling is reported, not worked around silently

When no Apptainer or Singularity runtime is available, the doer MUST report that plainly so the
caller can skip or install, rather than substituting an unpinned environment.

#### Scenario: No container runtime present

- **WHEN** a build is requested on a host with no runtime
- **THEN** the doer reports the missing dependency and builds nothing
