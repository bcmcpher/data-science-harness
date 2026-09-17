## Status

The minimal working core below shipped on 2026-09-17: the doer, `bagel-cli`, the backend check,
the planner rewired to `delegates_to: [annotate, datalad]`, and a gated e2e block. Tasks 2.2-2.4
remain, so this change stays open — `openspec archive` would merge a spec delta claiming a
`user-invocable` skill per supported tool, and three of the four have none.

## 0. Minimal working core

The doer (1.1-1.3) plus **`bagel-cli` alone** (2.1, 2.5), with the planner rewired (3.1-3.3) and
verified (4.1-4.3). Neurobagel is the most-named backend across planner bodies and the one that
makes a dataset machine-queryable, which is this change's stated point.

Deferred: `pynidm` (2.2), `reproschema` (2.3), `snomed-lookup` (2.4). Each adds a backend; none
changes whether the capability works. Ship the core, confirm `curate/annotate` no longer reads
`delegates_to: [datalad]`, then add backends one at a time.

## 1. The annotate doer

- [x] 1.1 Write `plugins/annotate/agents/annotate-doer.md` with the standard doer frontmatter and the
      operating procedure: parse request, check per-backend availability, look up, write, report.
- [x] 1.2 State the refusal rule explicitly, in the shape the archive doer uses for `unminted`: no
      identifier appears in a report unless a queried source returned it.
- [x] 1.3 Create `plugins/annotate/.claude-plugin/plugin.json` listing the agent.

## 2. The annotate-cli toolbox

- [x] 2.1 `plugins/annotate-cli/skills/bagel-cli/SKILL.md` — Neurobagel annotation and harmonization.
- [ ] 2.2 `plugins/annotate-cli/skills/pynidm/SKILL.md` — NIDM term export and query.
- [ ] 2.3 `plugins/annotate-cli/skills/reproschema/SKILL.md` — assessment/protocol schema handling.
- [ ] 2.4 `plugins/annotate-cli/skills/snomed-lookup/SKILL.md` — controlled-term lookup, explicit
      about what source it queries and what it needs to be configured.
- [x] 2.5 Create `plugins/annotate-cli/.claude-plugin/plugin.json`. Lists only `./skills/bagel-cli`
      today — the lint errors on a listed directory with no `SKILL.md`, so it grows with 2.2-2.4.
- [x] 2.6 `plugins/annotate-cli/scripts/check-backends.sh` — offline per-backend presence check in
      the shape `archive-cli/scripts/check-readiness.sh` uses (0 available, 1 unavailable, 2 usage),
      so the "degrade per tool" rule has a deterministic, testable mechanism.

## 3. Rewire the planner

- [x] 3.1 Change `plugins/curate/skills/annotate/SKILL.md` frontmatter to
      `delegates_to: [annotate, datalad]`.
- [x] 3.2 Replace the body's "future annotate doer" language with a concrete delegation naming the
      **annotate** doer, so prose and frontmatter agree in both directions.
- [x] 3.3 Add both plugins to `.claude-plugin/marketplace.json`.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py` — 0 errors; counts grow by 2 plugins, 1 skill, 1 agent
      in this pass, reaching 4 skills once 2.2-2.4 land.
- [x] 4.2 Add a gated block to `tests/e2e-smoke.sh`: a scaffolded dataset gains a `participants.json`
      that validates, with controlled terms where a backend is available; skip cleanly when none is.
- [x] 4.3 Confirm `curate/annotate` no longer reads `delegates_to: [datalad]` — the observable signal
      that this phase shipped.
