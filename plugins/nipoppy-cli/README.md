# nipoppy-cli

Nipoppy toolbox (capability plane): reference material for the
[nipoppy](https://nipoppy.readthedocs.io) neuroimaging dataset management CLI, read by the
`nipoppy` doer. Split into four skills, one per **command class** rather than one per verb.

## What it does

| Skill | Class | Verbs | Handling |
|---|---|---|---|
| `nipoppy-query` | read-only | `status`, `pipeline search`, `pipeline list` | Run directly; nothing to save |
| `nipoppy-track` | bookkeeping write | `track-curation`, `track-processing` | Run directly, report the files written, save as a checkpoint |
| `nipoppy-compute` | dataset-mutating computation | `reorg`, `bidsify`, `process`, `extract` | Construct and simulate; **never execute** — the planner runs it under `datalad run` |
| `nipoppy-setup` | declarations | `init`, `pipeline install/create/validate/upload` | Run directly, report what was created and what is still owed |

The split is by class because the *handling rule* is a property of the class, not of the verb.
nipoppy records nothing about how derivatives came to be, so a computation executed bare produces a
tree nothing can re-derive and no commit explains — and six months later it is indistinguishable
from one that was provenanced. Keeping those verbs behind a skill that refuses to run them is what
makes that a structural property rather than a habit.

## Install

```bash
# Session-only (for testing)
claude --plugin-dir ./plugins/nipoppy-cli

# Permanent install
claude plugin install ./plugins/nipoppy-cli
```

## Usage

**Auto-invoked** when the user asks about nipoppy commands, initializing a dataset, organizing
DICOMs, running BIDS conversion, executing fMRIPrep/MRIQC, or extracting IDPs.

**Slash commands:** `/nipoppy-query`, `/nipoppy-track`, `/nipoppy-compute`, `/nipoppy-setup`.

## References

Shared by all four skills, at `references/`:

| File | Contents |
|------|----------|
| `workflow-overview.md` | Full workflow diagram, key files, glossary, platform requirements |
| `setup-commands.md` | `init` and `status` — options and examples |
| `curation-commands.md` | `track-curation` and `reorg` — options, DICOM checks, curation status schema |
| `bids-commands.md` | `bidsify` — dcm2bids, HeuDiConv, BIDScoin options and Boutiques context |
| `process-command.md` | `process` — options, HPC submission, subcohort workflow |
| `track-extract-commands.md` | `track-processing` and `extract` — bagel schema, IDP extraction |
| `pipeline-catalog-commands.md` | `pipeline search`, `install`, `list` |
| `pipeline-authoring-commands.md` | `pipeline create`, `validate`, `upload` |
