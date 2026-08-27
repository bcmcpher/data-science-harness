## 1. The liab doer

- [ ] 1.1 Write `plugins/liab/agents/liab-doer.md`: parse request, build inventory, plan, confirm
      target, apply, verify sibling, report.
- [ ] 1.2 Make plan-by-default and the target-naming confirmation explicit constraints, not prose
      suggestions.
- [ ] 1.3 State the partial-application reporting rule and the no-automatic-retry rule.
- [ ] 1.4 `plugins/liab/.claude-plugin/plugin.json`.

## 2. The liab-cli toolbox

- [ ] 2.1 `plugins/liab-cli/skills/pyinfra/SKILL.md` — defaults to a plan; `allowed-tools` scoped.
- [ ] 2.2 `plugins/liab-cli/skills/forgejo/SKILL.md` — instance setup and repository/remote creation.
- [ ] 2.3 `plugins/liab-cli/.claude-plugin/plugin.json` and marketplace entries for both plugins.

## 3. Rewire the planner

- [ ] 3.1 `plugins/disseminate/skills/liab-deploy/SKILL.md` → `delegates_to: [liab, datalad]`, with
      prose naming the doer.
- [ ] 3.2 Add the "record what was deployed, do not claim compliance" constraint to the skill body.

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py` — 0 errors.
- [ ] 4.2 e2e assertion: a dry-run deploy plan is produced and no network operation occurs.
- [ ] 4.3 Document in the skill that the apply path is exercised manually, not by the test suite —
      state the verification gap rather than implying coverage.
