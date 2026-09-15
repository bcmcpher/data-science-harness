## Why

The living research compendium is the project's stated goal: a provenanced dataset, a re-executable
article, an agent-callable method bundle, and a self-hostable deployment, built from one DataLad
chain and cross-linked by DOI. Two of the four are `disseminate/executable-article` and
`disseminate/agent-bundle`, and both currently declare `delegates_to: [datalad]` — they can describe
a MyST tree or an MCP server and commit whatever the assistant wrote, and nothing more.

The tools they name have no implementation anywhere: `mcp` is mentioned 11 times across planner
bodies, `myst` 4, `repo2data` 3. This is the largest gap between what the harness claims and what it
can do, and it is the one that matters most, because a compendium that does not rebuild is just a
directory.

## What Changes

- A new `compendium` capability with a doer that owns executable-article and agent-bundle build
  mechanics.
- A `compendium-cli` toolbox: `myst`, `jupyter-book`, `repo2data`, and MCP-server scaffolding.
- `disseminate/executable-article` and `disseminate/agent-bundle` rewired to delegate.
- An e2e assertion: `executable-article` produces a buildable MyST tree from a released product.

## Capabilities

### New Capabilities
- `compendium`: build mechanics for executable articles and agent-callable method bundles — MyST and
  Jupyter Book projects, `repo2data` data fetching, and MCP server scaffolding.

### Modified Capabilities
- `disseminate`: `executable-article` and `agent-bundle` gain real delegation targets.

## Impact

- New: `plugins/compendium/`, `plugins/compendium-cli/`
- Modified: `plugins/disseminate/skills/executable-article/SKILL.md`,
  `plugins/disseminate/skills/agent-bundle/SKILL.md`, `.claude-plugin/marketplace.json`,
  `tests/e2e-smoke.sh`
- **Depended on `add-archive-toolbox`**, archived 2026-09-15: a compendium cross-links released,
  DOI'd products, so the archive path had to exist first. Its deposit paths have not yet been run
  against a live archive, so an end-to-end compendium test still needs a sandbox deposit.
