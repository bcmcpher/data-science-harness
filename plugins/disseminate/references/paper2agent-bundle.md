# Paper2Agent agent bundle (reference)

A Paper2Agent-style bundle turns a project's analysis code into an **agent-callable MCP server**:
the paper's methods become parameterized, tested tools an agent (or a person) can invoke to
reproduce or extend results. This harness emits the bundle in **its own universal format** — a
`SKILL.md` + `plugin.json` + MCP config — so the project dogfoods the same skill/plugin structure it
is built from.

```
<bundle>/
├── .claude-plugin/plugin.json   # declares the bundle's skills + mcpServers
├── skills/<tool>/SKILL.md       # one skill per extracted analysis tool (parameterized)
├── mcp/server.py                # MCP server exposing the tools (stdio)
├── .mcp.json                    # MCP server registration
└── tests/reproduce.py           # result-reproduction tests (assert known outputs)
```

## How it maps to the harness
- **Tools** are extracted from the project's `code/` scripts + the `participants.json` data
  dictionary: each becomes a parameterized tool (inputs = the script's real inputs, typed from the
  dictionary) exposed over MCP (Actionable).
- **Reproduction tests** assert each tool reproduces the provenanced result recorded by
  `run-comparison` (`derivatives/cmp-<slug>/`), so the bundle is verifiably re-executable
  (Ephemerality).
- Emitting `SKILL.md` + `plugin.json` + `.mcp.json` means the bundle is installable exactly like the
  harness's own plugins — the format is uniform.
- Register the bundle as an `agent-bundle`-kind product; it typically relates to the code
  (`IsDerivedFrom`) and the paper (`IsSupplementTo`) via `link-outputs`.

Canonical sources: Paper2Agent, Model Context Protocol (MCP).
