## Context

`openspec/specs/containers/spec.md` fixes the containers capability's shape:

- one skill per job (`dockerfile`, `oci-build`, `apptainer`) plus an offline runtime gate;
- three environment kinds (authored, vendored, derived), each with its own pin;
- a mutable tag is never a pin;
- the doer builds but never registers or runs. `datalad containers-add` and `containers-run`
  belong to the planner, so provenance has one owner.

The dataset layout is also fixed:

- recipes and `.sif` files live at the dataset root under `containers/`
  (`analyze/run-comparison` asks for `containers/<name>.sif`, and the spec names
  `containers/Apptainer.def`);
- `project/new-project`'s `.bidsignore` already excludes `containers/`;
- `nipoppy init` (0.4.5) also creates a top-level `containers/`;
- the YODA reference (`plugins/datalad-cli/references/yoda-layout.md`) reserves `inputs/` for
  input *data* subdatasets and `code/` for scripts.

What upstream says, as fetched on 2026-09-25:

- **Neurodocker** (README): installed with `pip install neurodocker`, or run as
  `docker run --rm repronim/neurodocker:<tag>`. The example command is
  `neurodocker generate docker -p apt --base-image debian:bookworm --mrtrix3 version=3.0.4 method=source > Dockerfile`.
  `generate singularity` is the recipe-for-Apptainer form. The README does not say whether
  generation needs network access. That is **unverified**. Generation renders templates, so
  offline is expected, and task 4.2 checks it.
- **ReproNim/containers** (README and `.datalad/config`):
  - It is installed with `datalad install -d . -s ///repronim/containers code/containers`.
  - Its `.datalad/config` defines 662 `datalad "containers.<name>"` sections. Images live under
    `images/<category>/<name>--<version>.sif` (older ones end in `.sing`), for example
    `images/bids/bids-aa--0.2.0.sif`.
  - Each image is registered with `cmdexec = {img_dspath}/scripts/singularity_cmd run {img} {cmd}`.
  - `singularity_cmd` runs with a cleaned environment and a bound temporary `HOME` and `/tmp`. It
    uses a Docker shim when `REPRONIM_USE_DOCKER` is set or on non-Linux hosts, reads
    `SINGULARITY_CMD` (`run` by default, or `exec`), and wraps the run in `duct` when
    `REPRONIM_USE_DUCT` is set.
  - The README's run examples use `-n bids-mriqc`. How a container registered in a subdataset is
    named from the superdataset is **unverified**: it may be a bare name, or prefixed with the
    subdataset path. Task 4.4 confirms it with `datalad containers-list`.
- On this machine `singularity` is a symlink to `apptainer` 1.1.9, so `singularity_cmd` can resolve
  a runtime. On a host with apptainer and no such symlink it may not. That is also **unverified**,
  and task 4.4 records the result.

## Goals / Non-Goals

**Goals:**
- A request for neuroimaging software with no manifest becomes a pinned, regenerable recipe rather
  than a refusal.
- An image that ReproNim already publishes is found and used before one is built.
- The doer still builds and never registers or runs. The planner still runs DataLad.

**Non-Goals:**
- Mirroring or forking ReproNim/containers. It is consumed as a subdataset.
- Running ReproNim images in the default e2e (size), or on a cluster.
- `neurodocker minify`.
- Choosing which software goes into a recipe. As with `dockerfile`, the user or planner names the
  software and versions.

## Decisions

**D1. A neurodocker recipe is an *authored* environment. Its manifest is the generating command.**
`containers/<name>/` holds three things:

- the recipe (`Dockerfile` or `Singularity`);
- `neurodocker.sh`, the exact `neurodocker generate …` command;
- a header comment in the recipe naming the neurodocker version.

The pin rule follows from the existing spec:

- every software flag carries `version=`;
- the base image is named by digest, resolved through the existing `check-runtimes.sh digest` path;
- the neurodocker version is recorded.

The skill refuses a request that breaks any of these, and names the missing pin. It reports
honestly that `apt` and `yum` layers inside the generated recipe are not version-locked. That is a
`notes:` line, not a refusal, because it is intrinsic to neurodocker's templates.

*Alternative: treat neurodocker output as a derived image.* Rejected. There is no vendored base
image the project chose for its content; the base is an OS image, and what is added comes from
neurodocker's templates.

