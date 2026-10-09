---
name: neurodocker
description: >
  Auto-invoke when the user asks for a container by naming neuroimaging software rather than giving
  a manifest — "a container with FSL 6.0.7 and ANTs", "a Dockerfile with MRtrix3 3.0.4", "a
  Singularity recipe for AFNI" — or names Neurodocker or /neurodocker. Generates a pinned,
  regenerable Docker or Singularity recipe with Neurodocker. Do NOT trigger to translate a manifest
  the project already owns (use dockerfile), to build the recipe (use oci-build or apptainer), to
  find a ready-built image (use repronim-containers), or to decide which software an analysis needs —
  the user or planner names the software and every version.
argument-hint: '[docker|singularity] --name <env> --base <image>@sha256:<digest> --pkg-manager <apt|yum> --<software> version=<v> ...'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Write, Bash, Grep, Glob
---

# Skill: neurodocker

Generate a Docker or Singularity recipe for named neuroimaging software with Neurodocker, pinned so
it can be regenerated, and refuse when it would not be.

**You generate, you do not choose.** The user or planner names the software and the version of each
item. Neurodocker knows *how* to install FSL or MRtrix3. It does not know *which* version the
analysis needs, and neither do you. A recipe that installs "whatever is current" builds today and
installs something else next year.

A Neurodocker recipe is an **authored** environment. Its manifest is the generating command, so
three things make it regenerable:

| Pin | Why |
|---|---|
| `version=` on every software flag | Neurodocker templates otherwise fail or fall back to a default the project never chose |
| the base image by `@sha256:` digest | a tag such as `debian:bookworm` is mutable |
| the Neurodocker version | the same command renders a different recipe under another release |

## Steps

1. **Check what is available.**
   ```bash
   bash plugins/containers-cli/scripts/check-runtimes.sh neurodocker
   bash plugins/containers-cli/scripts/check-runtimes.sh digest
   ```
   Exit 1 from `neurodocker` means no recipe can be generated here: report `unavailable` with the
   `enable:` line and stop. Exit 1 from `digest` means a tag cannot be resolved here; accept a
   digest the user supplies, or stop. Neither check pulls an image.

2. **Check every pin before generating.** Refuse, and name what is missing, when:
   - a software flag has no `version=` (`--fsl` alone, `--ants method=binaries`);
   - the base image is a tag with no digest (`debian:bookworm`, `ubuntu:22.04`);
   - no environment name is given for `containers/<name>/`.

   Resolve a base tag to a digest with the command `check-runtimes.sh digest` named, then confirm
   the digest with the user. Report the tag alongside the digest so a human can read it.

3. **Generate.** Use the binary when it is on `PATH`. Otherwise use the local
   `repronim/neurodocker` image that the gate found, by digest. Generation renders templates and
   runs offline.
   ```bash
   mkdir -p containers/<name>
   neurodocker generate docker \
     --pkg-manager apt \
     --base-image debian@sha256:<digest> \
     --mrtrix3 version=3.0.4 method=binaries \
     > containers/<name>/Dockerfile.tmp </dev/null \
     && mv containers/<name>/Dockerfile.tmp containers/<name>/Dockerfile \
     || rm -f containers/<name>/Dockerfile.tmp
   ```
   Use `generate singularity` and `containers/<name>/Singularity` for an Apptainer definition file.
   Generate into a temporary file and move it into place only on exit 0, so a failed run leaves no
   partial recipe.

   Some templates ask the user to accept a licence on stdin; FSL does ("FSL is non-free … Proceed?").
   Your shell cannot answer it: with no input, Neurodocker aborts. **Before generating** a recipe
   that includes FSL, ask the user whether they accept FSL's licence. Pass `--yes` only after they
   say yes, and record that they did in `notes:`. If any other template aborts on a prompt, report
   the prompt text and ask the same way.

4. **Record the generator next to the recipe.**
   - `containers/<name>/neurodocker.sh`: the exact command, one flag per line, with the redirect.
   - A first line in the recipe: `# neurodocker <version>: regenerate with containers/<name>/neurodocker.sh`.
     Neurodocker's own header names no version, so this line is the only record of it.

   `neurodocker --version` prints `neurodocker version <v>`.

5. **Hand off.** A `Dockerfile` goes to `oci-build`, then `apptainer` if a `.sif` is wanted. A
   `Singularity` file goes to `apptainer`. A recipe that has not been built is `written`, not
   `working`.

6. **Report.**
   ```
   op:          neurodocker-<docker|singularity>
   environment: <name> (serves: <pipeline or analysis>)
   kind:        authored (manifest: containers/<name>/neurodocker.sh)
   generator:   neurodocker <version> (binary | repronim/neurodocker@sha256:…)
   base:        <image>@sha256:… (tag: <tag>)
   software:    <flag version=…>, …
   out:         containers/<name>/<Dockerfile|Singularity> | none
   result:      written | refused | unavailable
   refused:     <the pin that was missing>
   notes:       apt/yum layers inside the recipe are not version-locked; that is intrinsic to
                Neurodocker's templates. Not built: that is oci-build's or apptainer's question.
   ```

## Constraints

- **Never generate with an unversioned software flag**, even when Neurodocker would accept it.
- **Never name the base image by tag alone.** Resolve it, or take a digest from the user.
- **Never edit the generated recipe by hand.** Change `neurodocker.sh` and regenerate, so the
  command and the recipe cannot disagree.
- **Never write install steps yourself** for software Neurodocker does not template. Report that it
  has no template, and name `dockerfile` (a derived image from a pinned manifest) as the way forward.
- **Never pull `repronim/neurodocker`.** Use it only when the gate found it locally.
- Do not accept a licence for the user: ask first. Do not build, and do not commit. The planner owns
  `datalad save`.
