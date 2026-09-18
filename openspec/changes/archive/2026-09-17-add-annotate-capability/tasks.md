## Status

Complete as of 2026-09-17, in two passes on the same day. The minimal working core landed first —
the doer, `bagel-cli`, the backend check, the planner rewired to `delegates_to: [annotate, datalad]`,
and a gated e2e block — then `pynidm`, `reproschema` and `snomed-lookup` (2.2-2.4), which is what
the spec delta's "one skill per supported tool" requirement needs before it can be merged into
`specs/`. Ready to archive.

## 0. Minimal working core

The doer (1.1-1.3) plus **`bagel-cli` alone** (2.1, 2.5), with the planner rewired (3.1-3.3) and
verified (4.1-4.3). Neurobagel is the most-named backend across planner bodies and the one that
makes a dataset machine-queryable, which is this change's stated point.

Deferred to the second pass: `pynidm` (2.2), `reproschema` (2.3), `snomed-lookup` (2.4). Each adds a
backend; none changed whether the capability works. The core shipped, `curate/annotate` stopped
reading `delegates_to: [datalad]`, and the three backends followed.

Writing them surfaced something the design did not anticipate, and it is now stated in the doer:
**most of this toolbox validates terms rather than finding them.** `bagel-cli` and `reproschema`
check terms and schemas you already have; only a `snomed-lookup` query and an *interactive* `pynidm`
session resolve a new identifier, and the latter blocks on stdin, so the doer hands that command to
the user instead of running it. The "never recall a term" rule therefore has exactly two legitimate
inbound paths, which the doer names.

## 1. The annotate doer

- [x] 1.1 Write `plugins/annotate/agents/annotate-doer.md` with the standard doer frontmatter and the
      operating procedure: parse request, check per-backend availability, look up, write, report.
- [x] 1.2 State the refusal rule explicitly, in the shape the archive doer uses for `unminted`: no
      identifier appears in a report unless a queried source returned it.
- [x] 1.3 Create `plugins/annotate/.claude-plugin/plugin.json` listing the agent.

## 2. The annotate-cli toolbox

- [x] 2.1 `plugins/annotate-cli/skills/bagel-cli/SKILL.md` — Neurobagel annotation and harmonization.
- [x] 2.2 `plugins/annotate-cli/skills/pynidm/SKILL.md` — NIDM term export and query.
- [x] 2.3 `plugins/annotate-cli/skills/reproschema/SKILL.md` — assessment/protocol schema handling.
- [x] 2.4 `plugins/annotate-cli/skills/snomed-lookup/SKILL.md` — controlled-term lookup, explicit
      about what source it queries and what it needs to be configured. It is the only skill in the
      toolbox that leaves the machine, so it also states what it sends (column names and labels,
      never participant rows) and keeps `unavailable`, `no match` and `failed` as three answers.
- [x] 2.5 Create `plugins/annotate-cli/.claude-plugin/plugin.json`. Now lists all four skills; it
      listed only `./skills/bagel-cli` in the first pass, because the lint errors on a listed
      directory with no `SKILL.md`.
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

- [x] 4.1 `python3 tests/lint-plugins.py` — 0 errors; counts grew by 2 plugins, 1 agent, and 4
      skills across the two passes (1 then 3), reaching 16 plugins / 49 skills / 7 agents.
- [x] 4.2 Add a gated block to `tests/e2e-smoke.sh`: a scaffolded dataset gains a `participants.json`
      that validates, with controlled terms where a backend is available; skip cleanly when none is.
      Extended in the second pass to assert the per-backend contract for all four — each names
      itself, answers 0 or 1, says how to enable itself when unavailable, and has a `SKILL.md`
      behind it, so the check can never green-light a backend with no invocation path.
- [x] 4.3 Confirm `curate/annotate` no longer reads `delegates_to: [datalad]` — the observable signal
      that this phase shipped.
