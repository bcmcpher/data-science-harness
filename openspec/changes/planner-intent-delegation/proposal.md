## Why

A planner skill adapts most easily when three layers are kept apart. This was the hackathon finding
the harness grew from:

- the **narrative plan**: what the researcher is doing;
- the **implementation**: the tools that manipulate files;
- the **compute environment**: what is available on this machine.

After `native-datalad-planners`, DataLad, git and git-annex are native to the main thread. Their
commands belong in planners, the way git commands belong in ordinary code. The peripheral tools are
different. nipoppy, containers, MyST, pyinfra and the annotation backends sit behind doers
precisely so that a doer can pick, pin or change its tool without the planners being rewritten.
Seven planners still spell out those tools' command lines (20 spans in total). `process/run-pipeline`
builds `nipoppy process --pipeline …` itself, although `openspec/specs/process/spec.md` says it
MUST NOT. Nothing checks this boundary. The three-layer finding is also not recorded anywhere.

## What Changes

- **Planners state intent for peripheral tools.** When a planner asks a doer for work, it states
  the intent, the parameters and the outputs it needs back, not the command line. DataLad, git and
  git-annex commands, and the harness's own scripts (`plugins/*/scripts/`, `schemas/`), stay
  allowed.
- **A new lint error** for command syntax of a peripheral tool in a workflow-plane skill body.
  The closed set of tool binaries lives in `tests/lint-plugins.py`, and the selftest covers the
  check. No baseline file is needed, because all current offenders are fixed in this change.
- **Seven planners rewritten** to zero spans:
  - `disseminate/executable-article`
  - `process/run-pipeline`
  - `disseminate/liab-deploy`
  - `curate/raw-to-bids`
  - `curate/annotate`
  - `curate/gen-data-dict`
  - `curate/deidentify`

  Where a command line carried a safeguard (a `--simulate` preview, explicit pipeline and version
  flags), the planner restates it as a rule in words.
- **Docs.**
  - `docs/motivation.md` records the three-layer finding. It also records that the compute
    environment is left to environment providers, and that `project/env-check` is the seam where
    provider context enters.
  - `README.md`'s "never calls a CLI directly" is reworded to the rule that is actually enforced.
  - `templates/skill/SKILL.md` shows an intent-form request to a doer.

**Not in this change:** a capability registry, capability names in `delegates_to`, a shared doer
return contract, alternative toolboxes for nipoppy, and lmod/module discovery. The tool binding
record is `DSH-Binding`, defined in `native-datalad-planners`.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `skill-format`: add the intent-delegation rule for peripheral tools, and state that the native
  toolchain's syntax is allowed.
- `structural-lint`: add the peripheral-syntax check and its selftest case.

## Impact

- `tests/lint-plugins.py`, `tests/lint-plugins-selftest.py`
- The seven planner `SKILL.md` files listed above
- `README.md` (Axis 1), `docs/motivation.md` (Architecture), `templates/skill/SKILL.md`
- No doer, toolbox or schema changes: doers already parse plain-language requests.
- **Depends on** `native-datalad-planners`, which rewrites these same files first.
