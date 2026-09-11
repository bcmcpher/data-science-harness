## 0. Minimal working core

The doer (1.1-1.3) plus **`myst` alone** (2.1, 2.5), with `executable-article` rewired and building
(3.1-3.2). Section 3 already sequences the article path before the bundle path; the minimal core
stops at 3.2.

Deferred: `jupyter-book` (2.2), `repo2data` (2.3), `mcp-scaffold` (2.4), and the whole agent-bundle
path (3.3-3.4).

The article path has a real first target: `paper/` is already a MyST project, so the first
executable article this harness produces should be its own paper.

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

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py` — 0 errors.
- [ ] 4.2 Neither planner still reads `delegates_to: [datalad]`.
- [ ] 4.3 Both e2e assertions gated to skip cleanly when MyST or a container runtime is absent.

## Removed from this change

The `manuscript` sub-agent decision (`docs/writing/SPEC.md`) was carried here as a section 4 and has
been removed. It is a question about the writing reference bundle, not about compendium build
mechanics, and `pin-doer-models` already owns the only part of it that blocks anything - the
symbolic `model: strong-writing` value that no allowed set would accept. Two changes owning one
decision is how a decision goes unmade.
