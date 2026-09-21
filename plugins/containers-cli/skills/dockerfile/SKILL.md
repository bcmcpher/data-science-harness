---
name: dockerfile
description: >
  Auto-invoke when the user wants to turn a project's declared analysis environment into a
  Dockerfile, pin a pipeline container such as fMRIPrep or QSIPrep, or extend a standard container
  with the project's own scripts and tools. Trigger on "write a Dockerfile", "containerize this
  environment", "make a container for this analysis", "pin fMRIPrep", "add my scripts to the fmriprep
  container", "which version of the container am I running", or /dockerfile. Do NOT trigger to build
  an image (use oci-build), to convert one to .sif (use apptainer), or to decide which packages an
  analysis needs — this translates a declared environment, it never chooses one.
argument-hint: '[check|authored|vendored|derived] [--manifest <file>] [--base <ref>] [--out <path>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: dockerfile

Translate a project's *declared* compute environment into a Dockerfile, and refuse when what it
declares would not rebuild.

**Read this before anything else: you translate, you do not choose.** Every package and every version
in what you emit must come from something the project already committed. An image built from versions
you picked is indistinguishable, on inspection, from one built from versions the project declared.
Both build. Both run. Both produce numbers. Only one of them rebuilds a year later, and the
difference is invisible until the moment it matters. That is the entire reason this skill refuses
more often than it writes.

A project has **several** environments, not one — an analysis environment beside vendored fMRIPrep
and QSIPrep, and sometimes a derived image that adds the project's scripts to a standard base. Each
is named, each records the pipeline it serves, and each is pinned by the rule for its kind.

## The three kinds, and what pins each

| Kind | What it is | What pins it |
|---|---|---|
| `authored` | built from a manifest the project owns | the pinned manifest |
| `vendored` | a published pipeline image | the image **digest** |
| `derived` | a vendored base plus the project's own additions | the base digest **and** a pinned manifest |

**A tag is not a pin.** `nipreps/fmriprep:23.2.0` is mutable — the same tag can be re-pushed, so two
runs a year apart can name it and execute different code. Resolving it to `@sha256:…` costs one
command and is the whole difference.

## Steps

1. **Check what is available before anything else.**
   ```bash
   bash plugins/containers-cli/scripts/check-runtimes.sh digest
   ```
   Writing a Dockerfile needs no runtime. Resolving a tag to a digest does, and exit 1 means a
   vendored or derived environment **cannot be pinned here** — say so and stop, rather than writing a
   tag and calling it pinned.

2. **Establish which environment is being asked about.** If the project holds more than one, ask
   which. Do not default to the only one you happen to find; a study with fMRIPrep, QSIPrep and a
   local analysis environment has three, and picking silently is how the wrong one gets rebuilt.
   Record the name and the pipeline it serves.

3. **Classify the request** as `authored`, `vendored` or `derived` using the table above, and say
   which you chose. The refusal that applies depends on it.

4. **For `authored`: read the manifest and check that it is pinned.**
   ```bash
   [ -f environment.yml ] && sed -n '1,60p' environment.yml
   [ -f uv.lock ] && echo "uv.lock present"; [ -f pyproject.toml ] && sed -n '1,40p' pyproject.toml
   [ -f renv.lock ] && head -20 renv.lock
   ```
   Three outcomes, and they are not the same problem:
   - **Pinned** — every dependency carries a resolved version. Proceed.
   - **Unpinned** — bare names, or ranges like `numpy>=1.24`. Refuse. Name the manifest and the
     command that would pin it: `conda env export --no-builds > environment.yml`, `uv lock`, or
     `renv::snapshot()`.
   - **Over-pinned** — `conda env export` *without* `--no-builds` writes build strings like
     `numpy=1.26.4=py311h64a7726_0`. This looks maximally pinned and is **less** portable: those
     build strings do not resolve on another platform. Report it as over-pinned, not as pinned, and
     name `--no-builds`.

   Emit a Dockerfile that **copies the manifest in and installs from it**, never a package list
   transcribed into `RUN` lines. A transcription is a second copy of the environment that drifts
   from the first, and nothing compares them.

5. **For `vendored`: resolve the tag to a digest.**
   ```bash
   skopeo inspect docker://nipreps/fmriprep:23.2.0 | grep -i digest   # does not pull
   podman manifest inspect nipreps/fmriprep:23.2.0 | head -20
   docker buildx imagetools inspect nipreps/fmriprep:23.2.0
   ```
   Record `<image>@sha256:…` as the pin, and report the tag alongside it so a human can still read
   what it is. If no registry can be reached, report that the pin **could not be resolved** and do
   not record the tag as if it were a pin. Accept a digest the user supplies directly.

6. **For `derived`: pin both ends.** The base by digest, the additions from a pinned manifest.
   ```dockerfile
   FROM nipreps/fmriprep@sha256:<digest>
   COPY environment-extra.yml /tmp/
   RUN conda env update -n base -f /tmp/environment-extra.yml
   COPY code/ /opt/project-code/
   ```
   Refuse bare package names for the additions. An unpinned `RUN pip install nilearn` on a pinned
   base is the quiet version of this failure: the base is byte-identical a year later and the layer
   on top is not, so the image drifts while looking pinned.

7. **Report.**
   ```
   op:          dockerfile-<check|authored|vendored|derived>
   environment: <name> (serves: <pipeline or analysis>)
   kind:        authored | vendored | derived
   source:      <manifest path, and/or image reference>
   pin:         <manifest + how it is pinned> | <image>@sha256:… | unresolved (<why>)
   out:         <Dockerfile path written> | none
   result:      written | refused | unavailable
   refused:     <which pin was missing, and the command that would supply it>
   notes:       <what was not checked: that it builds — that is oci-build's question>
   ```

## Constraints

- **Never choose a package or resolve a version.** Everything you emit comes from something already
  committed. This is the boundary the capability exists to hold.
- **Never accept a mutable tag as a pin.** Resolve it, or report it unresolved. A tag recorded as a
  pin is worse than an unpinned manifest, because it looks specific.
- **Never emit an unpinned install step into a derived image**, however small. One `pip install` with
  no version undoes the base digest above it.
- **Never report an over-pinned `conda env export` as pinned.** Build strings are platform-specific;
  the image will fail to rebuild elsewhere, which is the opposite of what the pin was for.
- **Never transcribe a manifest into `RUN` lines.** Copy the file and install from it, so there is
  one declaration of the environment rather than two that can disagree.
- **Never assume a project has one environment.** Ask which, and record which pipeline it serves.
- Do not build the image. `oci-build` owns that, and a Dockerfile that has not been built is
  `written`, not `working`.
- Do not commit. The datalad doer owns `datalad save`.
