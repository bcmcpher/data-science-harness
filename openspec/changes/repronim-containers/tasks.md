## 1. Toolbox skills

- [ ] 1.1 `plugins/containers-cli/skills/neurodocker/SKILL.md`: gate via `check-runtimes.sh neurodocker` and `digest`; generate docker/singularity into `containers/<name>/`; write `neurodocker.sh` and a version header; refuse software without `version=` and a base image without a digest; hand off to `oci-build` or `apptainer`; report block in the toolbox's format; `user-invocable: true`, `argument-hint`, scoped `allowed-tools`
- [ ] 1.2 `plugins/containers-cli/skills/repronim-containers/SKILL.md`: catalog lookup from `.datalad/config` (installed subdataset, else temporary metadata-only clone outside the dataset); report matches; return the install / `datalad get` / `datalad containers-run` commands for the planner; document `singularity_cmd`, `SINGULARITY_CMD`, `REPRONIM_USE_DOCKER`, `REPRONIM_USE_DUCT`; never report an unfetched image as available; `binding: containers/repronim@<commit>`
- [ ] 1.3 `check-runtimes.sh`: add a `neurodocker` target (binary on `PATH`, else a local `repronim/neurodocker` image via docker/podman); update the usage line and the unknown-tool message
- [ ] 1.4 `plugins/containers-cli/.claude-plugin/plugin.json`: add both skills to `skills`, add `neurodocker` and `repronim` keywords; update the description

## 2. Doer

- [ ] 2.1 `plugins/containers/agents/containers-doer.md`: add both skills to the toolbox table; a step before building a vendored/derived image that runs the catalog lookup and reports `catalog: match | no match | not checked (<why>)`; route "a container with <software>" requests with no manifest to `neurodocker`; add `catalog:` to the report block; state that a ReproNim image's pin is the subdataset commit plus annex key
- [ ] 2.2 Update the doer's `description:` to mention neurodocker recipes and ReproNim images

## 3. Lint, counts, docs

- [ ] 3.1 Add `neurodocker` to `PERIPHERAL_BINARIES` in `tests/lint-plugins.py`; confirm no planner body quotes it
- [ ] 3.2 `README.md`: the `containers-cli` row to "5 skills" (lint-enforced against disk); line 5 status totals (59 → 61 skills; not lint-enforced, update by hand); the toolbox prose "`containers` has 3, one per job"
- [ ] 3.3 `.claude-plugin/marketplace.json`: `containers-cli` description names the two new skills
- [ ] 3.4 README Contributing note: a new toolbox binary is added to `PERIPHERAL_BINARIES` (check it already says so after `planner-intent-delegation`; add only if missing)

## 4. Test environment and e2e

- [ ] 4.1 `tests/envs/neurodocker/{pyproject.toml,uv.lock}` per `live-tool-test-envs` D1; `bin/test-envs sync neurodocker` works
- [ ] 4.2 e2e containers-cli section (gated on `tool_env_ready neurodocker`): `neurodocker generate docker --pkg-manager apt --base-image <image>@sha256:<digest> --<one small package> version=<v> method=binaries`; assert `FROM` carries the digest and the output names the version; where `unshare -rn` is available, run it with no network to confirm generation is offline, and record the result in design.md
- [ ] 4.3 Add `neurodocker` to the runtime-gate loop (`for RT in docker podman apptainer oci digest`) and to the skill-presence loop (`dockerfile oci-build apptainer`), with both new skills
- [ ] 4.4 ReproNim step (gated on `DSH_NET=1` and datalad-container): in a throwaway superdataset under `$WORKDIR`, `datalad clone -d . ///repronim/containers containers/repronim`; `datalad containers-list` shows ReproNim entries; record the exact name form (bare or path-prefixed) in design.md and in the skill; assert `cmdexec` contains `scripts/singularity_cmd`
- [ ] 4.5 Optional image run (gated on `DSH_NET=1`, `DSH_NET_IMAGES=1`, apptainer): `datalad get` the smallest suitable image and `datalad containers-run -n <name> -- --version`; assert the run commit records the image; record whether `singularity_cmd` needed the `singularity` symlink
- [ ] 4.6 Without `DSH_NET` or the neurodocker env, the section prints one `SKIP:` per gated step and the e2e passes

## 5. Checks

- [ ] 5.1 `python3 tests/lint-plugins.py --strict` and the selftest pass
- [ ] 5.2 `bash tests/e2e-smoke.sh` passes with and without the gates
- [ ] 5.3 `openspec validate repronim-containers --strict` passes
