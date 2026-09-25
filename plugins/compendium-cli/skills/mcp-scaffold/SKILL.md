---
name: mcp-scaffold
description: >
  Auto-invoke when a project's provenanced analyses are to be emitted as an installable, agent-callable
  bundle — skill files, a plugin manifest and an MCP server registration in the harness's own format.
  Trigger on "scaffold the MCP server", "emit the agent bundle", "make these analyses callable",
  "generate the plugin manifest for the bundle", "Paper2Agent bundle", or /mcp-scaffold. Do NOT
  trigger for deciding which analyses should become tools, for writing analysis code, or for building
  an article (/myst, /jupyter-book).
argument-hint: '[check|scaffold|verify] [--dest <bundle-dir>] [--name <slug>] [--tool <script>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: mcp-scaffold

Write the files of an agent bundle — plugin manifest, one skill per tool, MCP server, reproduction
tests — in the harness's own universal format, and check the result against the harness's own lint.

**Read this before anything else: this skill writes the container, never the contents of a tool.**
Each tool wraps an analysis that already exists and has already run under provenance. The tool's
parameters are the script's real parameters, read out of its argument parser; its expected output is
the output a recorded run produced. Anything this skill cannot read from those two sources is asked
for, not inferred — a bundle is a claim that these methods are callable and reproduce, and a
parameter invented to make a signature look complete makes that claim false in a way no test catches
until someone calls it.

The layout is the harness's own, which is what makes it checkable. `plugins/compendium-cli/references/example-agent-bundle/`
is a minimal, lint-clean instance of exactly this shape; read it before writing one.

```
<bundle>/
├── .claude-plugin/marketplace.json     one entry, pointing at ./plugins/<slug>
├── plugins/<slug>/
│   ├── .claude-plugin/plugin.json      lists every skill below it
│   └── skills/<tool>/SKILL.md          one per extracted analysis
├── mcp/server.py                       exposes the tools over stdio MCP
├── .mcp.json                           server registration
└── tests/reproduce.py                  asserts each tool reproduces its recorded result
```

## Steps

1. **Check that the structural checker is available.**
   ```bash
   bash plugins/compendium-cli/scripts/check-tools.sh mcp-scaffold
   ```
   This tool wraps no external program; what it needs is `tests/lint-plugins.py` and PyYAML, because
   step 5 is the only thing that makes the format claim more than an assertion. Exit 1 → you may
   still write the bundle, but say plainly in the report that its structure was **not verified**.

2. **Read each candidate tool's real interface.** For every script named, read its argument parser
   and its declared inputs and outputs.
   ```bash
   sed -n '1,60p' code/<script>.py
   ```
   The tool's parameters are exactly the script's. If a parameter's type or meaning is not derivable
   from the parser or the data dictionary, ask. Do not widen a parameter to `str` to avoid asking.

3. **Emit the plugin and its skills.** Every emitted `SKILL.md` carries `name` equal to its directory,
   a `description` containing quoted trigger phrases and a "Do NOT trigger for …" clause,
   `plane: capability`, and `stamped:` letters — `[A, E]` for a tool that wraps a provenanced analysis
   and ships a reproduction test. Every skill directory is listed in the plugin manifest's `skills[]`;
   an unlisted skill never loads, and the lint treats it as an error.

4. **Emit the MCP server and the reproduction tests.** One test per tool, asserting the recorded
   result for that comparison — `derivatives/cmp-<slug>/` — is what the tool produces. A tool with no
   reproduction test does not go in the bundle.

5. **Check the emitted bundle with the harness's own lint, and report the result verbatim.**
   ```bash
   python3 tests/lint-plugins.py <bundle>        # expect: 0 errors
   ```
   This is the step that distinguishes "emitted in the harness format" from "emitted in something
   that resembles it". Fix every error it reports — a `name` that does not match its directory, a
   skill not listed in `skills[]`, an invalid `stamped:` letter — and run it again. **Do not report
   the bundle as emitted until there are zero errors**, and if the lint could not run, say that
   rather than implying it passed.

   One warning is expected and is not a defect in the bundle: the lint asks a marketplace description
   to state a planner count, which is a rule about *this repository's* own prose and has no meaning
   for a bundle that contains no planners. Report it as expected rather than silencing it by writing
   a count the bundle cannot support.

6. **Report.**
   ```
   op:        mcp-scaffold-<check|scaffold|verify>
   bundle:    <path>
   plugin:    <slug>
   tools:     <one line each: tool, the script it wraps, its parameters>
   tests:     <one per tool — a tool without one is not in the bundle>
   lint:      clean | <the errors, verbatim> | not run (<why>)
   result:    scaffolded | partial | failed | unavailable
   notes:     <what was not verified: that the server starts, that the tests pass>
   ```

## Constraints

- **Never write a tool's analysis logic.** The tool calls the existing script. If the script does not
  do what the tool should, that is a change to the analysis and it goes through
  `analyze/scaffold-analysis` and a recorded run, not through a bundle.
- **Never invent a parameter, a type or a default.** Read them from the script's argument parser and
  the data dictionary, or ask. An invented default is the worst case here: the tool runs, returns a
  plausible number, and nothing indicates it was not the analysis the paper described.
- **Never emit a tool without a reproduction test.** The bundle's claim is that these methods are
  re-runnable; a tool nobody can check against a recorded result is an assertion.
- **Never write a test that asserts the tool ran.** It asserts the tool reproduced the recorded
  output. A test that checks only for exit 0 passes over a tool that returns the wrong answer.
- **Never report the bundle as emitted in the harness format when the lint did not run or did not
  pass.** Say which. The format claim is the reason the bundle is structured this way at all.
- **Never claim the MCP server works.** Writing a server and starting one are different, and this
  skill does not start it.
- **Never expose a tool over an analysis that has no recorded run.** There is nothing for its test to
  assert against, and the bundle would present an unprovenanced result as a callable method.
- Do not commit. The planner owns `datalad save`.
