## Status

Complete. Section 0's minimal working core shipped 2026-09-17 (the doer, `myst` alone, and
`executable-article` rewired and building). The remainder — `jupyter-book`, `repo2data`,
`mcp-scaffold`, the `agent-bundle` rewire and the bundle-lint assertion — shipped 2026-09-18, and
the closing pass on 2026-09-21 fixed three places where prose still described the world before it.

## 0. Minimal working core

The doer (1.1-1.3) plus **`myst` alone** (2.1, 2.5), with `executable-article` rewired and building
(3.1-3.2). Section 3 already sequences the article path before the bundle path; the minimal core
stops at 3.2.

Deferred at that point, and landed on 2026-09-18: `jupyter-book` (2.2), `repo2data` (2.3),
`mcp-scaffold` (2.4), and the agent-bundle path (3.3-3.4).

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
- [x] 2.2 `plugins/compendium-cli/skills/jupyter-book/SKILL.md`. It establishes which major version
      the **project** is configured for, not merely which tool is installed: Jupyter Book 2 *is*
      mystmd reading `myst.yml`, v1 is Sphinx-based reading `_config.yml`, and a procedure written
      for one fails on the other in ways that read as a broken project. Two refusals: it will not
      migrate a project between major versions to make a build pass, and it will not report `built`
      when notebooks failed to execute — JB renders the traceback into the page and exits 0, so a
      reader otherwise gets a finished-looking book with a stack trace in it.
- [x] 2.3 `plugins/compendium-cli/skills/repo2data/SKILL.md`. It **constructs** the fetch and hands
      it to the datalad doer rather than downloading. A fetch is not provenance: repo2data records
      nothing about having run, so data that arrives this way and is then analysed produces results
      whose inputs cannot be traced. It also refuses when DataLad already tracks the destination,
      where `datalad get` restores the same bytes with their history attached.
- [x] 2.4 `plugins/compendium-cli/skills/mcp-scaffold/SKILL.md` — emit skill files, plugin manifest,
      and MCP config in the harness's universal format. It writes the bundle's **container**, never a
      tool's logic, and reads parameters out of each script's real argument parser: an invented
      default is the worst failure here, because the tool then runs and returns a plausible number.
      Step 5 runs the harness's own lint over what it emitted, which is what separates "emitted in
      the harness format" from "emitted in something that resembles it".

      The emitted shape is a **mini-marketplace** — `.claude-plugin/marketplace.json` +
      `plugins/<slug>/` — rather than a bare plugin directory, because `tests/lint-plugins.py` walks
      `<root>/plugins/*/` and errors without the marketplace manifest. A flat bundle cannot be
      checked against the format it claims. `plugins/compendium-cli/references/example-agent-bundle/`
      is a lint-clean instance of that shape, added here as the thing an emitter reads first.
- [x] 2.5 `plugins/compendium-cli/.claude-plugin/plugin.json` and marketplace entries for both plugins.
- [x] 2.6 **Added during implementation:** `plugins/compendium-cli/scripts/check-tools.sh`, the
      offline gate. Two properties the annotate and archive gates did not need:
      (a) it takes `--project <dir>`, because a `package.json`-declared `mystmd` lives at
      `<project>/node_modules/.bin/myst` and a bare relative check would answer differently
      depending on the caller's working directory; (b) it verifies the binary **runs**, not merely
      that it exists — `mystmd` needs Node >= 20.19, and a present binary next to an older Node dies
      with a `SyntaxError` on first use. Presence-only would report `available` and hand the doer a
      build that fails mid-step. At the time it was written, a request for `jupyter-book`,
      `repo2data` or `mcp-scaffold` was exit 2 rather than `unavailable`, because those had no skill
      and `unavailable` would have promised an invocation path that did not exist. 2.2-2.4 filled
      that, and the script gained a real arm for each; only an unknown tool is exit 2 now.
      `mcp-scaffold` wraps no external program, so its arm gates on `tests/lint-plugins.py` **and**
      PyYAML — without PyYAML the lint exits 2, which reads as a skip, so an unchecked bundle would
      look checked.

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
- [x] 3.3 Rewire `plugins/disseminate/skills/agent-bundle/SKILL.md` — now
      `delegates_to: [compendium, datalad]`, with a step that **drops any candidate analysis having
      no recorded run** rather than bundling it untested, and constraints against claiming the bundle
      works: emitting a server is not starting one, and writing tests is not passing them.
      `tests/check-bench-fixtures.py` failed the moment the planner was rewired, which is the signal
      working as designed; `bench/tasks/routing-lifecycle.yaml`'s `disseminate-bundle` ground truth
      moved to `[compendium, datalad]` in the same change rather than a later one.
