# Chen et al. (2026) — Brain Researcher

## Citation

Chen, Z., Lu, N., Li, X., Ricard, J. A., Ju, C., Wang, H. H., Kindermann, C., Mumford, J. A.,
Dillmann, S., Kent, J., de la Vega, A., Koyejo, S., Calhoun, V. D., Buckholtz, J. W., Zhou, J. H.,
Bollmann, S., & Poldrack, R. A. (2026). *Bringing analytic rigor to agentic AI for science: The
Brain Researcher platform for neuroimaging data analysis.* arXiv:2608.19902 [cs.AI, q-bio.NC].
103 pages, 19 figures. — `[chen2026brainresearcher]`

## Core claim

An analytic output becomes a defensible claim only after alternatives have been weighed and the
claim has been limited to what the evidence supports. Agents left to their own devices reproduce the
familiar failures — selective analysis, premature declarations of success, optimizing an imperfect
criterion — so methodological judgement has to be embedded *in* the workflow rather than applied
after it.

Brain Researcher operationalizes this as a harness running in the researcher's own computational
environment under prospectively declared rules: which analyses are admissible, which checks are
required, and how far a claim may be scoped. Researchers state the question, the allowed alternative
specifications, and success/failure criteria in advance; these are sealed by content hash in
"commitment cards" before execution.

Reported architecture: a Tool Registry of machine-readable specifications with version pinning; a
knowledge graph (BR-KG, 745,949 nodes / 2,461,469 edges) linking tasks, brain regions and datasets;
an MCP server mediating model actions; an execution layer on version-pinned container backends; a
review layer applying BLOCK/WARN rules and emitting claim verdicts; and a memory system handling
conflict detection.

Reported results: across 60 tool-calling tasks and seven frontier models, first-choice tool-selection
accuracy rose from 23.3% to 93.6% (+70.2 points), and verifiable grounding from 4.6% to 22.0% under
three-judge majority vote. Reference routes were fixed before either condition ran. Metrics reported
are correct route/tool@k, capability@k, and handoff score@k.

## What it motivates

- **`evaluation-protocol`** — this is the closest thing to a benchmark design for an agentic research
  harness in neuroimaging, and its metric vocabulary (route@k, capability@k, handoff sufficiency,
  harness-off control) is what our routing probe adopts. Adopting their names is deliberate: inventing
  parallel terms for the same measurement would make the numbers incomparable, which is the only
  reason to run the probe.
- **`evaluation-protocol`** — their verified-groundedness definition ("cited evidence could be located
  and judged supportive") is a usable model for a claim-level metric, and their 22.0% ceiling is a
  useful calibration on how hard grounding is even with a harness.
- **`publication`** — the paper's shape (architecture, benchmark, collaborator-led studies,
  limitations stated plainly) is the template for our preprint, and their stated limitations —
  runtime and researcher effort unmeasured, review-layer calibration internal to a 60-case library —
  are exactly the ones we should expect to be asked about.
- **`analyze`, `govern`** — commitment cards are a sharper version of what `govern/preregister` does
  with a frozen spec and a ledger obligation. Their multiverse analyses over allowed specifications
  are a capability our comparison model has no equivalent of.

## Where it differs

**State the overlap first: this is not merely adjacent work.** Brain Researcher is also described as
"an agentic research harness" operating in a neuroimaging researcher's computational environment, and
it shares authors with material this repository already cites (Kent and de la Vega appear on
`Kent_2026.pdf` in `docs/writing/index.md`). Any claim of complementarity has to be earned.

The defensible distinction is one of scope:

- **Brain Researcher governs analytic rigor within a single analysis.** Admissible specifications,
  required checks, multiverse sensitivity, and a review layer that adjudicates a claim as accepted,
  qualified, revised, blocked, rejected or deferred.
- **This harness governs the lifecycle around analyses.** A single DataLad provenance chain from raw
  data to published result, an administrative ledger carrying obligations and credit, and a
  DOI-linked living compendium as the export format.

The interface between them is concrete rather than rhetorical. Their review layer adjudicates claims
but does not produce the durable, versioned provenance record those verdicts should attach to; this
harness produces exactly that record and has no claim-adjudication layer. A claim verdict is only as
useful as the artifact it is bound to, and an artifact is only as useful as the judgement recorded
about it.

We should also expect their tool-selection result to bound our own expectations: a large fraction of
their improvement comes from a machine-readable tool registry, and our equivalent — `delegates_to`
resolution — is far thinner.

## Quoted passages

> "an analytic output becomes a defensible claim only after alternatives are weighed and the claim is
> limited to what the evidence supports."

> "Brain Researcher, an agentic research harness operating in a neuroimaging researcher's
> computational environment under rules for admissible analyses, required checks and claim scope."

> "By linking decisions to evidence and provenance, Brain Researcher embeds methodological judgement
> within the workflow, not after it."

On their evaluation limits, paraphrased: several episodes rely on same-dataset multiverse rather than
independent replication; public datasets may trigger training-data memorization; review-layer
calibration was internal to a 60-case library rather than field-scale; and runtime and researcher
effort were not measured.
