## Context

Three toolchains, used in three different places, by three different audiences:

| Toolchain | Used by | Needed by |
|---|---|---|
| Python (`pyyaml`, `jsonschema`) | the four check scripts | anyone running the checks; CI on every push |
| Node (`openspec`, `mystmd`) | spec validation, paper build | maintainers and CI |
| conda (`datalad`, `git-annex`, container runtime) | `tests/e2e-smoke.sh` | e2e runs only; dispatch-triggered in CI |

The README already states the project's position: "The target community (academic data scientists)
already uses `pip`/`uv`. The format itself has zero Python dependency — Python is only needed to run
the CLI installer." That stays true. What is being pinned is the tooling that checks and builds the
repository, not anything a user of the harness content needs.

## Goals / Non-Goals

**Goals:**
- A recorded, reproducible set of versions for each toolchain.
- CI installing from the manifests rather than from inline floating specifiers.
- A single documented path from a fresh clone to a passing check run.
- A `pyproject.toml` that the planned `ds-harness` CLI can grow into.

**Non-Goals:**
- Adding a dependency to the harness *content*. Skills and agents stay plain Markdown.
- Requiring conda. It owns only the e2e stack; the Python and Node paths work without it.
- Vendoring anything.
- Publishing `ds-harness` to PyPI. The metadata is a seed, not a release.

## Decisions

- **Three manifests, not one.** A single file would have to claim that the paper build and the
  provenance smoke test are the same kind of dependency, and they are not — one is a Node CLI a
  maintainer needs, the other is a system-level stack that CI deliberately does not install on every
  push. Separating them means the common case (`uv sync`, run the checks) stays cheap.
- **Lock what can be locked.** `uv.lock` and `package-lock.json` are committed. `environment.yml`
  is not locked to explicit builds: `conda-lock` output is platform-specific, and the e2e stack is
  already gated and skippable, so a floating conda-forge spec is the right trade. Say so in the file
  rather than leaving it to be inferred.
- **`pyproject.toml` declares no runtime dependencies.** The repository is not yet a Python package;
  the checks are standalone scripts. Dependencies live in PEP 735 dependency groups (`dev`, `e2e`),
  which is what `uv sync --group` consumes and what keeps `[project.dependencies]` free for
  `ds-harness` when it exists.
- **Node deps are local, not global.** `npm ci` into `node_modules/`, invoked through `npx`. Global
  installs are what produced the current situation, where the machine had `openspec` and did not have
  `mystmd` and nothing recorded either fact.
- **Python floor is 3.10**, matching the interpreter the checks are exercised on. The scripts already
  use PEP 604 unions and builtin generics, so nothing older would work anyway.
- **The lint gains a manifest check.** A dependency added to a check script but not to a manifest is
  the exact drift this change exists to fix; catching it mechanically is cheap and it is the same
  class of check the lint already performs for skills and manifests.

## Risks / Trade-offs

- **Three manifests is more surface than one.** The justification is that they have genuinely
  different audiences and lifecycles; the cost is a contributor having to know which one owns their
  new dependency. The README and the lint check between them should make that unambiguous.
- **`environment.yml` is unlocked**, so an e2e run is reproducible in intent but not in bytes. That
  is a real weakening, accepted because the block is gated and the alternative is per-platform lock
  files for a test that already self-skips.
- **`uv.lock` pins a resolution, not an interpreter.** A different Python patch version can still
  behave differently. CI pins the interpreter separately.
- **Committing `package-lock.json` will produce dependabot-style churn** on a repository that is
  otherwise Markdown. Worth it for a reproducible `openspec validate`, but it is noise.
