## 1. The compendium doer

- [ ] 1.1 Write `plugins/compendium/agents/compendium-doer.md`: parse request, check dependencies,
      scaffold, build in the project container, report.
- [ ] 1.2 State the two refusal rules: no unprovenanced figure embedded silently, no partial artifact
      presented as complete.
- [ ] 1.3 `plugins/compendium/.claude-plugin/plugin.json`.

## 2. The compendium-cli toolbox

- [ ] 2.1 `plugins/compendium-cli/skills/myst/SKILL.md`.
- [ ] 2.2 `plugins/compendium-cli/skills/jupyter-book/SKILL.md`.
- [ ] 2.3 `plugins/compendium-cli/skills/repo2data/SKILL.md`.
- [ ] 2.4 `plugins/compendium-cli/skills/mcp-scaffold/SKILL.md` — emit skill files, plugin manifest,
      and MCP config in the harness's universal format.
- [ ] 2.5 `plugins/compendium-cli/.claude-plugin/plugin.json` and marketplace entries for both plugins.

## 3. Finish the article path before starting the bundle path

- [ ] 3.1 Rewire `plugins/disseminate/skills/executable-article/SKILL.md` to
      `delegates_to: [compendium, datalad]`, with prose naming the doer.
- [ ] 3.2 e2e assertion: `executable-article` produces a MyST tree that builds from a released product.
- [ ] 3.3 Only then rewire `plugins/disseminate/skills/agent-bundle/SKILL.md`.
- [ ] 3.4 e2e assertion: an emitted bundle passes `tests/lint-plugins.py`'s structural checks.

## 4. Resolve the manuscript sub-agent

- [ ] 4.1 Decide `docs/writing/SPEC.md`'s `manuscript` sub-agent: build it as part of this cluster, or
      mark it explicitly deferred in the SPEC.
- [ ] 4.2 If built, relocate the writing reference bundle to `plugins/disseminate/references/writing/`
      as the SPEC's build note describes, and replace the symbolic `model: strong-writing` with a real
      value validated by `pin-doer-models`.

## 5. Verify

- [ ] 5.1 `python3 tests/lint-plugins.py` — 0 errors.
- [ ] 5.2 Neither planner still reads `delegates_to: [datalad]`.
- [ ] 5.3 Both e2e assertions gated to skip cleanly when MyST or a container runtime is absent.
