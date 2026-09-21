## Status

Complete. Proposed 2026-09-21 as spec-and-tasks only; implemented the same day.

**The headline result is that this is the first capability whose path is actually exercised, not
only gated.** Docker 29.8.1 (rootful), Podman 3.4.4 (rootless) and Apptainer 1.1.9 are all present
on the development machine, so the full path was run end to end rather than described — including
the `docker-daemon://` failure this capability exists to route around, reproduced verbatim.

## 0. Minimal working core

The `dockerfile` skill (1.1), the gate (2.1), and the doer rewired (3.1) — the path from a pinned
manifest to a Dockerfile, which is the part nothing owns today. `oci-build` and `apptainer` can
follow, because the existing doer already builds and converts; what it cannot do is author.

Sequence the authoring skill first for the same reason the compendium change sequenced the article
path first: it is the arrow that is missing, not the one that is weak.

## 1. The containers-cli toolbox

- [x] 1.1 `plugins/containers-cli/skills/dockerfile/SKILL.md` — translate a pinned manifest into a
      Dockerfile. Reads `environment.yml`, `pyproject.toml` + `uv.lock`, or `renv.lock`. Emits a
      Dockerfile that installs **from the manifest file**, copied into the image, rather than from a
      package list transcribed into `RUN` lines — a transcribed list is a second copy of the
      environment that drifts from the first.

      Its refusal is the change's whole point: no pin, no Dockerfile. Distinguish the two ways a
      manifest fails, because they have opposite fixes:
      - **Unpinned** — dependencies with no resolved version. Name the manifest and the command that
        would pin it (`conda env export --no-builds`, `uv lock`, `renv::snapshot()`).
      - **Over-pinned** — `conda env export` without `--no-builds` writes build strings that do not
        resolve on another platform. This looks maximally pinned and is less portable, so it must
        not be silently accepted as "pinned".

- [x] 1.1a Extend `dockerfile` to the other two environment kinds. The skill is not only a manifest
      translator; it must handle how an environment actually came to exist:
      - **vendored** — a published pipeline image (fMRIPrep, QSIPrep, MRIQC). There is no manifest in
        the project. Resolve the tag to a digest and record the digest.
      - **derived** — emit `FROM <base>@sha256:…` plus the project's additions, installed from a
        pinned manifest. Refuse bare package names: an unpinned `RUN pip install nilearn` on a pinned
        base is the quiet version of this failure, because the base is identical a year later and the
        layer on top is not.

      **A tag is not a pin.** `nipreps/fmriprep:23.2.0` is mutable and can be re-pushed. Resolving it
      costs one command (`docker buildx imagetools inspect`, `podman manifest inspect`, or a registry
      HEAD) and is the entire difference between a reproducible pipeline run and one that looks
      reproducible.

      Handle the offline case explicitly: resolution needs a registry, and on a cluster login node it
      will fail. Report that the pin could not be resolved rather than silently accepting the tag,
      and still accept a digest the user supplies directly. This is the most likely place for the
      rule to get worked around.

- [x] 1.2 `plugins/containers-cli/skills/oci-build/SKILL.md` — build a Dockerfile with `docker build`
      or `podman build`. Detect which runtimes are present; prefer podman when both are, and say why
      (rootless by default, no daemon, no docker group). Report which runtime built the image and
      whether the build was rootless.

      Refusals: never report an image that did not build; never fall back to a different runtime
      silently after one fails, because the two produce the same layers only when both succeed.

- [x] 1.3 `plugins/containers-cli/skills/apptainer/SKILL.md` — convert an OCI image to `.sif` and
      move it to a cluster.

      **Carry the docker-archive caveat here verbatim, with the failure it prevents quoted.**
      Apptainer 1.1.x speaks too old a Docker API to read a modern daemon: `docker-daemon://` fails
      with "client version … too old". The path is `docker save` (or `podman save`) →
      `apptainer build <out>.sif docker-archive://<tar>`. This is currently knowledge held in
      `plugins/containers/agents/containers-doer.md` and verified in `tests/e2e-smoke.sh`; moving it
      into a skill is what stops a future doer rewrite from losing it.

      Verify the `.sif` (`apptainer inspect`) before reporting success. Separate *verified here* from
      *transferred*: with no transfer performed, report the image as cluster-ready in form only.

- [x] 1.4 `plugins/containers-cli/.claude-plugin/plugin.json` and the marketplace entry. The lint is
      bidirectional — an unlisted skill directory is an error, and so is a listed one that is absent.
      It also caught `README.md` claiming 21 plugins when 22 were on disk, in the same pass.

## 2. The gate

- [x] 2.1 `plugins/containers-cli/scripts/check-runtimes.sh`, on the contract every gate here uses:
      exit 0 `available` with a `found:` line, exit 1 `unavailable` with `missing:` and `enable:`
      lines, exit 2 for an unknown tool.

      Two things this gate needs that no existing gate does:
      - **It must report rootless vs rootful**, not only presence. A rootful-only docker is available
        and still unusable to a user without group membership, and "available" would hide that.
      - **It must verify the binary runs**, not merely that it exists — the same property
        `compendium-cli`'s gate needed, for the same reason: a present binary that dies on first use
        would otherwise be reported as available.

