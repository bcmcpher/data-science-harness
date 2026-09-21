# Introduction

<!-- SKELETON. Each block below is the argument the paragraph must make and the evidence it needs.

`docs/motivation.md` is the first written prose of this argument and is the repository's canonical
statement of it. Draft from there rather than from scratch, and do not contradict it — but do not
link to it either. A published paper must stand alone for a reader who cannot follow a repository
link, so this section carries its own prose. -->

<!-- Quoted passages in the source notes remain the authority for anything attributed. -->

## The problem

<!--
MOVE 1 — establish the territory.

Academic data science has a different end goal from software: the deliverable is a research product,
not a shipped package. That product is increasingly not a static PDF or a frozen dataset.

Keep this short. The reader knows it.
-->

## What changed

<!--
MOVE 2 — the gap.

Assistants can now execute analyses faster than the surrounding record can be maintained by hand.
Three consequences, each of which needs a citation or an observation, not an assertion:

  a. Provenance falls behind execution. A result exists before anything records how it came to be.
  b. Administrative context — funding, ethics, consent scope, obligations, credit — was already the
     part most likely to be reconstructed after the fact. Acceleration makes that worse.
  c. Governance does not travel with data. @botes2026lawinsidemachine: "Technically portable data
     are not necessarily governably reusable data." Also: agent-level access control, consent
     obsolescence, and re-identification through combination across federated sources.

Be careful here. (a) and (b) are claims about practice that we are asserting from experience, not
measuring. Say so, or find a citation. The paper's own honesty rule applies to its introduction.
-->

## Why the obvious fixes are insufficient

<!--
MOVE 3 — the niche.

  - Reproducibility checklists are applied at the end, to an artifact whose history is already lost.
  - Provenance tooling (DataLad, containers) is necessary and not sufficient: it records what was
    run, not why, under what commitments, or who is accountable.
  - Agentic harnesses that enforce analytic rigor (@chen2026brainresearcher) govern the reasoning
    inside one analysis, and do not produce the durable lifecycle record those judgements should
    attach to.
  - Reporting guidelines (EQUATOR, COBIDAS) describe the destination, not the path.

Each bullet needs to be fair to the thing it sets aside. This is the paragraph most likely to
misrepresent prior work; write section 02 first and come back.
-->

## What we built

<!--
MOVE 4 — the contribution. Forward reference to section 03; do not architect here.

  - Two planes: research process separated from tool mechanics, so capabilities recombine and a
    workflow can swap one for another.
  - One provenance chain: every computation through `datalad run`, every administrative change
    `datalad save`-d, so the analysis record and the administrative record cannot diverge.
  - A versioned ledger: products, obligations, contributors, and an append-only log, validated
    against a schema.
  - The living compendium as the default export, not an extra step.
  - A set of refusals: the harness declines to emit an environment, a figure or a tool parameter it
    cannot trace to something declared. Forward-reference section 03; this is the move a reader is
    least likely to expect and is worth naming in the intro rather than saving.

State the design commitment plainly: governance should be a by-product of doing the work, because
anything that requires a separate act of discipline will be skipped under deadline.

STATE OF THE BUILD, for this move's last sentence — take it from disk, not from an earlier draft.
Both planes are built: 22 plugins, 77 registered skills (37 planner / 40 toolbox), 8 doers each
paired 1:1 with a `*-cli` toolbox, 22 specs. What is *not* built is evidence, and the sentence must
carry both halves or it overclaims. Section 05 has the specifics; do not enumerate them here.
-->

## Contributions

<!--
Numbered list. Candidates:
  1. An architecture separating research process from tool mechanics, with a stated contract
     (planner/doer) that is mechanically checkable.
  2. A ledger schema treating administration as a first-class, provenanced research object.
  3. A living-compendium export composed of four coupled artifacts from one provenance chain.
  4. A specified evaluation protocol for measuring whether a harness improves governance — stated as
     a protocol, with no results.

Contribution 4 is unusual and reviewers will push on it. @botes2026lawinsidemachine's "what gets
benchmarked gets built" is the defence: specifying the measurement before the capability is a
deliberate choice, not an omission. Make that argument explicitly rather than hoping it lands.
-->
