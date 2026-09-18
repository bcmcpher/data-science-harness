## Status

Section 0's minimal working core shipped 2026-09-17: the doer, `myst` alone, and
`executable-article` rewired and building. Sections 2.2-2.4 and 3.3-3.4 remain, so this change
stays open.

## 0. Minimal working core

The doer (1.1-1.3) plus **`myst` alone** (2.1, 2.5), with `executable-article` rewired and building
(3.1-3.2). Section 3 already sequences the article path before the bundle path; the minimal core
stops at 3.2.

Deferred: `jupyter-book` (2.2), `repo2data` (2.3), `mcp-scaffold` (2.4), and the whole agent-bundle
path (3.3-3.4).

The article path has a real first target: `paper/` is already a MyST project, so the first
executable article this harness produces should be its own paper.

## 1. The compendium doer

- [x] 1.1 Write `plugins/compendium/agents/compendium-doer.md`: parse request, check dependencies,
      scaffold, build in the project container, report. No `model:` — it produces artifacts in the
      dataset, and `skill-format` forbids pinning an agent that mutates one.
- [x] 1.2 State the two refusal rules: no unprovenanced figure embedded silently, no partial artifact
      presented as complete. A third was needed and added: **never build on the host and report it as
      pinned.** With no registered container the doer stops and reports `unpinned (build not run)`,
      or builds on request with the label `unpinned (built on host, on request)` carried into the
      report. An unpinned build reported as success is a false claim about Portability, which is one
      of the two STAMPED letters this capability exists to advance.
- [x] 1.3 `plugins/compendium/.claude-plugin/plugin.json`.

## 2. The compendium-cli toolbox

- [x] 2.1 `plugins/compendium-cli/skills/myst/SKILL.md`.
- [ ] 2.2 `plugins/compendium-cli/skills/jupyter-book/SKILL.md`.
- [ ] 2.3 `plugins/compendium-cli/skills/repo2data/SKILL.md`.
- [ ] 2.4 `plugins/compendium-cli/skills/mcp-scaffold/SKILL.md` — emit skill files, plugin manifest,
      and MCP config in the harness's universal format.
- [x] 2.5 `plugins/compendium-cli/.claude-plugin/plugin.json` and marketplace entries for both plugins.
- [x] 2.6 **Added during implementation:** `plugins/compendium-cli/scripts/check-tools.sh`, the
      offline gate. Two properties the annotate and archive gates did not need:
      (a) it takes `--project <dir>`, because a `package.json`-declared `mystmd` lives at
      `<project>/node_modules/.bin/myst` and a bare relative check would answer differently
      depending on the caller's working directory; (b) it verifies the binary **runs**, not merely
      that it exists — `mystmd` needs Node >= 20.19, and a present binary next to an older Node dies
      with a `SyntaxError` on first use. Presence-only would report `available` and hand the doer a
      build that fails mid-step. A request for `jupyter-book`, `repo2data` or `mcp-scaffold` is exit
      2, not `unavailable`: those have no skill, and `unavailable` would promise an invocation path
      that does not exist.

## 3. Finish the article path before starting the bundle path

- [x] 3.1 Rewire `plugins/disseminate/skills/executable-article/SKILL.md` to
      `delegates_to: [compendium, datalad]`, with prose naming the doer. The planner now carries the
      doer's `unprovenanced:` list and pinned/unpinned result into its own report instead of
      smoothing them over, and is told not to run `myst` itself.
- [x] 3.2 e2e assertion: a scaffolded MyST project builds. Nine assertions. What it deliberately
      does **not** assert is reproducibility — a MyST project whose figures are committed images
      builds perfectly and reproduces nothing, so figure provenance stays the doer's check rather
      than a property of a green build. The build is asserted rather than `step`-ed, so a failure
      reports instead of aborting the suite.
- [ ] 3.3 Only then rewire `plugins/disseminate/skills/agent-bundle/SKILL.md`.
- [ ] 3.4 e2e assertion: an emitted bundle passes `tests/lint-plugins.py`'s structural checks.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 19 plugins, 52 skills,
      8 agents.
- [ ] 4.2 Neither planner still reads `delegates_to: [datalad]`. **Half done:**
      `executable-article` is rewired; `agent-bundle` is not, because its MCP-scaffold skill (2.4) is
      deferred. Rewiring it now would point a planner at a capability that cannot serve it.
- [x] 4.3 The MyST block skips cleanly, and the skip **quotes the gate's own reason** rather than
      assuming "not installed": present-but-unrunnable and absent are different problems with
      different fixes. Verified by running the suite with an old Node on PATH — it skips with the
      Node-version hint and the suite still exits 0.
- [x] 4.4 **Added:** the `disseminate-article` routing fixture updated to
      `[compendium, datalad]`, caught by `tests/check-bench-fixtures.py` in the same pass rather
      than two changes later.

## Removed from this change

The `manuscript` sub-agent decision (`docs/writing/SPEC.md`) was carried here as a section 4 and has
been removed. It is a question about the writing reference bundle, not about compendium build
mechanics, and `pin-doer-models` owned the only part of it that blocked anything - the
symbolic `model: strong-writing` value that no allowed set would accept. That change (archived
2026-09-15) made it a commented placeholder, because a writing agent is not pinnable. Two changes
owning one decision is how a decision goes unmade.