## 3. Rewire what is already there

- [x] 3.1 `plugins/containers/agents/containers-doer.md` — replace the inline build-path table with a
      `## Toolbox` table naming the skill per job, the move `bids-doer` and `compendium-doer` already
      made. Update the description and the report block to cover authoring and the runtime used.

      **Do not drop the apptainer↔Docker caveat in the rewrite.** It moves to 1.3; verify it is
      present there before removing it here.

- [x] 3.2 `plugins/project/skills/new-project/SKILL.md` step 4 — stop hand-writing "a minimal
      `Dockerfile`/`Apptainer.def`". Delegate to the containers doer, and add `containers` to
      `delegates_to`. A new project then either gets a Dockerfile derived from its declared
      environment or is told plainly that its environment is not pinned yet.

      This changes a planner's `delegates_to`, so `tests/check-bench-fixtures.py` will fail the
      moment it is edited. Resolve the routing ground truth **in this change**, not after it — that
      failure is the signal working as designed.

- [x] 3.3 Check whether `analyze/run-comparison`'s delegation prose still matches the doer's new
      shape. It is the only existing skill with `delegates_to: [containers, datalad]`.

- [x] 3.4 **Environments are plural everywhere they are mentioned.** The doer, the skills and
      `new-project` all currently say "the project's environment", singular. A real study has an
      authored analysis environment, one vendored image per pipeline, and sometimes a derived one.
      Each is named and each records the pipeline it serves; when a request does not say which, the
      doer asks rather than defaulting to whichever it finds.

      **Add no registry for this.** `datalad containers-add <name>` already keys containers by name
      in `.datalad/config`, and `datalad containers-run --container-name <name>` already selects
      among them — both already covered by `datalad-cli/skills/datalad-container-run`. The naming
      stays where it already works; this capability builds and pins.

- [x] 3.5 State the `nipoppy` boundary in both doers, since both could plausibly claim it: nipoppy
      declares which pipeline and version a dataset runs; `containers` obtains, pins, builds and
      converts the image that pipeline executes in. A capability boundary that is only implied is one
      that gets crossed.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at **22 plugins, 77
      skills, 9 agents**, as predicted.
- [x] 4.2 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.3 `python3 tests/check-bench-fixtures.py` — clean at 42. It failed the moment `new-project`
      gained `containers`, naming the stale expectation exactly:
      `task 'project-new' expects delegates_to ['datalad'] but 'project/new-project' declares
      ['containers', 'datalad'] — ground truth is stale`. Resolved in this change, as 3.2 required.
- [x] 4.4 e2e: a `containers-cli` block on the gate-and-skip pattern, **19 assertions**, suite now
      124 passed / 0 failed (up from 105). Beyond the usual gate checks it asserts the two pinning
      rules and the archive path are *written in the skills*, not merely remembered: a skill that
      stops saying "never use `docker-daemon://`" fails the suite. That is the assertion most likely
      to matter in a year.
- [x] 4.5 **The limit, and where it does not apply.** For every other toolbox in this repository the
      honest statement is "the gates are tested and the paths behind them are not". Here it is not,
      and that asymmetry is worth recording precisely.

      All three runtimes are present on the development machine, so the path was run for real:
      - `podman build` from a Dockerfile — built.
      - `apptainer build docker-daemon://…` — **failed, verbatim**: `conveyor failed to get: loading
        image from docker engine: Error response from daemon: client version 1.22 is too old.
        Minimum supported API version is 1.40`. This is the trap the capability is shaped around, and
        it is now confirmed rather than remembered.
      - `podman save` → `apptainer build docker-archive://…` — produced a valid `.sif`.
      - `apptainer inspect` and `apptainer exec <sif> python3 --version` — ran, returning
        `Python 3.11.14`.
      - tag → digest via `podman manifest inspect docker.io/library/alpine:3.19` — resolved to
        `sha256:b58899f069c47216f6002a6850143dc6fae0d35eb8b0df9300bbe6327b9c2171`, which is the
        vendored-pin mechanism working.

      **Still not established:** that any of this runs on an actual cluster. Nothing here reached
      one, the transfer step was not exercised, and the `.sif` was verified only on the machine that
      built it.
- [x] 4.6 The three kinds are named in the `dockerfile` skill's report block (`kind:` and `pin:`),
      in the doer's report block, and asserted present by the e2e block. A vendored image whose pin
      did not resolve reports `unresolved (<why>)` rather than showing the tag in the `pin:` field —
      the failure mode this change exists to prevent is visible in the report, not only in prose.

- [x] 4.7 **Recorded as unexercised, not quietly assumed.** `renv.lock` — no R project exists here to
      check it against. Mark it as such rather than letting the spec imply it was tried.
