# Related work

<!--
SKELETON.

Write this section FIRST. The introduction's "why the obvious fixes are insufficient" paragraph
depends on getting the positioning right, and the positioning is the part of this paper most likely
to be wrong in a way that costs credibility with the people we most want to work with.
-->

## Principles and frameworks

<!--
STAMPED [@macdonald2026stamped] — Self-containment, Tracking, Actionability, Modularity,
Portability, Ephemerality, Distributability. Each a spectrum, not a pass/fail gate. This is the
framework the harness indexes into: every skill declares which letters it advances, and the lint
validates those letters against the closed set.

Cover briefly: YODA as the concrete dataset layout, VAMP as the antecedent formulation.

Do not re-derive STAMPED here. Cite it and move on; docs/stamped.md carries the normative
requirements.
-->

## Provenance and pipeline tooling

<!--
DataLad [@datalad] — content-addressed versioning plus `run`/`rerun`, which is what makes
Tracking T.4 (component versions captured programmatically) achievable rather than aspirational.

BIDS [@bids] and Nipoppy [@nipoppy] — layout and pipeline management.

Neurobagel [@neurobagel] — federated harmonization and search, which is where controlled-term
annotation pays off.

Frame these as *capabilities the harness wraps*, not as competing approaches. The contribution is
not new provenance machinery; it is that the machinery is invoked by default by the process layer
rather than remembered by the researcher.
-->

## Living research products

<!--
NeuroLibre [@neurolibre] — re-executable preprints.
Paper2Agent [@paper2agent] — methods exposed as agent-callable tools.
Lab-in-a-Box [@labinabox] — self-hosted, data-sovereign infrastructure.

The claim to make: each is a good answer to one arm of the problem, and they are not currently
produced from a common provenance chain. This harness's contribution here is the *coupling* — four
artifacts from one chain, cross-linked by persistent identifier — not any one of the four.

Be honest that this coupling is designed and only partly built (see openspec/changes/).
-->

## Agentic harnesses for scientific analysis

<!--
THIS IS THE SUBSECTION THAT MATTERS. Get it right or the paper reads as unaware of its own
neighbourhood.

Brain Researcher [@chen2026brainresearcher] is described by its authors as "an agentic research
harness operating in a neuroimaging researcher's computational environment under rules for
admissible analyses, required checks and claim scope." It is not adjacent work. It is the same
phrase for a system in the same field, and it shares authors with material this project already
draws on.

Describe it accurately and generously first:
  - Commitment cards: question, allowed alternative specifications, and success/failure criteria
    sealed by content hash BEFORE execution.
  - Tool Registry with version pinning; BR-KG (745,949 nodes / 2,461,469 edges); MCP mediation;
    version-pinned container execution.
  - Review layer applying BLOCK/WARN rules, classifying claims as accepted, qualified, revised,
    blocked, rejected, or deferred.
  - Reported: first-choice tool-selection accuracy 23.3% → 93.6% across seven models on 60
    tool-calling tasks; verifiable grounding 4.6% → 22.0% under three-judge majority.
  - Multiverse analyses exposing analytic-choice sensitivity.

THEN state the distinction, in these terms:

  Brain Researcher governs analytic rigor WITHIN a single analysis.
  This harness governs the lifecycle AROUND analyses.

And then the interface, which is the only part that earns the word "complementary":

  Their review layer adjudicates claims but does not produce the durable, versioned provenance
  record those verdicts should attach to. This harness produces exactly that record and has no
  claim-adjudication layer. A verdict is only as useful as the artifact it binds to; an artifact is
  only as useful as the judgement recorded about it.

Also state, without hedging, where WE are behind:
  - Their tool registry is machine-readable and rich. Our equivalent is `delegates_to`, a list of
    plugin names, and it is far thinner. Much of their tool-selection improvement plausibly comes
    from registry richness we do not have.
  - They have run a benchmark. We have specified one.
  - Their commitment cards are a sharper mechanism than our frozen-spec-plus-ledger-obligation, and
    we have no multiverse capability at all.

Reviewers who know this work will check whether we noticed. Noticing, in print, costs nothing and
buys the collaboration.

Source note: docs/references/notes/chen-2026-brain-researcher.md
-->

## Governance as infrastructure

<!--
@botes2026lawinsidemachine supplies the argument for why any of this matters beyond tidiness:
governance has to be designed into the infrastructure rather than retrofitted, because agent-speed
querying, consent obsolescence, re-identification through combination, and cross-border conflict
each break an assumption human-scale review rested on.

Adjacent frameworks to cite via that piece: GA4GH machine-readable consent [@ga4gh_consent],
UNESCO neurotechnology ethics [@unesco_neurotech], NIH BRAIN neuroethics principles
[@nih_brain_neuroethics].

Two things to carry over carefully:
  - "Machine-readable consent should not be confused with machine-decided consent." The harness
    records terms; it does not decide them. Say so.
  - This is a perspective piece operating at the level of federated repositories and national
    frameworks. A project-level tool cannot deliver most of what it asks for. Claim the narrow
    thing: a durable, versioned, portable project-level governance record is a precondition for the
    larger thing, not the larger thing.

Source note: docs/references/notes/botes-2026-law-inside-machine.md
-->
