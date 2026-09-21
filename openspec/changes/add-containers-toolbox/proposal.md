## Why

`containers` is the only doer with no toolbox, and it is the last hole in the capability plane. But
the gap is not only that a toolbox is missing — the capability is pointed the wrong way.

Its spec Purpose reads "the capability-plane wrapper over **Apptainer/Singularity image builds**",
and Docker appears in exactly one place: as a source to convert *from*, via a `docker save` →
`docker-archive://` workaround. That is backwards from how the environment is actually authored.
People write Dockerfiles. Clusters run Apptainer. The path that matters runs
**Dockerfile → OCI image → `.sif`**, and today the harness owns only the last arrow.

The concrete consequence is a claim nothing backs. `project/new-project` step 4 scaffolds "a minimal
`Dockerfile`/`Apptainer.def`" — written by hand, by a planner, with no toolbox beneath it and no
check that what it wrote corresponds to the project's declared environment. Meanwhile
`plugins/containers/agents/containers-doer.md` refuses the middle of the path outright: *"Do not
choose the scientific environment (which packages)."* So the project declares an environment in
`environment.yml`, and the container recipe beside it is written from recall. Those two files drift,
and nothing in the repository compares them.

A second assumption is wrong in the same way, and it shows up the moment the capability meets real
work: **a project has more than one compute environment.** A study runs fMRIPrep and QSIPrep and a
local analysis environment, and those are three different images with three different origins. Worse,
the interesting case is the hybrid — a standard container with the project's own scripts and a
couple of extra tools layered on top. The spec as written talks about "the project's pinned
environment", singular, and about translating a manifest, which is only one of the three ways an
environment comes to exist.

That matters most for what counts as a pin. A locally authored environment is pinned by its manifest.
A published pipeline container has no manifest in the project at all — its pin is the image digest.
And `fmriprep:23.2.0` is **not** a pin: a tag is mutable and can be re-pushed, so two runs a year
apart can name the same tag and execute different code. That failure is invisible in exactly the way
an unpinned manifest is invisible, which is why it belongs in the same requirement.

## What Changes

- **The capability is reframed**: authoring and building happen in Docker (or Podman); Apptainer is
  the export target for clusters. Provenance is unchanged — `datalad containers-add` and
  `containers-run` stay with the datalad doer.
- **A `containers-cli` toolbox, split by job rather than by binary**: `dockerfile` (translate a
  pinned manifest into a Dockerfile), `oci-build` (build it with docker or podman), `apptainer`
  (convert an OCI image to `.sif` and move it to a cluster).
- **Podman is a runtime variant inside `oci-build`**, not a skill of its own. It is CLI-compatible
  with docker and produces the same layers; what differs is rootless operation and the admin
  requirements that follow, which the gate reports.
- **One new refusal, which is the point of the change**: an environment is only accepted when it
  carries a pin appropriate to its kind — a version-pinned manifest for one the project authors, an
  image **digest** for one it vendors, and both for one it derives. The toolbox never picks a
  package, never resolves a version, and never accepts a mutable tag as a pin.
- **Environments are plural and named.** A project may hold several — an authored analysis
  environment alongside vendored fMRIPrep and QSIPrep, and derived images that add project scripts to
  a standard base. Each is named, each names the pipeline it serves. No new registry is introduced:
  `datalad containers-add <name>` already keys containers by name in `.datalad/config`, and
  `containers-run --container-name <name>` already selects between them.

## Capabilities

### Modified Capabilities
- `containers`: Purpose reframed around the Dockerfile → OCI → `.sif` path; the build-path
  requirement generalized from "Apptainer builds" to "the path the artifact needs"; new requirements
  for pinned authoring, the three environment kinds, plural named environments, runtime selection,
  and cluster export.

## Impact

- New: `plugins/containers-cli/` (3 skills + `scripts/check-runtimes.sh`), marketplace entry
- Modified: `openspec/specs/containers/spec.md`, `plugins/containers/agents/containers-doer.md`,
  `plugins/project/skills/new-project/SKILL.md` (step 4 delegates rather than hand-writes),
  `.claude-plugin/marketplace.json`, `tests/e2e-smoke.sh`
- **This change is spec-and-tasks only.** Nothing under `plugins/` is written here; the task list
  records what the implementing pass must build. That pass is where the skills get real tests.