**D2. A ReproNim image is *vendored*, and its pin is the subdataset commit plus the image's annex
key.** A `.sif` fetched from the subdataset is content-addressed by git-annex. The superdataset
records the subdataset's commit in `.gitmodules` state. Together these are at least as strong as an
OCI digest, and `datalad containers-run` records the image key in the run commit (the e2e's
containers-run block already asserts `extra_inputs` for its own image). The spec's "a mutable tag is
not a pin" requirement is about registry tags. This decision states explicitly that a ReproNim
image satisfies the vendored-pin rule, and that `--follow=sibling` updates are a version change the
planner records.

*Alternative: require a digest by converting to OCI first.* Rejected. It would discard the
provenance the dataset already carries, and add a build step for an image that is already built.

**D3. The skill returns DataLad commands, and the planner runs them.** Installing a subdataset
(`datalad clone -d .`), fetching one image (`datalad get`) and running (`datalad containers-run`)
are DataLad operations, and those belong to the main thread. The `repronim-containers` skill:

- reads the catalog: the installed subdataset's `.datalad/config` if present, otherwise a
  temporary clone outside the dataset, with no annex content;
- reports matches by tool and version;
- returns the install, get and run commands;
- returns the `binding: containers/repronim@<subdataset commit>` line.

*Alternative: let the doer install the subdataset.* Rejected. It would give the containers doer a
DataLad write, which the containers spec's boundary forbids.

**D4. The ReproNim check is advisory and never blocks a build.** Before a vendored or derived build,
the doer looks up the catalog. It reports one of three results:

- `catalog: match <name> <version>`: it stops and asks whether to use the match;
- `catalog: no match`: it proceeds;
- `catalog: not checked (<why>)`: no network and no installed subdataset. It proceeds and says so.

*Alternative: require the lookup to succeed.* Rejected. An offline build would then be impossible.

**D5. `DSH_NET=1` gates every e2e step that touches the network.** No section fetches by default.
The ReproNim step clones metadata only, with no `datalad get`. An image run needs a second opt-in,
`DSH_NET_IMAGES=1`, because images are hundreds of megabytes.

*Alternative: one gate for both.* Rejected. A developer who is fine with a metadata clone should
not download a pipeline image by accident.

**D6. `neurodocker` joins `PERIPHERAL_BINARIES`.** Planners name the doer and state intent. The
toolbox skills may quote the command, as for the other container binaries.

## Risks / Trade-offs

- [The ReproNim catalog is large and lookups are slow.] → Read `.datalad/config` only. It is one
  text file, and `git config -f` parses it without DataLad.
- [`singularity_cmd` expects a `singularity` binary.] → The skill documents the symlink
  requirement and the `REPRONIM_USE_DOCKER` fallback. Task 4.4 records what happens on apptainer
  without the symlink.
- [Neurodocker templates change between releases, so the same command yields a different recipe.]
  → Recording the neurodocker version is the pin, and the test env locks one version. Regeneration
  with another version is a reviewable diff of the recipe.
- [Two new skills in a toolbox that "owns one refusal per job".] → Each still owns one:
  `neurodocker` refuses unversioned software, and `repronim-containers` refuses to present an
  unfetched image as available.

## Migration Plan

Additive. Removing the two skills, the gate target and the e2e steps restores the current
behaviour. Existing projects are unaffected until they install the subdataset.

## Open Questions

- **Where is the subdataset installed?** **Default: `containers/repronim/`.** Every compute
  environment in a harness dataset already lives under `containers/` (recipes, `.sif` files,
  `containers/<name>/` for neurodocker recipes). `.bidsignore` already excludes it, and nipoppy
  0.4.5 creates the same top-level directory. The alternative is upstream's documented
  `code/containers/`. It matches ReproNim's README verbatim, which helps users following
  ReproNim's own tutorials. But it puts a large image dataset under `code/`, which YODA reserves
  for scripts kept in git. `inputs/` is rejected: YODA reserves it for input data. The skill will
  accept a user-chosen path either way.
- Which neurodocker version `tests/envs/neurodocker` locks, and whether the skill should prefer the
  pip binary or the `repronim/neurodocker` image when both exist. **Default: the pip binary**, whose
  version the lock names. The image is the fallback, pinned by digest.
- Whether a catalog match should short-circuit the build silently. **Default: no.** The doer
  reports the match and asks, because the user may need a version ReproNim does not carry.
