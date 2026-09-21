# Paper2Agent agent bundle (reference)

A Paper2Agent-style bundle turns a project's analysis code into an **agent-callable MCP server**:
the paper's methods become parameterized, tested tools an agent (or a person) can invoke to
reproduce or extend results. This harness emits the bundle in **its own universal format** — a
`SKILL.md` + `plugin.json` + MCP config — so the project dogfoods the same skill/plugin structure it
is built from.

The bundle is a **mini-marketplace**, not a bare plugin directory. The marketplace manifest is what
lets `python3 tests/lint-plugins.py <bundle>` resolve a plugin at all: the lint walks
`<root>/plugins/*/` and errors when `<root>/.claude-plugin/marketplace.json` is absent. A flat
bundle cannot be checked against the format it claims to be in.

```
<bundle>/
├── .claude-plugin/marketplace.json   # one entry, pointing at ./plugins/<slug>
├── plugins/<slug>/
│   ├── .claude-plugin/plugin.json    # lists every skill below it
│   └── skills/<tool>/SKILL.md        # one skill per extracted analysis tool (parameterized)
├── mcp/server.py                     # MCP server exposing the tools (stdio)
├── .mcp.json                         # MCP server registration
└── tests/reproduce.py                # result-reproduction tests (assert known outputs)
```

`plugins/compendium-cli/references/example-agent-bundle/` is a minimal, lint-clean instance of
exactly this shape. Read it before generating one.

## What an emitted skill must carry

- **`plane: capability` and `stamped: [A, E]`.** The lint's `is_harness` test is
  `not plugin_name.endswith("-cli")`, so a bundle's plugin is held to the full harness rules rather
  than the relaxed toolbox ones — a missing `plane` warns and an invalid one errors.
- **No `delegates_to`.** The lint resolves every delegation target against the lint root's
  `plugins/` tree. A standalone bundle contains no doers, so any entry there is an error — and a
  bundle's tools call the MCP server, not a harness agent.
- A `description` carrying quoted trigger phrases, and the three body sections `## When to use`,
  `## Steps`, `## Constraints`.

Lint the bundle **without** `--strict`, expecting 0 errors and exactly one warning: the lint asks a
marketplace description to state a planner count, which is a rule about this repository's prose and
meaningless for a bundle that has no planners. Report that warning rather than silencing it.

## How it maps to the harness
- **Tools** are extracted from the project's `code/` scripts + the `participants.json` data
  dictionary: each becomes a parameterized tool (inputs = the script's real inputs, typed from the
  dictionary) exposed over MCP (Actionable).
- **Reproduction tests** assert each tool reproduces the provenanced result recorded by
  `run-comparison` (`derivatives/cmp-<slug>/`), so the bundle is verifiably re-executable
  (Ephemerality).
- Emitting `marketplace.json` + `plugin.json` + `SKILL.md` + `.mcp.json` means the bundle is
  installable by `bin/install.sh` exactly like the harness's own plugins — the format is uniform.
- Register the bundle as an `agent-bundle`-kind product; it typically relates to the code
  (`IsDerivedFrom`) and the paper (`IsSupplementTo`) via `link-outputs`.

Canonical sources: Paper2Agent, Model Context Protocol (MCP).
