## 1. The annotate doer

- [ ] 1.1 Write `plugins/annotate/agents/annotate-doer.md` with the standard doer frontmatter and the
      operating procedure: parse request, check per-backend availability, look up, write, report.
- [ ] 1.2 State the refusal rule explicitly, in the shape the archive doer uses for `unminted`: no
      identifier appears in a report unless a queried source returned it.
- [ ] 1.3 Create `plugins/annotate/.claude-plugin/plugin.json` listing the agent.

## 2. The annotate-cli toolbox

- [ ] 2.1 `plugins/annotate-cli/skills/bagel-cli/SKILL.md` — Neurobagel annotation and harmonization.
- [ ] 2.2 `plugins/annotate-cli/skills/pynidm/SKILL.md` — NIDM term export and query.
- [ ] 2.3 `plugins/annotate-cli/skills/reproschema/SKILL.md` — assessment/protocol schema handling.
- [ ] 2.4 `plugins/annotate-cli/skills/snomed-lookup/SKILL.md` — controlled-term lookup, explicit
      about what source it queries and what it needs to be configured.
- [ ] 2.5 Create `plugins/annotate-cli/.claude-plugin/plugin.json` listing all four skills.

## 3. Rewire the planner

- [ ] 3.1 Change `plugins/curate/skills/annotate/SKILL.md` frontmatter to
      `delegates_to: [annotate, datalad]`.
- [ ] 3.2 Replace the body's "future annotate doer" language with a concrete delegation naming the
      **annotate** doer, so prose and frontmatter agree in both directions.
- [ ] 3.3 Add both plugins to `.claude-plugin/marketplace.json`.

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py` — 0 errors; counts grow by 2 plugins, 4 skills, 1 agent.
- [ ] 4.2 Add a gated block to `tests/e2e-smoke.sh`: a scaffolded dataset gains a `participants.json`
      that validates, with controlled terms where a backend is available; skip cleanly when none is.
- [ ] 4.3 Confirm `curate/annotate` no longer reads `delegates_to: [datalad]` — the observable signal
      that this phase shipped.
