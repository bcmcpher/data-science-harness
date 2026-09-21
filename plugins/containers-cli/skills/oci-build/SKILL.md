---
name: oci-build
description: >
  Auto-invoke when the user wants to build a Dockerfile into an OCI image with Docker or Podman, or
  to find out which container builder this machine can actually use. Trigger on "build the
  container", "docker build", "podman build", "build the image", "why can't I build containers here",
  "do I need sudo to build", or /oci-build. Do NOT trigger to write a Dockerfile (use dockerfile), to
  convert an image to .sif (use apptainer), or to run an analysis inside a container — that is the
  datalad doer's container-run.
argument-hint: '[check|build] [--file <Dockerfile>] [--tag <name>] [--context <dir>] [--runtime docker|podman]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: oci-build

Build a Dockerfile into an OCI image, and report which runtime built it and what that runtime
required of the machine.

**Read this before anything else: a successful build says the Dockerfile is valid, not that the
environment is right.** A Dockerfile with an unpinned `pip install` builds perfectly today and builds
something else next year. Whether what you are building is pinned is `dockerfile`'s question and was
answered before you were called; do not re-answer it by implication, and do not report a green build
as if it settled reproducibility.

Docker and Podman produce the **same layers** from the same Dockerfile, so the artifact does not
depend on which one ran. What differs is what each demands of the machine, and that belongs in the
report because it changes what the next person needs.

## Steps

1. **Check the runtime before anything else.**
   ```bash
   bash plugins/containers-cli/scripts/check-runtimes.sh oci
   ```
   The `found:` line names the runtime that was selected and why. **Podman is preferred when both are
   present** — rootless, daemonless, no group membership. Exit 1 means no builder is usable here;
   report it and stop rather than looking for another way to produce an image.

   Read the `caveat:` line if there is one. A rootful docker is *available* and still unusable to
   someone not in the docker group, and that is a different problem from docker being absent.

2. **Locate the Dockerfile and its build context.** The context is what gets sent to the builder, and
   it is the usual cause of a build that is slow or that cannot find a file it copies.
   ```bash
   ls -la Dockerfile containers/ 2>/dev/null
   ```
   A `COPY` that fails is almost always a context problem, not a Dockerfile error.

3. **Show the build command, then run it.** The two CLIs are compatible for this verb.
   ```bash
   podman build -f <Dockerfile> -t <name>:<tag> <context>
   docker build -f <Dockerfile> -t <name>:<tag> <context>
   ```
   Tag the image so later steps can name it. This tag is a **local handle**, not a pin — the pin is
   whatever `dockerfile` recorded, and this tag does not replace it.

4. **Read the failure, not just the exit code.** The three that account for most of them:
   - `COPY failed: no such file` — the path is outside the build context.
   - permission denied on the socket — rootful docker without group membership. The fix is podman or
     group membership, not `sudo` bolted onto the command.
   - a package resolution failure mid-`RUN` — the manifest pins something unavailable for this
     platform, often an over-pinned `conda env export` carrying build strings. Send it back to
     `dockerfile`; do not edit the pin to make the build pass.

5. **Confirm the image exists before reporting success.**
   ```bash
   podman image inspect <name>:<tag> >/dev/null && echo ok
   docker image inspect <name>:<tag> >/dev/null && echo ok
   ```

6. **Report.**
   ```
   op:        oci-build-<check|build>
   runtime:   podman <version> | docker <version>
   rootless:  yes | no (<what that requires of the machine>)
   file:      <Dockerfile path>
   context:   <build context dir>
   image:     <name>:<tag> | none
   result:    built | failed | unavailable
   failure:   <the failing step and its error, verbatim>
   notes:     <what was not checked: that the environment is pinned, that anything runs in it>
   ```

## Constraints

- **Never report an image that did not build.** A failed build leaves no image; report the failing
  step and its error rather than the intent.
- **Never silently fall back to the other runtime after one fails.** They produce the same layers
  only when both succeed. A fallback hides the reason the first failed — which is usually a machine
  fact the user needs, like not being in the docker group. Report, then ask.
- **Never add `sudo` to make a rootful docker build work.** That changes who owns the resulting
  files and is not the fix; podman or group membership is. Say so.
- **Never edit the Dockerfile's pins to make a build succeed.** A resolution failure is a finding
  about the manifest and belongs back with `dockerfile`. Loosening a pin to get a green build is
  exactly the drift this capability exists to prevent.
- **Never present a built image as cluster-ready.** A cluster runs `.sif`; converting is
  `apptainer`'s job and has not happened yet.
- Do not pull a base image the Dockerfile does not name, and do not substitute `:latest` for a digest
  that failed to resolve.
- Do not commit. The datalad doer owns `datalad save`.
