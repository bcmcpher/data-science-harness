## 1. Python toolchain

- [x] 1.1 `pyproject.toml` — project metadata seeding the planned `ds-harness`, `requires-python`
      matching the interpreter the checks are exercised on, no `[project.dependencies]` yet.
- [x] 1.2 PEP 735 dependency groups: `dev` (`pyyaml`, `jsonschema`) and `e2e` (adds `datalad`).
- [x] 1.3 `uv lock` and commit `uv.lock`.
- [x] 1.4 Verify all four check scripts run from a synced environment.

## 2. Node toolchain

- [x] 2.1 `package.json` — `@fission-ai/openspec` and `mystmd` as devDependencies, pinned to the
      versions currently in use.
- [x] 2.2 `npm install` and commit `package-lock.json`.
- [x] 2.3 Confirm `openspec validate` and the paper build resolve from `node_modules/`, not globally.
- [x] 2.4 `.nvmrc` pinning the Node major, since `engines.node` is a range and `setup-node`
      resolves `.nvmrc` more predictably.
- [x] 2.5 `tests/check-paper.sh` — build `paper/` and fail on an unresolved citation. Needed
      because MyST reports an unresolved citation as a *warning*, so `myst build --strict` alone
      goes green with a broken bibliography; and because `--html` starts the theme server and does
      not terminate, so CI must use `--site`.

## 3. End-to-end toolchain

- [x] 3.1 `environment.yml` — conda-forge `datalad`, `git-annex`, `datalad-container`, and the
      Python check deps, so one env covers a full local run.
- [x] 3.2 State in the file that it is deliberately unlocked, and why.
- [x] 3.3 Note that apptainer is a system package outside conda's reach.

## 4. Wire CI to the manifests

- [x] 4.1 Replace the inline `pip install pyyaml jsonschema` with a lock-file sync.
- [x] 4.2 Replace `npm install -g @fission-ai/openspec@1` with `npm ci` plus `npx`.
- [x] 4.3 Replace the e2e job's ad hoc apt and pip steps with the conda environment.
- [x] 4.4 Add the fixture-check job's dependency to the same synced environment.

## 5. Housekeeping

- [x] 5.1 `.gitignore`: `node_modules/`, `.venv/`, `__pycache__/`, `*.egg-info/`.
- [x] 5.2 README: a setup section naming each toolchain and what it enables.

## 6. Catch the next undeclared import

- [ ] 6.1 Add the import-versus-manifest check to `tests/lint-plugins.py`.
- [ ] 6.2 Add the corresponding selftest case.

## 7. Verify

- [x] 7.1 From a clean checkout: sync each toolchain and run all four checks plus `openspec validate`.
- [x] 7.2 `myst build --html` in `paper/` succeeds from the locked Node environment.
- [x] 7.3 `python3 tests/lint-plugins.py --strict` and the selftest both clean.
- [x] 7.4 `environment.yml` verified by dispatching the e2e job: conda-forge resolved
      git-annex 10.20260717 (well past the >= 10.20230126 the smoke test requires) and
      datalad 1.6.2, and `tests/e2e-smoke.sh` reported 36 passed / 0 failed with the container
      block skipping cleanly on the absent apptainer runtime.
- [x] 7.5 The first dispatch failed: a fresh runner has no git identity, and the script silences
      stderr on the commands `set -e` aborts on, so the log ended at the last PASS with no
      diagnostic. Both fixed in the workflow — identity configured, and a `bash -x` re-run on
      failure so the next one is diagnosable.
