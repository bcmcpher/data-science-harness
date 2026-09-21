## Why

The harness has a complete workflow plane, a lint, and a smoke test, and no way to say why any of it
exists to anyone outside the repository. Three specific gaps:

- **No literature record.** There is no `.bib`, `.ris`, or `.csl` file anywhere. The closest thing is
  the 11-row source table in `docs/writing/index.md`, which covers manuscript *craft* — how to write
  a paper — not the work that motivates this harness. The README names STAMPED, BIDS, Neurobagel,
  NeuroLibre, Paper2Agent, Lab-in-a-Box, ORCID, CRediT, and EQUATOR without citing any of them.
- **No evaluation.** Nothing measures agent behaviour. `tests/lint-plugins.py` checks structure and
  `tests/e2e-smoke.sh` checks that raw DataLad commands produce the provenance they should, but
  neither says whether an assistant with this harness installed does better work than one without.
- **No publication.** The work began at an OHBM hackathon and is headed for an arXiv/bioRxiv preprint
  and then Aperture Neuro, OHBM's open-access journal, which explicitly welcomes code, dataset, and
  protocol descriptions. There is nowhere to draft it.

Two recent sources prompted this. Chen et al. (2026), *Brain Researcher*, is an agentic research
harness for neuroimaging that enforces rules for admissible analyses, required checks, and claim
scope; it reports first-choice tool-selection accuracy rising from 23.3% to 93.6% across seven models
on 60 tool-calling tasks. It shares authors with work this repository already cites, and it is close
enough to this project that the relationship has to be stated precisely rather than assumed to be
complementary. Botes (2026) argues that governance must be built into neuroscience AI infrastructure
rather than retrofitted, and observes that "what gets benchmarked gets built" — which is a direct
argument for defining the evaluation before the capabilities it would measure.

## What Changes

- `docs/references/` — a BibTeX file, an index table, and one annotated note per source recording
  what it motivates and where it differs.
- `docs/evaluation.md` plus `bench/` fixtures — a described protocol across four probes, with a
  declarative, composable fixture format. **No runner and no executed benchmark.** Which integrations
  the paper covers is not yet settled, so the format has to let probes and tasks be added and removed
  without touching shared code.
- `paper/` — a MyST project, so the paper arguing for re-executable articles is one.
- `.github/workflows/ci.yml` — the repository's first CI, running the lint, the selftest, the ledger
  validator, and `openspec validate`.

## Capabilities

### New Capabilities
- `literature-record`: how motivating sources are tracked, and the requirement that each one names
  what it motivates.
- `evaluation-protocol`: the four measurement probes, their fixture format, and the honesty
  constraints on reporting results that have not been produced.
- `publication`: where the paper lives, what it must contain, and what it must not claim.

## Impact

- New: `docs/references/`, `docs/evaluation.md`, `bench/`, `paper/`, `.github/workflows/ci.yml`
- Modified: `.gitignore` (`paper/_build/`)
- No change to `plugins/`. This change adds no capability to the harness itself.
