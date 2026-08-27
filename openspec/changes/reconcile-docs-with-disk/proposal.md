## Why

The README is the harness's only top-level document and it has drifted from the repository it
describes. The gaps are mechanical and measurable:

- It says "**Eleven plugins**" (`README.md:171`); there are **13** on disk.
- It references **`plugin.yaml` 8 times**, including in the Contributing steps that tell a new
  contributor to add their skill's path to it. There are **0** `plugin.yaml` files and **13**
  `.claude-plugin/plugin.json`. A first contribution following the README edits a file that does not
  exist.
- It documents a **`harness.yaml` root manifest**; there are 0 on disk.
- Its Plugins tables name a `publish` and an `annotate` capability plugin and roughly thirteen
  workflow skills — `init-ledger`, `dmp`, `ethics-track`, `stamped-assess`, `env-check`,
  `claude-config`, `track-milestone`, `merge-data`, `gen-data-dict`, `annotate-variables`,
  `plan-analysis`, `gen-report`, `submission-track` — that were never built.
- Its Project Ledger example (`README.md:252-317`) shows a far richer schema than
  `schemas/project.schema.json` accepts, which has `additionalProperties: false`. Following the
  example produces a ledger that fails validation.
- `.claude-plugin/marketplace.json` expands STAMPED as "Shareable, Tracked, Actionable,
  Metadata-rich, Provenanced, Executable, and Distributable"; `docs/stamped.md` defines it as
  Self-containment, Tracking, Actionability, Modularity, Portability, Ephemerality, Distributability.
  Two different acronyms are shipping under one name.
- The Repository Structure block omits `docs/writing/`, `docs/project-ledger.md`, `examples/`, and
  `tests/lint-plugins-selftest.py`.
- The Install section does not mention OpenCode, although `bin/install.sh` defaults to it.
- `analyze/literature-search` is described at `README.md:228` but does not exist.

Documentation that describes a different repository is worse than no documentation: it costs a
contributor a wasted attempt and it makes every other claim in the file less credible.

## What Changes

- Every claim above corrected against disk, or the missing thing built, or the claim marked
  explicitly as planned.
- A lint check for the mechanically checkable subset, so this drift is caught rather than
  rediscovered.

The temporary roadmap section was already removed when OpenSpec was introduced — its content is now
`openspec/changes/` — so that part of the original Phase 12 is done and is not tracked here.

## Capabilities

### Modified Capabilities
- `structural-lint`: gains a check that the documented manifest filename and plugin count match disk.

## Impact

- Modified: `README.md`, `.claude-plugin/marketplace.json`, `docs/writing/SPEC.md`,
  `tests/lint-plugins.py`, `tests/lint-plugins-selftest.py`
- Independent of every other change; can be picked up at any time.
