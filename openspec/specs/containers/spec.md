# containers

## Purpose

The capability-plane wrapper over a project's compute environments, along the path people actually
use: **Dockerfile → OCI image → `.sif`.** Environments are authored in Docker or Podman; Apptainer is
what compute clusters provide, and a `.sif` is what `datalad containers-run` registers. An earlier
version of this spec described the capability as a wrapper over Apptainer builds with Docker as a
source to convert *from*, which had the arrow backwards.

**A project has several environments, not one.** A real study runs an authored analysis environment
beside vendored pipeline images such as fMRIPrep and QSIPrep, and often a derived image adding the
project's own scripts to a standard base. Each is named and each records the pipeline it serves. No
registry is introduced for this: `datalad containers-add <name>` already keys containers by name and
`containers-run --container-name <name>` selects among them.

The governing discipline is that **an image that runs is not an image that rebuilds.** The two fail
identically on inspection — both build, both execute, both produce numbers — and diverge only when
someone rebuilds a year later. So what this capability refuses is more characteristic of it than what
it builds: an unpinned manifest, a `conda env export` carrying platform-specific build strings, a
mutable image tag recorded as a pin, and an unpinned install step layered onto a pinned base. Each
refusal names the command that would fix it, because a refusal without a remedy just gets worked
around.

A second discipline is that the capability reports what the machine required of it, not only what it
produced. Podman and Docker build the same layers, so the artifact is identical; what differs is that
a rootful Docker demands group membership the next user may not have. That belongs in the report
rather than being discovered on a cluster.

The boundaries are deliberate and narrow. This capability builds and pins; **registering
(`datalad containers-add`) and running (`containers-run`) stay with the planner**, which runs DataLad
directly, so provenance has exactly one owner. And **`nipoppy` declares which pipeline and version a dataset runs** while
this capability obtains, pins and converts the image that pipeline executes in — neither owns both.

What it does not choose is the science: which packages an analysis needs is the user's, and this
capability only translates what the project already declared.

## Requirements

### Requirement: The built image is reported, not assumed

The doer MUST report the operation, the exact build command, `result`, and the resulting image path,
and MUST show the constructed command before building.

#### Scenario: A build fails

- **WHEN** the build returns non-zero
- **THEN** the doer surfaces the error, returns `result: failed`, and leaves no partial image
  presented as usable

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

### Requirement: An authored environment is derived from a pinned manifest, never from recall

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

### Requirement: A project has several environments, each named and each pinned for its kind

The capability MUST support more than one compute environment per project and MUST NOT assume a
single one. Each environment MUST be named, MUST record which pipeline or analysis it serves, and
MUST carry a pin appropriate to how it came to exist:

| Kind | What pins it |
|---|---|
| **authored** — built from a manifest the project owns | the pinned manifest |
| **vendored** — a published pipeline image | the image digest |
| **derived** — a vendored base plus the project's own additions | the base digest **and** a pinned manifest for what was added |

No new registry is introduced: `datalad containers-add <name>` already keys containers by name, and
`containers-run --container-name <name>` already selects among them.

#### Scenario: A study runs several pipelines

- **WHEN** a project uses fMRIPrep, QSIPrep and a local analysis environment
- **THEN** each is built and registered under its own name, and the report states which pipeline each
  serves

#### Scenario: A request does not say which environment

- **WHEN** a build or conversion is requested and the project holds more than one environment
- **THEN** the doer asks which one rather than defaulting to the only one it happens to find

### Requirement: A mutable tag is not a pin

A vendored or derived environment MUST be pinned by image digest. The toolbox MUST resolve a tag to
its digest and record the digest, and MUST NOT accept a tag alone as a pin.

A tag can be re-pushed, so two runs a year apart can name `fmriprep:23.2.0` and execute different
code. This is the same failure as an unpinned manifest, arriving by a different route, and it is
invisible in the same way.

#### Scenario: An image is requested by tag

- **WHEN** a pipeline container is named by tag
- **THEN** the tag is resolved to a digest, the digest is what is recorded, and the report shows both

#### Scenario: The digest cannot be resolved

- **WHEN** no registry can be reached to resolve the tag
- **THEN** the toolbox reports that the pin could not be resolved and does not record the tag as
  pinned, while still accepting a digest the user supplies directly

### Requirement: A derived environment pins both its base and its additions

A derived environment MUST pin its base by digest and MUST install its additions from a pinned
manifest. The toolbox MUST NOT emit an unpinned install step into a derived image.

An unpinned layer on a pinned base is the quiet version of this failure: the base is identical a year
later and the layer on top is not.

#### Scenario: Tools are added to a standard container

- **WHEN** a project adds its own scripts and extra packages to a vendored pipeline image
- **THEN** the emitted Dockerfile names the base by digest and installs the additions from a pinned
  manifest

#### Scenario: The additions are not pinned

- **WHEN** the tools to add are given as bare package names
- **THEN** the toolbox refuses, and names what would pin them, rather than emitting a plain install
  step

### Requirement: Declaring a pipeline and obtaining its image have different owners

The `containers` capability MUST own obtaining, pinning, building and converting images. Declaring
which pipeline and which version a dataset runs MUST remain with `nipoppy`. Neither MUST claim both.

#### Scenario: A pipeline version is declared

- **WHEN** a dataset declares a pipeline and version in its nipoppy configuration
- **THEN** the containers capability pins and obtains the image for that version, and does not
  change the declaration

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
