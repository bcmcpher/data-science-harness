# Why this exists

> **Status: the workflow plane is built, the capability plane is uneven, and nothing has been
> measured.** Six workflow plugins and 67 skills are on disk and structurally checked. Beneath them,
> `datalad` has a 19-skill toolbox, `annotate` a 4-skill one, `archive` a 3-skill one, and `bids`,
> `compendium` and `liab` a 1-skill one each, while `containers` has none, so a planner can express
> a step it cannot fully perform. The evaluation protocol in
> [`evaluation.md`](evaluation.md) is specified and **no probe has been run**; no number anywhere in
> this repository comes from a measurement. When that changes, this banner is the first thing to
> update.

This is the canonical statement of what the harness is for. [`README.md`](../README.md) describes how
it is built and how to use it; [`paper/`](../paper) argues the case for an outside reader. Where any
of them appear to disagree, this document is the one that is right.

---

## The problem

Assistants can now execute analyses faster than the surrounding record can be maintained by hand. A
result exists before anything records how it came to be; the administrative context around it —
funding, ethics scope, consent terms, obligations, credit — was already the part most likely to be
reconstructed after the fact, and acceleration makes that worse. The record does not just lag, it
stops being recoverable. And what governance there is does not travel: as
[Botes (2026)](https://biolawgic.substack.com/p/the-law-inside-the-machine-building) puts it,
technically portable data are not necessarily *governably reusable* data.

Existing AI assistant configurations do not answer this, because they were built for a different end
goal. They are designed for software products — ship a package, cut a release, deploy a service.
Academic data science publishes a **research product**, and a research product is no longer a static
PDF or a frozen dataset. It is a dataset someone can retrieve, an article that regenerates its own
figures, methods another researcher's agent can call, and infrastructure a lab can host itself. A
configuration that optimizes for shipping software produces none of that, and none of the record that
makes it trustworthy.

The third form of the problem is the one that prompted the work. The author runs a help desk for a
cohort of postdocs working at the intersection of AI and neuroscience. A help desk is precisely the
situation where answering questions does not scale: the knowledge about which tool to reach for,
in what order, under what constraints, has to leave one person's head and become something a
researcher can route through directly. That is the same move the harness makes internally — judgment
externalized into reviewable prose an agent must pass through, rather than left implicit in a context
window. The harness is what the help desk turns into when it is written down.

## Who this is for

An early-career researcher doing data-intensive work, most concretely in neuroimaging, who needs to
produce a defensible research record and does not want to assemble the tooling to do it from scratch.
They are reached two ways: directly, through the help desk and the training described under
[Practice](#practice), and indirectly, by installing the harness and letting it carry the practices
the help desk would otherwise have to teach.

Contributors are a second audience, and the format is chosen for them: all content is Markdown and
YAML, and extending the harness does not require writing Python.

## Why the obvious fixes are insufficient

Each of the available answers is good at something, and none of them closes this gap.

- **Reproducibility checklists** are applied at the end, to an artifact whose history is already
  lost. They describe what a good record would contain; they do not cause one to exist.
- **Provenance tooling** — DataLad, containers, workflow engines — is necessary and not sufficient.
  It records *what was run*. It does not record why, under what commitments, or who is accountable
  for the result.
- **Agentic harnesses that enforce analytic rigor**, such as
  [Brain Researcher](https://arxiv.org/abs/2608.19902), govern the reasoning inside one analysis.
  They do not produce the durable lifecycle record those judgements should attach to. See
  [Positioning](#positioning) — this one overlaps in scope and the distinction has to be earned
  rather than asserted.
- **Reporting guidelines** (EQUATOR, COBIDAS) describe the destination, not the path.

> The claim that provenance and administrative context degrade under acceleration is asserted from
> practice, not measured. It is the premise the work rests on, and it is stated here as a premise.
> The [evaluation protocol](evaluation.md) measures whether the harness *helps*, not whether the
> problem is real.

## The design commitment

**Governance should be a by-product of doing the work.**

That is a statement about mechanism, and it is the reason for every structural decision that follows.
Anything that requires a separate act of discipline gets skipped under deadline — not through
carelessness, but because the deadline is real and the discipline is not enforced by anything. So the
record is not produced by remembering to produce it. Every computation goes through `datalad run`;
every administrative change is `datalad save`-d; the export format that regenerates itself is the
default rather than an extra step.

What this delivers is administration treated as first-class rather than as an afterthought: funding,
ethics, data-management plans, deadlines, people and credit tracked alongside the science, with the
same provenance discipline applied to both. That is the outcome. The by-product commitment is how it
is reached.

## Principles

The harness indexes into **STAMPED** ([Macdonald et al., 2026](https://stamped-principles.org)) — a
vocabulary for the operational maturity of a *research object*, the data, code, environment and
metadata that together make research a complete, re-runnable unit. Seven properties: Self-containment,
Tracking, Actionability, Modularity, Portability, Ephemerality, Distributability. Each is a spectrum
rather than a pass/fail gate, and [`stamped.md`](stamped.md) carries the normative requirements.

STAMPED is not decoration here; it is load-bearing in four specific places:

- **Modularity justifies the two-plane split.** STAMPED calls for separating analysis code, input
  data, environments, licenses and results. The harness applies the same separation to itself.
- **Specification-centric research objects ground pre-registration.** The durable object is the
  *specification*; the running code is ephemeral, rebuilt from spec. That generalizes
  pre-registration rather than bolting it on.
- **AI-era tracking fits an agent-driven harness.** Agent actions are recorded by wrapping the
  invocation in a provenance command that captures model, prompt and resulting changes.
- **Assessment is a skill, not a report.** `govern/stamped-assess` scores a research object against
  the checklist as part of the workflow.

Every skill declares which letters it advances, and the structural lint validates those letters
against the closed set — so the framework cannot quietly drift into a vocabulary of convenience.

## Architecture

Two planes, and one rule joining them.

| Plane | What lives here | Rule |
|---|---|---|
| **Capability** (technical) | Thin wrappers over one external tool each — DataLad, Nipoppy, BIDS, containers, archives. Mechanical, reusable STAMPED primitives. | A capability holds tool mechanics and no research-process logic. |
| **Workflow** (conceptual) | Tool-agnostic research process in research vocabulary — govern, initialize, curate, analyze, process, disseminate. | A workflow skill never calls a CLI directly. It delegates to a capability. |

This is STAMPED Modularity applied to the harness itself, and it buys two things: capabilities
recombine under different workflows, and a workflow can swap one capability for another — Zenodo for
OSF — without rewriting the process.

It also makes the research judgment *inspectable*. A planner skill must carry `## When to use`,
`## Steps` and `## Constraints` — human-authored process judgment, enforced by the structural lint —
while tool mechanics are quarantined below. The contract fails a check rather than decaying into
convention.

Around both planes runs the rest of the design: a single DataLad provenance chain from raw data to
published result, a versioned [project ledger](project-ledger.md) carrying products, obligations and
credit as schema-validated entries, and a **living compendium** as the default export — a provenanced
dataset, a re-executable article, an agent-callable method bundle and a self-hostable deployment,
built from that one chain and cross-linked by persistent identifier. The contribution there is the
*coupling*, not any one of the four; each already has a good answer, and they are not currently
produced from a common chain.

## What it claims, and how you would know

The harness claims that an assistant working inside it produces research artifacts that are **better
governed** than one working without it — reachable through a provenance chain, described by a complete
ledger, re-executable by a third party — at an acceptable cost, and that it **routes work to the right
tool more often**.

That decomposes into four independent measurements, each with a declared control, because a probe
that cannot state its control measures nothing:

| Probe | Question | What would falsify it |
|---|---|---|
| `routing` | Does the model reach the right planner and delegate to the right doer? | Harness-off baseline routes as well, or better |
| `provenance` | Is the produced artifact reachable, described and complete? | Ledgers validate but the chain has gaps a third party hits |
| `reproducibility` | Can a third party rebuild it from scratch and get the same result? | Rebuild needs undocumented manual interventions |
| `cost` | What does it cost in tokens, time and human interventions? | The governance gain is real but priced out of ordinary use |

Two properties of the design matter more than the results will: routing ground truth is **derived
mechanically** from each skill's `delegates_to` field rather than hand-labelled or model-generated,
and a probe whose required capability is absent is **skipped with a stated reason**, never reported as
a zero. Both exist to keep the evaluation from validating itself.

**None of these has been run.** The protocol was written before the capabilities it measures,
deliberately — an evaluation designed after the fact tends to measure whatever was convenient to
build.

## Positioning

**[Brain Researcher](https://arxiv.org/abs/2608.19902) (Chen et al., 2026)** is not adjacent work.
Its authors describe it as an agentic research harness operating in a neuroimaging researcher's
computational environment, which is the same phrase for a system in the same field. It seals
commitment cards — question, admissible specifications, success criteria — by content hash before
execution; it runs a version-pinned tool registry and a large knowledge graph; and its review layer
adjudicates claims as accepted, qualified, revised, blocked, rejected or deferred. It reports
substantial gains in tool-selection accuracy and in verifiable grounding.

The distinction is scope. **Brain Researcher governs analytic rigor within a single analysis. This
harness governs the lifecycle around analyses.** The interface between them is concrete: their review
layer adjudicates claims but does not produce the durable, versioned provenance record those verdicts
should attach to, and this harness produces exactly that record and has no claim-adjudication layer.
A verdict is only as useful as the artifact it binds to; an artifact is only as useful as the
judgement recorded about it.

Three places this work is behind, stated because they are true and because noticing costs nothing:
their tool registry is machine-readable and rich where our `delegates_to` is a list of plugin names,
and much of their routing improvement plausibly comes from that richness; they have run a benchmark
and we have specified one; and their commitment cards are a sharper mechanism than our frozen spec
plus ledger obligation, with no multiverse capability on our side at all.

**[Botes (2026)](https://biolawgic.substack.com/p/the-law-inside-the-machine-building)** supplies the
argument for why this matters beyond tidiness: governance has to be designed into infrastructure
rather than retrofitted, because agent-speed querying, consent obsolescence, re-identification through
combination, and cross-border conflict each break an assumption that human-scale review rested on.
Two things carry over carefully. It is a perspective piece operating at the level of federated
repositories and national frameworks, and a project-level tool cannot deliver most of what it asks
for — the claim here is the narrow one, that a durable, versioned, portable project-level governance
record is a *precondition* for the larger thing, not the larger thing. And machine-*readable* consent
is not machine-*decided* consent: the harness records terms, and does not decide them.

**Provenance and pipeline tooling** — DataLad, BIDS, Nipoppy, Neurobagel — are capabilities the
harness wraps, not approaches it competes with. The contribution is not new provenance machinery. It
is that the machinery is invoked by default by the process layer instead of being remembered by the
researcher.

## Scope

The work is **neuroimaging-first**. BIDS, Nipoppy, fMRIPrep, MRIQC, COBIDAS, Neurobagel and OHBM run
through the concrete surface of every plugin, and the practice it comes from is neuroimaging practice.
The architecture is not domain-specific and the workflow vocabulary is general, but the evidence,
the integrations and the worked examples are from one field. Read claims about "academic data
science" with that in mind.

## What is built, and what is not

| | State |
|---|---|
| Workflow plane | **Built.** Six plugins — `project`, `govern`, `curate`, `analyze`, `process`, `disseminate` — and the 37 planner skills beneath them, structurally checked. One, `analyze/literature-search`, is deliberately unbuilt. |
| Capability plane | **Uneven.** `datalad` has a 19-skill toolbox; `nipoppy` has one; `annotate` has one skill per backend (Neurobagel, NIDM, ReproSchema, SNOMED), most of which validate terms rather than find them; `archive` has one per backend (OSF, Zenodo, DataCite); `bids` has one wrapping whichever validator distribution is installed; `compendium` has one wrapping MyST, which the end-to-end test actually builds with; `liab` has one wrapping pyinfra, whose plan path the test exercises when pyinfra is installed and whose apply path is exercised only by hand, because testing it needs a disposable host. None of the annotate, archive or BIDS paths has been run live, because none of those tools is installed. `containers` still has a doer and no toolbox. A planner above them can express a step and perform only the parts those toolboxes cover. |
| Ledger | **Built.** Schema-validated, with a worked example. |
| Living compendium | **Designed, partly built.** The four artifacts are specified; the coupling is not complete. |
| Portability | **Designed for six harnesses, exercised on two.** The installer supports Claude Code and OpenCode. |
| Evaluation | **Specified, unrun.** Four probes, fixtures in `bench/`, CI-validated, no results. The runner is not built here: [`wikiskill`](https://github.com/bcmcpher/wikiskill) reads these fixtures in place, and nothing has been executed through it either. |

Unbuilt work is tracked in [`openspec/changes/`](../openspec/changes), where each item has a proposal
and a task list; what is built is specified in [`openspec/specs/`](../openspec/specs). Nothing in this
document claims a fourth status. A capability is built, specified, or named here as a gap.

The observable signal that a capability has shipped is a planner's `delegates_to` growing beyond
`[datalad]`. A half-built capability is worse than an absent one, because the planner will try to use
it.

## Practice

The harness is one part of the offering. The rest is delivered outside this repository.

The author works as the help desk for the **Canadian Neuroanalytics Scholars** programme, interfacing
with and guiding a cohort of postdocs working at the intersection of AI and neuroscience. The goal of
that role is to give them access to the technical tooling and resources they need to complete their
projects without having to find it themselves — and, in doing so, to build a resource that outlasts
any one cohort. This harness is the durable form of that work.

Training is delivered in three forms: conference workshops and tutorials, institutional and lab
sessions, and written material researchers work through on their own. Reference material built up
alongside it is **distributed across many sources and formats, and is deliberately not consolidated
here** — much of it is third-party, format-bound, or tied to a context that does not survive being
copied into a repository. This document characterises that body of work rather than inventorying it.

Reach that can be pointed at today: invitations to present, and inbound requests and issues from
outside the immediate cohort. There is also an early-stage institutional initiative building a shared
resource for guidance and training on this class of tool — early adopters finding each other and
pooling effort rather than each solving it alone.

> **This section carries no numbers, because none have been measured.** Under the same rule that
> binds the rest of this document, the training record is qualitative until the specifics exist.
> What would strengthen it: dates and audience size per delivery, the institutions reached, and
> whether any group outside the cohort has adopted the harness independently. Those are worth
> collecting; they are not worth estimating.

---

*Sources for this document: [`docs/references/`](references/index.md). Citation records live in
[`references.bib`](references/references.bib), the single source of truth shared with
[`paper/`](../paper).*
