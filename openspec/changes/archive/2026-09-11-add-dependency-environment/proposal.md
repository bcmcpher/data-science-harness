## Why

The repository has no dependency manifest of any kind — no `pyproject.toml`, `requirements.txt`,
`environment.yml`, `package.json`, or lockfile. Every tool it needs is assumed to be already on the
machine, and the versions that were actually used are recorded nowhere.

This is a real gap and an awkward one, because the harness's own argument is that computational
environments MUST be explicitly specified and version controlled (STAMPED P.2 and P.3,
`docs/stamped.md`). The repository asks users to pin their analysis environments while pinning
nothing itself.

It is also already costing something concrete. `.github/workflows/ci.yml` installs `pyyaml`,
`jsonschema`, and `@fission-ai/openspec@1` inline with floating versions, so a CI run is not
reproducible and an upstream change can break the build with no diff to point at. `mystmd` was
missing entirely until it was installed by hand, and nothing recorded that `paper/` needs it.

## What Changes

Three manifests, because the repository genuinely depends on three separate toolchains and
collapsing them would misrepresent what needs what:

- **`pyproject.toml` + `uv.lock`** — the Python checks (`tests/lint-plugins.py`,
  `tests/lint-plugins-selftest.py`, `tests/check-bench-fixtures.py`, `schemas/validate-ledger.py`).
  Also the seed for the planned `ds-harness` CLI, so it does not need re-inventing later.
- **`package.json` + `package-lock.json`** — the Node CLIs: `@fission-ai/openspec` for spec
  validation and `mystmd` for the paper build.
- **`environment.yml`** — the end-to-end stack: DataLad, git-annex, and the container tooling
  `tests/e2e-smoke.sh` needs. These are not reliably pip-installable, and conda-forge is how they are
  actually obtained.

Plus: CI switched to install from the manifests, `node_modules/` and Python build artifacts ignored,
and the README's Install section told where the dev environment comes from.

## Capabilities

### New Capabilities
- `dependency-environment`: what the repository depends on, which manifest owns each dependency, and
  the requirement that the manifests be the source CI installs from.

### Modified Capabilities
- `structural-lint`: gains a check that every tool the checks import is declared in a manifest, so
  a new dependency cannot be added without being recorded.

## Impact

- New: `pyproject.toml`, `uv.lock`, `package.json`, `package-lock.json`, `environment.yml`
- Modified: `.github/workflows/ci.yml`, `.gitignore`, `README.md`
- No change to `plugins/`. The harness's *content* still has zero dependencies — this pins the
  tooling that checks and builds it, not the format itself.
