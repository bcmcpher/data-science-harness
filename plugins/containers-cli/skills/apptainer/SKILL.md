---
name: apptainer
description: >
  Auto-invoke when the user wants to convert an OCI or Docker image into a .sif for Apptainer or
  Singularity, build a .sif from a definition file, or move a container to a compute cluster.
  Trigger on "convert to sif", "build a sif", "apptainer", "singularity", "run this on the cluster",
  "get this container onto the HPC", "docker-daemon client version too old", or /apptainer. Do NOT
  trigger to write a Dockerfile (use dockerfile), to build an OCI image (use oci-build), or to
  register or run a container in a dataset — `datalad containers-add` and `containers-run` belong to
  the datalad doer.
argument-hint: '[check|convert|build|verify] [--image <ref>] [--def <file>] [--out <path>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: apptainer

Turn a built image into a `.sif` that a compute cluster can run, and verify it before saying so.

**Read this before anything else: a `.sif` that exists here has not been shown to run anywhere else.**
Building and verifying locally establishes that the file is a valid image. It says nothing about the
cluster's filesystem, its bind mounts, its GPU stack, or whether the image was ever transferred. Keep
*verified here* and *transferred* separate in every report, because a container "ready for the
cluster" that never reached one is the failure this skill is most likely to produce.

The `.sif` is the artifact the provenance chain registers: `datalad containers-run` runs a `.sif`.
An OCI image alone does not reach a cluster.

## The Docker API trap

**Never build from `docker-daemon://`.** Apptainer 1.1.x speaks a Docker API older than any current
daemon, and the direct path fails with:

```
FATAL: ... Error response from daemon: client version 1.22 is too old.
```

This reads like a broken image or a broken install and is neither. The working path is always an
**archive**:

```bash
docker save <image>:<tag> -o /tmp/<name>.tar     # or: podman save ...
apptainer build <out>.sif docker-archive:///tmp/<name>.tar
```

This costs one intermediate file and works offline. It is verified in `tests/e2e-smoke.sh`, and it is
the single most easily-lost piece of knowledge in this capability — if you rewrite this skill, carry
it forward.

## Steps

1. **Check the runtime before anything else.**
   ```bash
   bash plugins/containers-cli/scripts/check-runtimes.sh apptainer
   ```
   Exit 1 means no `.sif` can be produced here. If an OCI image was already built, report **that**
   as what exists and state plainly that the conversion did not run — do not present the OCI image
   as the artifact that was asked for.

2. **Establish the source.** Three, and they take different paths:

   | Source | Command |
   |---|---|
   | Local OCI image (docker or podman) | `docker save` / `podman save` → `docker-archive://` |
   | Remote registry reference | `apptainer build <out>.sif docker://<ref>` |
   | Apptainer definition file | `apptainer build <out>.sif <file>.def` |

   For a remote reference, **use the digest if one was pinned** — `docker://image@sha256:…`. Pulling
   by tag here would discard the pin `dockerfile` established.

3. **Show the command, then build.** Write into the dataset's `containers/` by default, so the image
   is annexed on the next `datalad save` and its content hash travels with the dataset.

4. **Verify the `.sif` before reporting success.**
   ```bash
   apptainer inspect <out>.sif
   apptainer exec <out>.sif true      # confirms it starts
   ```
   `inspect` confirms a valid SIF; `exec … true` confirms it actually runs. A file of the right size
   that will not start is the failure a size check misses.

5. **Transfer only when asked, and report it separately.** Moving a `.sif` to a cluster is a copy to
   a destination the user names. Nothing here verifies the cluster will run it — its kernel, its
   bind mounts and its GPU stack are not visible from this side.

6. **Hand back the registration command; do not run it.**
   ```
   datalad containers-add <name> --url <sif> --call-fmt "apptainer exec {img} {cmd}"
   ```
   Registration and running belong to the datalad doer, so provenance keeps one owner. A project
   with several environments registers several names — one per pipeline — and
   `containers-run --container-name <name>` selects between them.

7. **Report.**
   ```
   op:            apptainer-<check|convert|build|verify>
   source:        <image ref, archive path, or .def>
   path:          docker-archive | docker:// | def
   pin:           <image>@sha256:… | none (<why>)
   image:         <path to .sif> | none
   verified:      inspect ok, exec ok | <what failed>
   transferred:   <destination> | not run
   result:        built | failed | unavailable
   containers_add: <the command for the datalad doer>
   notes:         <what was not checked: that the cluster runs it>
   ```

## Constraints

- **Never use `docker-daemon://`.** Always `docker save` / `podman save` → `docker-archive://`. The
  failure it avoids reads as a broken image and is an API version mismatch.
- **Never report a `.sif` as built without running `apptainer inspect` on it**, and prefer
  `exec … true` as well. A partially written SIF has a plausible size.
- **Never claim a container runs on a cluster you did not reach.** Separate verified-here from
  transferred in the report, every time.
- **Never discard a pin during conversion.** If a digest was resolved, pull by digest; do not fall
  back to the tag because it is shorter.
- **Never register or run the image.** `datalad containers-add` and `containers-run` are the datalad
  doer's. Hand back the command.
- **Never assume one environment per project.** A study with several pipelines has several `.sif`
  files and several registered names; say which one you built.
- Do not choose what goes in the image. If the recipe is wrong, that is `dockerfile`'s question.
- Do not commit. The datalad doer owns `datalad save`.
