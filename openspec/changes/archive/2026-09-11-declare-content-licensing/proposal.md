## Why

The repository ships one MIT `LICENSE` at the root, covering everything. But the deliverable here is
mostly not code — it is Markdown: 42 `SKILL.md` files, 6 agents, the reference bundles, `docs/`, and
`paper/`. MIT is a software licence, and applying it to prose leaves a reuser guessing whether its
terms are meant to bind a document.

`paper/myst.yml` already resolves this correctly for one subtree, declaring
`license: {content: CC-BY-4.0, code: MIT}`. Nothing else in the repository does, and the root
`LICENSE` contradicts it by implication.

Two independent reasons to fix it:

- **STAMPED D.3**, which this repository distils and asks its users to follow, says each module
  SHOULD carry an explicit licence with a resolvable identifier (SPDX / REUSE). The repository does
  not currently comply with the principle it publishes.
- Open-licensing eligibility. Funders and archives increasingly require OSI-approved terms for
  software and CC BY or CC0 for other materials, stated separately. A single MIT file does not meet
  that as written.

## What Changes

- A `## License` section in the README stating the split, with SPDX identifiers.
- `LICENSE-CONTENT.md` carrying the CC BY 4.0 notice in the form Creative Commons specifies for
  marking a work, pointing at the canonical legal code.
- A `REUSE.toml` mapping paths to SPDX identifiers, so the split is machine-readable rather than
  only prose.
- `paper/myst.yml` left as it is — it is already correct, and it becomes the pattern rather than the
  exception.

## Capabilities

- `harness-distribution` — a new requirement covering how licensing travels with the content.

## Impact

No change to any skill, agent, or manifest. Nothing about how the harness installs or runs changes;
this is a statement about terms, not behaviour.
