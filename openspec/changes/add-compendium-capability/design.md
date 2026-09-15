## Context

`disseminate/executable-article` and `disseminate/agent-bundle` are already written as planners —
they identify inputs, scaffold, wire figures to provenance, register a product, and save. What is
missing underneath is everything that turns a scaffold into something that builds.

`docs/writing/SPEC.md` specifies a `manuscript` sub-agent with a symbolic `model: strong-writing`
that was never built. It belongs to this cluster: the writing reference bundle it loads is the
authoring counterpart to the compendium's build machinery.

## Goals / Non-Goals

**Goals:**
- A produced executable article that actually builds, from the project's pinned container.
- An agent bundle that is loadable as tools and whose reproduction tests check recorded results.
- Resolve the `manuscript` sub-agent question — build it here or mark it explicitly deferred.

**Non-Goals:**
- Submitting to NeuroLibre. Producing a NeuroLibre-shaped artifact is in scope; their review process
  is not.
- Hosting the MCP server. Scaffolding it is in scope; deployment is `add-liab-capability`.
- Writing the science. `draft-manuscript` already draws the line at not inventing results.

## Decisions

- **The compendium doer builds; it does not author.** Figure content, narrative, and tool semantics
  come from the planner and the user. The doer runs MyST, wires `repo2data`, and emits MCP
  scaffolding.
- **Figures are wired to runs, not to files.** An executable article's figure must name the
  provenanced run that produced it, so the rebuild is checkable against the DataLad history rather
  than against a stale image on disk.
- **The agent bundle is emitted in the harness's own format** — SKILL.md plus a plugin manifest plus
  an MCP config. This dogfoods the format and means a published bundle is installable by the same
  installer that installs the harness.
- **Reproduction tests are part of the bundle, not optional.** A method bundle whose tools do not
  reproduce the paper's recorded results is a liability; the tests are what make it a research
  product rather than a code dump.
- **Build in the project's container.** An article that rebuilds only on the author's machine has not
  demonstrated anything.

## Risks / Trade-offs

- **This is the largest capability in the roadmap** and spans two quite different outputs. The
  one-step-deep principle argues for finishing the article path completely before starting the
  bundle path, even though they share a doer.
- **MyST and Jupyter Book overlap.** Supporting both risks two half-supported paths; the article
  requirements are written against the produced artifact rather than the generator to keep that
  choice open.
- **MCP scaffolding targets a moving spec.** The emitted config should be minimal and regenerable
  rather than elaborate.
- **Depends on the archive path.** `add-archive-toolbox` landed on 2026-09-15, but its deposit and
  relation paths have only been checked up to the credential gate. Until a sandbox deposit runs,
  the cross-linking step of a compendium cannot be exercised end to end.
