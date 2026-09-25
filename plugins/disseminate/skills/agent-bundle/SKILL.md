---
name: agent-bundle
description: >
  Synthesize a Paper2Agent-style MCP server from the project's scripts + data dictionary, emitted in
  the harness's own SKILL.md + plugin.json + MCP config, with result-reproduction tests. Trigger on
  "agent bundle", "Paper2Agent", "make an MCP server", "expose the methods as tools", "agent-callable
  paper", "tool bundle". Produces an agent-bundle-kind living product that dogfoods the harness format.
plane: workflow
stamped: [A, E]
delegates_to: [compendium]
---

# Skill: agent-bundle

Turn the project's analysis code into an **agent-callable bundle**: the paper's methods become
parameterized, tested MCP tools an agent or person can invoke to reproduce or extend results
(Actionable), each backed by a reproduction test (Ephemerality — verifiably re-runnable). The bundle
is emitted in the harness's **own** `SKILL.md` + `plugin.json` + MCP format, so the project dogfoods
the structure it is built from. You delegate the emission to the **compendium doer**; ledger and
history reads, and the save, run directly, in the main thread.

Load `plugins/disseminate/references/paper2agent-bundle.md` for the bundle layout and mapping before
generating.

> 🔧 **Whether an analysis is worth exposing as a tool is yours and the author's.** A script that
> only ever made one figure is not a method anyone will call. The doer emits what it is told to;
> deciding the bundle's scope is this skill's job, and the author's.

## When to use
- A product's analyses are provenanced (`run-comparison` outputs exist) and the author wants them
  exposed as reusable, tested tools / an MCP server.
- Do NOT use to write the paper (`draft-manuscript`) or to build the reproducible article
  (`executable-article`) — this exposes the *methods as callable tools*.

## Steps
1. **Extract candidate tools** — from `code/` scripts and the `participants.json` data dictionary:
   each analysis becomes a parameterized tool (inputs = the script's real inputs, typed from the
   dictionary; outputs = the provenanced `derivatives/…`). List them and confirm scope with the user.
2. **Confirm each candidate has a recorded run behind it.** Delegate:
   > "for each of these comparisons, which run commit produced its outputs?"

   A comparison whose outputs have no producing run cannot go in the bundle: there is nothing for its
   reproduction test to assert against, and exposing it would present an unprovenanced result as a
   callable method. Report those and drop them from the scope rather than bundling them untested.
3. **Emit the bundle (compendium doer)** — delegate:
   > "scaffold an agent bundle at `agent-bundle/` for these tools: `<tool → script → recorded
   > result>`. Emit the plugin manifest, one skill per tool, the MCP server, its registration and a
   > reproduction test per tool, and check the result with the harness's lint."

   The doer's `mcp-scaffold` skill reads each script's real argument parser rather than inferring a
   signature, and runs `tests/lint-plugins.py` over what it wrote — a bundle that claims the
   harness's format without having been checked against it is an assertion. Relay the lint result as
   the doer reports it, including `not run`.
4. **Register + save** — add the bundle path to the product's `outputs[]` (or create an
   `agent-bundle`-kind product); save:
   ```bash
   datalad save -m "$(printf 'agent-bundle: synthesize <id>\n\nDSH-Op: agent-bundle\nDSH-Stage: disseminate\nDSH-Product: <id>')"
   ```
   Add a `DSH-Binding:` line copied from the compendium doer's report if it names one.
5. **Report** — the bundle path, the tools exposed and the comparison each reproduces, the lint
   result, any candidate dropped for having no recorded run, how to run the MCP server and the
   reproduction tests, and the next step: `link-outputs` to relate the bundle to the code
   (`IsDerivedFrom`) and paper (`IsSupplementTo`). **Say that the tests have not been run**, unless
   they have.

## Constraints
- Tools wrap *existing* provenanced analyses — do not invent new methods or change the science; a
  tool's output must match the recorded result (that is what the reproduction test asserts).
- Emit the harness's own `SKILL.md` + `plugin.json` + `.mcp.json` format (dogfooding) — do not
  invent a bespoke bundle format.
- Every tool ships a reproduction test; a bundle whose tools are not verifiably reproducible is not
  releasable. A test that asserts only that the tool ran is not a reproduction test — it passes over
  a tool returning the wrong answer.
- **Never bundle an analysis with no recorded run.** Report it and leave it out.
- **Never report the bundle as being in the harness format when the lint did not run or did not
  pass.** The format claim is the whole reason the bundle is shaped this way.
- **Never claim the bundle works.** Emitting a server is not starting one, and writing tests is not
  passing them. Say which of those has happened.
- Record the bundle under the product's `outputs[]`; keep the ledger schema-valid. Run DataLad
  yourself; delegate the bundle emission to the compendium doer.
