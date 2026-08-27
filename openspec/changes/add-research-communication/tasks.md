## 1. Literature record

- [x] 1.1 `docs/references/references.bib` — seed with Chen et al. 2026 (Brain Researcher,
      arXiv:2608.19902), Botes 2026 (Biolawgic, web-only), and Macdonald et al. 2026 (STAMPED).
- [x] 1.2 Extend with the sources the README names but never cites: BIDS, Neurobagel, NeuroLibre,
      Paper2Agent, Lab-in-a-Box, DataLad, Nipoppy, ORCID, CRediT, EQUATOR, COBIDAS.
- [x] 1.3 `docs/references/index.md` — the source table, following `docs/writing/index.md`'s columns
      plus a "motivates" column naming an `openspec/specs/` capability, and an attribution note.
- [x] 1.4 `docs/references/notes/chen-2026-brain-researcher.md` — claim, what it motivates, where it
      differs, short quoted passages.
- [x] 1.5 `docs/references/notes/botes-2026-law-inside-machine.md`.
- [x] 1.6 `docs/references/notes/macdonald-2026-stamped.md`.
- [x] 1.7 Confirm every note names at least one capability; drop any source that names none.

## 2. Evaluation protocol

- [x] 2.1 `docs/evaluation.md` — fixture schemas, the four probes, control conditions, judging
      procedure, and what invalidates a result.
- [x] 2.2 State prominently that no probe has been executed.
- [x] 2.3 `bench/README.md` — how to add a probe, task, or rubric without touching shared code.
- [x] 2.4 `bench/probes/{routing,provenance,reproducibility,cost}.yaml`.
- [x] 2.5 `bench/tasks/` — at least one worked suite for the routing probe, with expected planner and
      `delegates_to` per task.
- [x] 2.6 `bench/rubrics/` — the scored dimensions and anchors the provenance probe needs.
- [x] 2.7 Point the provenance and reproducibility probes at `schemas/validate-ledger.py` and
      `tests/e2e-smoke.sh`, and the cost probe at the existing transcript analyzer.

## 3. Paper

- [x] 3.1 `paper/myst.yml` and `paper/main.md`.
- [x] 3.2 `paper/sections/01-intro.md` — AI-accelerated analysis outpacing governable provenance.
- [x] 3.3 `paper/sections/02-related.md` — Brain Researcher, NeuroLibre, Paper2Agent, Lab-in-a-Box,
      STAMPED, with the positioning stated as a distinction.
- [x] 3.4 `paper/sections/03-architecture.md` — two planes, planner/doer, ledger, comparison→product,
      living compendium.
- [x] 3.5 `paper/sections/04-evaluation.md` — the protocol as planned work, no results.
- [x] 3.6 `paper/sections/05-discussion.md` — limitations led by the absence of executed evaluation.
- [x] 3.7 Wire the bibliography to `docs/references/references.bib` rather than copying it.
- [x] 3.8 Record the venue path and its submission constraints with the draft.

## 4. CI

- [x] 4.1 `.github/workflows/ci.yml` running `tests/lint-plugins.py`,
      `tests/lint-plugins-selftest.py`, `schemas/validate-ledger.py examples/project.yaml`, and
      `openspec validate --all --strict --no-interactive`.
- [x] 4.2 Honour the exit-code contract: status 2 means the dependency is absent, which is a skip.
- [x] 4.3 Leave `tests/e2e-smoke.sh` off the push trigger — it needs DataLad and apptainer.
- [x] 4.4 State in the workflow that it checks structure and specs, not agent behaviour.

## 5. Housekeeping

- [x] 5.1 Add `paper/_build/` to `.gitignore`.

## 6. Verify

- [x] 6.1 `openspec validate --all --strict --no-interactive` passes.
- [x] 6.2 `paper/` builds and citations resolve — `npm run paper:check`. mystmd is now pinned in
      `package.json` (see `add-dependency-environment`).
- [x] 6.3 Every `bench/tasks/*.yaml` `expected_delegates_to` names a plugin that provides an agent.
- [ ] 6.4 CI green on a branch push; confirm it fails when a spec is deliberately corrupted.
      **Not yet run:** the workflow has never executed — nothing has been pushed.
