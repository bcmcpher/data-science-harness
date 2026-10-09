---
name: repronim-containers
description: >
  Auto-invoke before building a pipeline image that ReproNim may already publish (fMRIPrep, MRIQC,
  QSIPrep, a BIDS app), or when the user asks "is there a ready-built container for X", "use the
  ReproNim containers", "install ///repronim/containers", or /repronim-containers. Looks up the
  ReproNim/containers DataLad dataset for a tool and version, reports the match and its size, and
  returns the DataLad commands the planner runs to install, fetch and run it. Do NOT trigger to
  build an image (use oci-build), to generate a recipe (use neurodocker), or to run anything — this
  skill reads a catalog and returns commands; it never installs, fetches or runs.
argument-hint: '<tool> [<version>] [--path containers/repronim]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: repronim-containers

Find whether `///repronim/containers` already provides an image, and hand the planner the DataLad
commands that use it.

ReproNim/containers is a DataLad dataset of ready-built Singularity images for BIDS apps and
neuroimaging tools. Each registered image runs through the dataset's own wrapper, and each is
pinned by git-annex content. Building an image this dataset already provides duplicates work and
loses the wrapper.

**You read and report. The planner runs DataLad.** Installing a subdataset, fetching an image and
running it are DataLad writes. They belong to the main thread, so provenance has one owner.

## What the dataset holds

Measured 2026-10-09, at subdataset commit `76e98307`:

- 340 registered containers in `.datalad/config`, as `datalad.containers.<name>.image` and
  `.cmdexec` entries. Most register only the **latest** version, such as
  `bids-fmriprep` → `images/bids/bids-fmriprep--25.2.6.sif`.
- Older versions are still **files** in the tree, not registered:
  `images/<category>/<name>--<version>.<sif|sing|simg>` (for example
  `images/bids/bids-fmriprep--23.2.0.sing`).
- A metadata-only clone is about 17 MB. Image content is not fetched by a clone.
- Images are large: `bids-mriqc--24.0.2.sif` is 4.95 GB. The size is in the annex key
  (`MD5E-s<bytes>--…`), so it can be reported before any download.

## Steps

1. **Find the catalog.** Prefer an installed subdataset (default path `containers/repronim/`):
   ```bash
   CAT=containers/repronim
   [ -f "$CAT/.datalad/config" ] && git -C "$CAT" rev-parse --short HEAD
   ```
   Otherwise read a temporary metadata-only clone **outside the dataset**, and remove it when the
   lookup ends, whether it succeeds or fails:
   ```bash
   CATTMP=$(mktemp -d)
   trap 'chmod -R u+w "$CATTMP" 2>/dev/null; rm -rf "$CATTMP"' EXIT
   datalad clone ///repronim/containers "$CATTMP/c" >/dev/null && CAT="$CATTMP/c"
   ```
   Never `datalad get` during a lookup. If neither works (no network, no installed copy), report
   `catalog: not checked (<why>)` and stop. That never blocks a build.

2. **Look up the tool.**
   ```bash
   git config -f "$CAT/.datalad/config" --get-regexp '^datalad\.containers\..*\.image$' | grep -i <tool>
   git -C "$CAT" ls-tree -r --name-only HEAD images | grep -i -- "<tool>--<version>\."
   ```
   Classify the result:
   - **registered match**: the registered image is the requested version.
   - **file match**: the version is in the tree, but not registered. It needs a `containers-add`
     by the planner (step 4).
   - **no match**: neither. Say which versions the catalog has.

3. **Report the size and the call format before suggesting a fetch.**
   ```bash
   git -C "$CAT" annex lookupkey <image path>       # MD5E-s<bytes>--…
   git config -f "$CAT/.datalad/config" datalad.containers.<name>.cmdexec
   ```
   Nearly every entry runs `{img_dspath}/scripts/singularity_cmd run {img} {cmd}`. That wrapper:
   - runs with a cleaned environment and a bound temporary `HOME` and `/tmp`;
   - reads `SINGULARITY_CMD` (`run` by default, or `exec`);
   - uses a Docker shim when `REPRONIM_USE_DOCKER` is set, or on a non-Linux host;
   - wraps the run in `duct` when `REPRONIM_USE_DUCT` is set;
   - calls `singularity`. A host with only `apptainer` needs a `singularity` symlink, or
     `REPRONIM_USE_DOCKER`.

4. **Return the commands for the planner.** From the superdataset root:
   ```bash
   datalad clone -d . ///repronim/containers containers/repronim      # once; ~17 MB, no images
   datalad get containers/repronim/<image path>                         # this one image only
   datalad containers-run -n containers/repronim/<name> \
     --input <inputs> --output <outputs> -- <args>
   ```
   `datalad containers-run` fetches a missing image by itself, so the size from step 3 must reach
   the caller before the planner runs either command, not only before `datalad get`.
   From the superdataset, a subdataset's container is named with its path prefix
   (`containers/repronim/bids-mriqc`), and `datalad containers-list -r` lists them.
   For a **file match**, the planner registers that version in the superdataset first:
   ```bash
   datalad containers-add <name>-<version> \
     -i containers/repronim/<image path> \
     --call-fmt 'containers/repronim/scripts/singularity_cmd run {img} {cmd}'
   ```

5. **Report.**
   ```
   op:       repronim-containers-lookup
   request:  <tool> <version>
   catalog:  match <name> <version> | file match <path> | no match (has: <versions>) | not checked (<why>)
   source:   installed containers/repronim | temporary clone (removed)
   image:    <path> (<size>, fetched: yes|no)
   callfmt:  <cmdexec>
   binding:  containers/repronim@<subdataset commit>
   commands: <the step-4 commands, for the planner>
   notes:    the pin is the subdataset commit plus the annex key; updating the subdataset is a
             version change the planner records
   ```

## Constraints

- **Never report an image as available to run when its content is not fetched.** `fetched: no`
  until `datalad get` has run.
- **Never fetch annex content.** A lookup reads git metadata only. The planner runs `datalad get`
  (or `containers-run`, which fetches too) for the one image chosen, after the caller has seen its
  size.
- **Never leave the temporary clone behind.** Remove it on every exit path.
- **Never install the subdataset, register, or run.** Return the commands; the planner runs them.
- **Never treat a match as a decision.** Report it and let the caller choose; they may need a version
  ReproNim does not carry, or a derived image.
- A ReproNim image is **vendored**. Its pin is the subdataset commit the superdataset records plus
  the image's annex key. It needs no OCI digest. Moving the subdataset to a newer commit is a version
  change, not a no-op.
