## Why

The containers capability builds every image from scratch. It turns a pinned manifest into a
Dockerfile, builds it with Podman or Docker, and converts the result to a `.sif`. Two ReproNim
tools cover ground it does not, and a ReproNim user would reach for both first.

- **Neurodocker** (`pip install neurodocker`) generates Dockerfiles and Singularity recipes for
  neuroimaging software, such as `--mrtrix3 version=3.0.4`. It encodes install knowledge that the
  `dockerfile` skill deliberately does not have, because that skill only translates a manifest the
  project already owns. A request like "a container with FSL 6.0.7 and ANTs" has no manifest to
  translate today. The skill can only refuse it.
- **ReproNim/containers** (`///repronim/containers`) is a DataLad dataset of ready-built Singularity
  images, over 600 of them, each registered for `datalad containers-run`. Each image is pinned by
  git-annex content and by the commit of the dataset that holds it. Its README installs it as a
  subdataset (`datalad install -d . -s ///repronim/containers code/containers`). Each image is
  registered with `cmdexec = {img_dspath}/scripts/singularity_cmd run {img} {cmd}`. That wrapper
  isolates the host environment and binds a clean `HOME` and `/tmp`. It falls back to Docker when
  `REPRONIM_USE_DOCKER` is set, and wraps runs in `duct` when `REPRONIM_USE_DUCT` is set. Building
  an fMRIPrep or MRIQC image that this dataset already provides duplicates work and loses that
  wrapper.

Neither tool appears anywhere in the repository.

## What Changes

- **New `containers-cli` skill `neurodocker`.**
  - It generates a Docker or Singularity recipe into `containers/<name>/` from a neurodocker
    command in which every package carries `version=`, with the base image named by digest.
  - Next to the recipe it writes the exact generating command and the neurodocker version, so the
    recipe can be regenerated.
  - It hands the recipe to `oci-build` (Dockerfile) or `apptainer` (definition file).
  - It refuses a package with no `version=`, and a base image named by tag alone.
- **New `containers-cli` skill `repronim-containers`.**
  - It finds whether `///repronim/containers` already provides an image for a requested tool and
    version, and reads how that image is registered.
  - It returns the DataLad commands the planner runs to install the subdataset, fetch the one image
    it needs, and run it with `datalad containers-run`.
  - It explains the `singularity_cmd` call format and its `REPRONIM_USE_DOCKER` fallback.
- **The containers doer changes in two ways:**
  - Before building a new vendored or derived image, it checks whether ReproNim/containers already
    provides one, and reports what it found.
  - A request for software without a manifest ("a container with X and Y") routes to `neurodocker`
    instead of being refused.
- **`neurodocker` is added to `check-runtimes.sh`.** It reports available when the `neurodocker`
  binary is on `PATH`, or when a local Docker/Podman holds a `repronim/neurodocker` image.
- **`neurodocker` is added to `PERIPHERAL_BINARIES`** in `tests/lint-plugins.py`, so planners state
  intent rather than neurodocker command lines.
- **Counts.** `containers-cli` goes from 3 to 5 skills. The README row and the plugin manifest must
  match: the lint checks per-plugin README rows against disk. The status line total (59 → 61
  skills), the marketplace description and the README prose ("`containers` has 3, one per job")
  are updated by hand.
- **e2e.**
  - `tool_env neurodocker` runs `neurodocker generate docker` offline and asserts the pinned
    version and digest in the output.
  - With `DSH_NET=1`, the e2e installs `///repronim/containers` as a subdataset and asserts that
    `containers-list` shows its images with the `singularity_cmd` call format.
  - `tests/envs/neurodocker/` is added the way `live-tool-test-envs` defines.

**Not in this change:** running a ReproNim image by default (images are hundreds of MB), minifying
images with `neurodocker minify`, and `con-duct` integration beyond noting `REPRONIM_USE_DUCT`.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `containers`: Neurodocker as a recipe source with its own pinning rule; ReproNim/containers as a
  pre-built source checked before a build; a ReproNim image pinned by subdataset commit and annex
  key counts as a pin; toolbox grows to five skills.

## Impact

- New: `plugins/containers-cli/skills/{neurodocker,repronim-containers}/SKILL.md`,
  `tests/envs/neurodocker/{pyproject.toml,uv.lock}`
- `plugins/containers-cli/.claude-plugin/plugin.json` (skills list, keywords),
  `plugins/containers-cli/scripts/check-runtimes.sh` (`neurodocker` target)
- `plugins/containers/agents/containers-doer.md` (toolbox table, how-you-operate steps, report
  fields)
- `tests/lint-plugins.py` (`PERIPHERAL_BINARIES`), `tests/e2e-smoke.sh` (containers-cli section)
- `README.md` (line 5 totals, the `containers-cli` row, the toolbox prose),
  `.claude-plugin/marketplace.json` (`containers-cli` description)
- **Depends on** `live-tool-test-envs` for `tests/envs/`, `bin/test-envs` and `tool_env`.
