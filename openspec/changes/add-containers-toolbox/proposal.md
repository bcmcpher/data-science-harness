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
- **One new refusal, which is the point of the change**: a Dockerfile is emitted only from a
  committed, version-pinned manifest. The toolbox never picks a package and never resolves a
  version.

## Capabilities

### Modified Capabilities
- `containers`: Purpose reframed around the Dockerfile → OCI → `.sif` path; the build-path
  requirement generalized from "Apptainer builds" to "the path the artifact needs"; new requirements
  for manifest-derived authoring, runtime selection, and cluster export.

## Impact

- New: `plugins/containers-cli/` (3 skills + `scripts/check-runtimes.sh`), marketplace entry
- Modified: `openspec/specs/containers/spec.md`, `plugins/containers/agents/containers-doer.md`,
  `plugins/project/skills/new-project/SKILL.md` (step 4 delegates rather than hand-writes),
  `.claude-plugin/marketplace.json`, `tests/e2e-smoke.sh`
- **This change is spec-and-tasks only.** Nothing under `plugins/` is written here; the task list
  records what the implementing pass must build. That pass is where the skills get real tests.
