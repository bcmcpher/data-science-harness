## Context

`plugins/containers/agents/containers-doer.md` is the whole capability today: one agent, no toolbox.
It builds a `.sif` from an Apptainer definition, a remote OCI reference, or a local Docker image, and
hands back a `datalad containers-add` command. It is correct about the thing it does, including a
real and hard-won detail — apptainer 1.1.x speaks too old a Docker API to read a modern daemon, so
the local-Docker path must go through `docker save` → `docker-archive://`, never `docker-daemon://`.
That knowledge is verified in `tests/e2e-smoke.sh` and must survive this change intact.

What it does not do is the part people actually spend time on: turning a declared analysis
environment into a container recipe at all.

## Goals / Non-Goals

**Goals:**
- A Dockerfile that demonstrably corresponds to the project's declared, pinned environment.
- One path from that Dockerfile to a cluster-runnable `.sif`, with the docker-archive detour owned
  by a skill rather than remembered by an agent.
- Podman usable wherever docker is, without a second copy of the build skill.

**Non-Goals:**
- Choosing the scientific environment. Unchanged, and sharpened below.
- Registering or running the image. `datalad containers-add` / `containers-run` stay with the
  datalad doer; provenance keeps one owner.
- Hosting a registry, or managing cluster accounts and schedulers. Moving a `.sif` to a known
  destination is in scope; obtaining the destination is not.
- Building multi-architecture images. Named here because it is the obvious next ask and would
  change the build skill's shape.

## Decisions

- **Translation is mechanical; selection is not.** The `dockerfile` skill emits a Dockerfile **only**
  from a committed, version-pinned manifest — `environment.yml`, `pyproject.toml` + `uv.lock`, or
  `renv.lock`. It never picks a package and never resolves a version.

  This is the decision the whole change turns on, so the reasoning is worth stating: an image built
  from guessed pins is indistinguishable, on inspection, from one built from declared pins. Both run.
  Both produce numbers. Only one is rebuildable, and the difference surfaces months later when the
  rebuild yields something else. Refusing an unpinned manifest is therefore not pedantry — it is the
  only moment where the difference is still visible.

  The refusal has a stated remedy rather than being a dead end: the skill names which manifest is
  unpinned and what would pin it (`conda env export --no-builds`, `uv lock`, `renv::snapshot()`), so
  the user fixes the manifest rather than working around the skill.

- **An environment comes to exist in one of three ways, and the pin differs for each.** This is the
  distinction the toolbox must carry, because the three look identical once built:

  | Kind | What it is | What pins it |
  |---|---|---|
  | **authored** | built from a manifest the project owns | the pinned manifest |
  | **vendored** | a published pipeline image — fMRIPrep, QSIPrep, MRIQC | the image **digest** |
  | **derived** | a vendored base plus the project's own scripts and tools | the base digest **and** a pinned manifest for what was added |

  **A tag is not a pin.** `nipreps/fmriprep:23.2.0` is mutable: the same tag can be re-pushed, so two
  runs a year apart can name it and execute different code. Resolving the tag to
  `@sha256:…` at registration time is the whole difference, and it costs one command. Accepting a
  tag would reproduce, for vendored images, exactly the failure the unpinned-manifest refusal exists
  to prevent — an image that runs, produces numbers, and is not rebuildable.

  **Derived is where this breaks quietly.** A `RUN pip install nilearn` appended to a standard
  container is the most natural thing to write and pins nothing; a year later the base is the same
  and the layer on top is not. So a derived environment is held to both pins, not one.

- **Environments are plural, named, and keyed by the pipeline they serve.** The capability must stop
  saying "the project's environment". A real study has an authored analysis environment, one vendored
  image per pipeline, and sometimes a derived one. **No new registry is added**: `datalad
  containers-add <name>` already keys containers by name in `.datalad/config`, and `containers-run
  --container-name <name>` already selects among them. The containers capability builds and pins;
  naming and selection stay where they already work.

- **The boundary with `nipoppy` is declaration versus image.** Nipoppy's config declares which
  pipeline and which version a dataset runs; this capability obtains, pins and converts the image
  that pipeline executes in. Neither owns both. Stated here because both plausibly could claim it,
  and a capability boundary that is only implied is one that gets crossed.

- **Split by job, not by binary.** `dockerfile` (author), `oci-build` (build), `apptainer` (convert
  and ship). Docker and podman are CLI-compatible and produce the same layers, so a skill each would
  be two near-duplicates that drift. Splitting by job also puts each refusal in exactly one place:
  "will not invent a pin" belongs to authoring, "will not report an image that did not build" to
  building, "will not claim a `.sif` runs on a cluster it never reached" to export.

- **Podman is a runtime variant, and its difference is admin, not syntax.** `oci-build` detects which
  runtime is present, prefers podman when both are (rootless by default, no daemon, no docker group),
  and reports which one built the image — because the answer changes what the resulting image
  requires of the next machine. The gate reports rootless vs rootful explicitly: a rootful docker
  build on a shared machine implies group membership that the user may not have and may not be able
  to get.

- **The `.sif` remains the provenanced artifact.** Authoring moves to Docker; what `datalad
  containers-run` registers is still a `.sif`. This keeps the reframe from touching the provenance
  story at all.

- **The docker-archive detour becomes a skill's constraint rather than an agent's memory.** It moves
  into `apptainer`'s prose, with the failure it prevents quoted, so it survives a doer rewrite.

- **`new-project` stops hand-writing a Dockerfile.** Step 4 currently writes a recipe from recall.
  It delegates to the containers doer instead, which means a new project either gets a Dockerfile
  derived from its declared environment or is told plainly that its environment is not yet pinned.

## Risks / Trade-offs

- **The reframe touches a spec that governs working code.** Two requirements are MODIFIED rather than
  added, and the doer's build-path table is load-bearing for `analyze/run-comparison`. The
  apptainer↔Docker caveat is the specific thing most likely to be lost in a rewrite; the task list
  calls it out as its own verification step.
- **Three runtimes, none installed on the development machine.** Like every other toolbox here, the
  gates will be tested and the paths behind them will not. The change should not pretend otherwise —
  but it is also the capability most likely to be genuinely exercisable, since docker and apptainer
  have both run in this suite before. Recorded as the obvious follow-up, not smuggled in.
- **Refusing unpinned manifests will be hit immediately.** `conda env export` without `--no-builds`
  produces build-string pins that are not portable across platforms; a plain `environment.yml`
  written by hand usually has none. The skill must distinguish *unpinned* from *over-pinned* and say
  which, or it will read as broken.
- **Digest resolution needs the network, and the refusal must not become unusable offline.** Turning
  a tag into a digest requires contacting a registry. On a cluster login node or an air-gapped
  machine that will fail, and the skill must then report that the pin could not be resolved rather
  than silently accepting the tag — while still letting a user supply a digest they already have.
  This is the most likely place for the pinning rule to be worked around in practice.

- **Derived images invite scope creep toward a package manager.** Once the toolbox emits
  `FROM <base>@sha256:…` plus added tools, the obvious next asks are dependency resolution and
  conflict handling against the base image's existing environment. It must stay a translator: what
  gets added comes from a manifest the user owns.

- **`renv.lock` is the weakest leg.** The R path is specified for symmetry, but no R project exists
  in this repository to check it against, and it should be marked as unexercised rather than assumed.