- [x] 3.4 e2e assertion: a bundle passes `tests/lint-plugins.py`'s structural checks. **What is
      asserted is the reference bundle, not an emitted one** — nothing in this repo emits a bundle,
      so what is mechanically checkable is that the documented layout, instantiated once, passes the
      harness's own lint. The lint needed no change: `main()` already takes a `repo_root` positional,
      `check_doc_claims` returns early without a `README.md`, and `check_script_imports` returns
      early without a `pyproject.toml`.

      The bundle is linted **without** `--strict`, expecting 0 errors and exactly one warning. That
      asymmetry with 4.1's `--strict` run is deliberate: the lint asks a marketplace description to
      state a planner count, which is a rule about *this repository's* prose and meaningless for a
      bundle containing no planners. `mcp-scaffold` says so explicitly rather than silencing it by
      writing a count the bundle cannot support.

      The e2e loop that asserted these three tools were *unbuilt* was deleted rather than updated. It
      asserted the absence 2.2-2.4 fill, and a stale assertion that still passes is worse than a
      failing one.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 21 plugins, 74 skills,
      9 agents. (The counts recorded here when 4.1 was first checked — 19/52/8 — were this change's
      own starting state, four archived changes ago.)
- [x] 4.2 Neither planner still reads `delegates_to: [datalad]`. Both now read
      `[compendium, datalad]`, and `tests/check-bench-fixtures.py` is clean at 42 tasks, so the
      routing ground truth moved with them.
- [x] 4.3 The MyST block skips cleanly, and the skip **quotes the gate's own reason** rather than
      assuming "not installed": present-but-unrunnable and absent are different problems with
      different fixes. Verified by running the suite with an old Node on PATH — it skips with the
      Node-version hint and the suite still exits 0.
- [x] 4.4 **Added:** the `disseminate-article` routing fixture updated to
      `[compendium, datalad]`, caught by `tests/check-bench-fixtures.py` in the same pass rather
      than two changes later. `disseminate-bundle` followed in 3.3 for the same reason.
- [x] 4.5 **Added during the closing pass.** Three documents still described the world before
      2.2-2.4 landed, and none of them is reachable by the lint — which is exactly why they drifted:
      - `plugins/compendium/agents/compendium-doer.md` listed only `myst` in its toolbox table and
        instructed the doer to say the other three are **not built** and refuse them. `agent-bundle`
        delegates bundle emission to that doer, so the 3.3 rewire pointed a planner at an agent
        told to refuse the request. The table now carries all four skills and a bundle path.
      - `plugins/disseminate/references/paper2agent-bundle.md` documented a **flat** bundle layout
        with no marketplace manifest — a layout that cannot pass the lint `agent-bundle`'s own Step 3
        demands, and `agent-bundle` tells the planner to read it *before generating*.
      - `.claude-plugin/marketplace.json`'s `compendium-cli` entry described MyST only, while the
        plugin manifest beside it had been rewritten for all four skills.

      **The limit of what any of this verifies: no network path and no emission path is exercised.**
      Nothing in the repo emits a bundle, no MyST build ran on this machine, and no MCP server was
      started. A green suite is evidence about the gates and about the reference bundle's shape.
      Nothing here establishes that a bundle emitted from a real project reproduces anything.

## Removed from this change

The `manuscript` sub-agent decision (`docs/writing/SPEC.md`) was carried here as a section 4 and has
been removed. It is a question about the writing reference bundle, not about compendium build
mechanics, and `pin-doer-models` owned the only part of it that blocked anything - the
symbolic `model: strong-writing` value that no allowed set would accept. That change (archived
2026-09-15) made it a commented placeholder, because a writing agent is not pinnable. Two changes
owning one decision is how a decision goes unmade.
