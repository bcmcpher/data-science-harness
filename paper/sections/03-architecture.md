# Architecture

<!--
SKELETON.

RULE FOR THIS SECTION: every claim about what the harness does must be checkable against
openspec/specs/. If a spec does not cover it, either it is not built or the spec is missing — in
both cases, do not claim it here. The README's own documentation-versus-disk drift
(openspec/changes/reconcile-docs-with-disk) is the failure mode this rule exists to prevent.

Pull the real counts from the repository when drafting. Do not write them from memory.
-->

## Two planes

<!--
openspec/specs/skill-format

Capability plane: thin, tool-scoped wrappers over one external tool each. A capability wraps a tool
and holds no research-process logic.

Workflow plane: tool-agnostic research process in research vocabulary. A workflow skill never calls
a CLI directly; it invokes capabilities.

This split is STAMPED Modularity applied to the harness itself. The payoff is concrete and worth
stating as such: capabilities recombine under different workflows, and a workflow can swap one
capability for another — Zenodo for OSF — without rewriting the process.

Figure 1: the two planes with the delegation edges. Generate from the repository (each planner's
declared delegates_to) rather than drawing by hand, so the figure cannot drift from the code.
-->

## The planner/doer contract

<!--
openspec/specs/skill-format

A PLANNER holds research-process logic and does not call CLIs. A DOER is a subagent owning tool
mechanics; doers are the only things that run tools. Delegation is expressed twice — as a
frontmatter list and as prose — so it survives translation to harnesses without frontmatter.

The mechanically checkable part is the contribution worth emphasising: tests/lint-plugins.py errors
when a declared delegation names a plugin that provides no agent, and when prose and frontmatter
disagree in either direction. A contract that is only a convention decays; this one fails a check.

Figure 2 or a table: what the lint enforces. Derive from openspec/specs/skill-format.
-->

## One provenance chain

<!--
openspec/specs/datalad

Every computation through `datalad run` / `container-run`; every administrative change
`datalad save`-d. The consequence to state: the analysis record and the administrative record cannot
diverge, because they are the same history.

Doer refusal rules are part of the design, not implementation detail — no run on a dirty tree, no
`container-run` against an unregistered container, no empty commit message, no research decisions
made by the doer. Each one exists to prevent a specific way the chain breaks silently.

Mention the containers/datalad boundary as an example of the modularity argument paying off: the
containers capability builds the image, the datalad capability registers and runs it, so provenance
has exactly one owner.
-->

## The project ledger

<!--
openspec/specs/project-ledger

project.yaml at the dataset root, versioned like any other artifact. Closed schema
(additionalProperties: false), validated by schemas/validate-ledger.py.

Keys: project, products, obligations, contributors, log. Append-only log; corrections are new
entries.

The argument: administration is a continuous track the pipeline runs inside — the Manage & Comply
lane — not a stage. Funding, ethics, obligations, and credit get the same provenance discipline as
the science.

Connect to @botes2026lawinsidemachine here: obligations[] is where terms carried forward would live.
Be explicit that consent scope and use restrictions are NOT currently in the schema. That is the
honest version and it is also the more interesting one — it names the next piece of work.
-->

## Comparisons and products

<!--
openspec/specs/analyze

Real papers are a series of small analyses introduced in unpredictable order, not a rigid pipeline.
A comparison is one addable unit: a DataLad branch plus a provenanced run.

The rigor spectrum is the design idea worth the space:
  - Exploratory: zero ledger footprint (STAMPED Ephemerality). Explore freely, prune what does not
    tell the story. Touches the ledger only if promoted.
  - Confirmatory: spec frozen and registered before execution, recorded as a ledger obligation,
    checked against the frozen spec on completion.

Same schema, one spectrum; the confirmatory mode adds freeze-first and an obligation. A set of
pre-registered comparisons is therefore just a to-do list of confirmatory obligations.

Compare explicitly to Brain Researcher's commitment cards — theirs is the sharper mechanism, and
saying so here costs nothing.
-->

## The living compendium

<!--
openspec/specs/disseminate

Four coupled artifacts from one provenance chain, cross-linked by DataCite relations:
  1. provenanced dataset (versioned, DOI-tagged)
  2. re-executable article (NeuroLibre-style)
  3. agent-callable method bundle (Paper2Agent-style, emitted in the harness's own format)
  4. self-hostable deployment (Lab-in-a-Box-style)

The coupling is the claim, not any individual artifact.

BE HONEST ABOUT BUILD STATE. Several of these planners currently have no capability beneath them —
they can describe the output and commit it, and nothing more. Point at openspec/changes/ for what is
proposed. A reader who installs this and finds an executable article that does not build will not
forgive an overstated architecture section, and there is no reason to risk it.
-->

## Portability

<!--
openspec/specs/harness-distribution

Content authored once in a Claude Code-compatible layout; bin/install.sh translates at install time
(OpenCode: drop name/tools, insert mode: subagent). Harness-specific variants are never committed.

Short subsection. It matters for adoption and is not the paper's argument.
-->
