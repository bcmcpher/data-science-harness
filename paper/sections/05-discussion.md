# Discussion

<!-- SKELETON. -->

## What this design buys

<!--
Three claims, each traceable to openspec/specs/ and each stated at the strength the evidence
supports — which, with no executed evaluation, means "designed to" and not "shown to":

  1. Governance as a by-product. Provenance and administrative record are produced by doing the
     work, not by a separate act of discipline. Anything requiring separate discipline is skipped
     under deadline.
  2. Recombination. The plane separation means a workflow can swap one capability for another
     without rewriting the process; the mechanically checked planner/doer contract keeps that from
     decaying into convention.
  3. Coupling. Four living-compendium artifacts from one chain, cross-linked by identifier, rather
     than four separately maintained outputs that drift.

Resist "we show". Nothing here is shown yet.
-->

## Limitations

<!--
ORDER MATTERS. First limitation first.

1. NOTHING HAS BEEN EVALUATED. The protocol in section 04 is specified and unrun. Every claim about
   the harness's effect on work quality is a design argument, not a measurement. This is the
   limitation a reader should take away, and it goes first.

2. BUILT IS NOT EXERCISED. This replaces the old "uneven capability plane" limitation. Both planes
   are now structurally complete — 7 doers, each paired 1:1 with a toolbox, and DataLad's toolbox
   used natively by the main thread — and that sharpens the limitation rather than softening it, because shape is no longer
   what is missing. Be specific, from `tests/e2e-smoke.sh` and `.github/workflows/ci.yml`:

     - `nipoppy` and `process` have **no test of any kind** — no gate test, no real-tool test.
       `process` is the plugin that runs fMRIPrep.
     - ~19 gate assertions take the form `[ $RC -eq 0 ] || [ $RC -eq 1 ]`. They pass whether or not
       the tool is installed. What they establish is that the gate script does not crash.
     - The e2e job is `if: github.event_name == 'workflow_dispatch'` — it never runs on push or PR.
       CI checks structure and specs, and says so in its own header.
     - `containers` is the one capability whose full real-tool path was run end to end here, and it
       is also the one CI cannot run, because apptainer is deliberately not installed there.

   State what a green suite does and does not mean. It means the gates answer and refuse correctly
   and the structure is consistent. It does not mean the tools behind the gates work, and it says
   nothing about whether the harness improves anyone's research record.

   Do not point a reader at `openspec/changes/` for the remaining work. It is empty, and an empty
   changes/ now means the structure is finished rather than that nothing is left.

3. The lint checks structure, not meaning. It catches a stale count, a dead change-link, a
   delegation naming a plugin that provides no agent. It cannot catch a sentence that is simply
   wrong: a reconciliation pass on this repository found eleven documentation drifts, of which the
   extended lint caught five. Concede this directly — the mechanically checkable contract is one of
   the contribution claims, so its limits belong in the same paper.

4. Single-project experience. The design comes from one context; generality is asserted, not
   demonstrated.

5. Governance scope is project-level. @botes2026lawinsidemachine asks for agent-level access control
   and machine-decidable consent across federated repositories. A project-level tool cannot deliver
   that. The narrow claim is that a durable, versioned governance record is a precondition, and that
   the ledger schema does not yet carry consent scope or use restrictions at all.

6. No claim adjudication. We record what was done; we do not judge whether a claim is supported.
   @chen2026brainresearcher does, and does it better than we could bolt on.

7. Harness dependence. The content is Markdown and portable in principle, but it is exercised on two
   assistants. Portability to the other four named targets is designed, not tested.

Follow @chen2026brainresearcher's example here — their limitations section is direct about
same-dataset multiverse, possible training-data memorization, internal review-layer calibration, and
unmeasured runtime. A limitations section that reads as thorough is more persuasive than one that
reads as defensive.
-->

## Relationship to analytic-rigor harnesses

<!--
Reprise section 02's positioning in one tight paragraph, and make the constructive claim:

  Brain Researcher's review layer produces verdicts — accepted, qualified, revised, blocked,
  rejected, deferred — that should attach to a durable, versioned, citable artifact. This harness
  produces exactly that artifact and records no verdicts about it. The concrete integration is a
  claim record bound to a provenanced product identifier: their adjudication, our provenance chain.

@chen2026brainresearcher name "claim records as shared, contestable infrastructure across
laboratories" as future work. That is the point of contact, and it is worth proposing explicitly
rather than gesturing at.
-->

## Future work

<!--
  - Run the protocol. Routing pilot first — its ground truth is already derived from the repository,
    so it is the cheapest to make trustworthy.
  - Finish the capability plane. Name the changes rather than describing them abstractly:
    annotate, archive toolbox, compendium, bids/nipoppy depth, liab.
  - Extend the ledger to carry consent scope and use restrictions, per
    @botes2026lawinsidemachine's structured-metadata argument. GA4GH's data-use vocabulary is the
    obvious candidate and lands in the same place as controlled-term annotation.
  - Claim records bound to product identifiers — the integration above.
  - Dogfood: the first executable article this harness produces should be this paper.
-->

## Availability

<!--
Repository, license (MIT for code; CC BY 4.0 for this content), and the OpenSpec change record as
the roadmap.

Point at openspec/specs/ as the authoritative description of what is built, and openspec/changes/ as
what is planned. That is a small but real contribution to the reader: it means "what does this
actually do today" has a checkable answer that will not drift from the paper.
-->
