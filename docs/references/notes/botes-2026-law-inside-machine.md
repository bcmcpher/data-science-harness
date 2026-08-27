# Botes (2026) — The Law Inside the Machine

## Citation

Botes, M. (2026, August 25). *The Law Inside the Machine: Building the NeuroAI Future by Design.*
Biolawgic. https://biolawgic.substack.com/p/the-law-inside-the-machine-building
(accessed 2026-08-27) — `[botes2026lawinsidemachine]`

## Core claim

Governance infrastructure has to be designed alongside neuroscience AI systems, not retrofitted onto
them. The emerging federated environment — AI agents, foundation models, digital twins querying
across repositories — breaks four assumptions that human-scale governance rested on:

1. **Agent-level access control.** Human-centred review cannot manage systems submitting queries at
   machine speed and reformulating requests across federated repositories.
2. **Re-identification through combination.** An agent joining several sources can infer sensitive
   information that no single repository contains.
3. **Consent obsolescence.** Decades-old consent documents written for human interpretation are
   unreliable guides for autonomous systems making access decisions.
4. **Cross-border conflict.** Data collected in one jurisdiction, stored in another, and processed
   internationally meets incompatible rules on consent, sovereignty, and commercialization.

Proposed mitigations: embed governance in the data infrastructure as structured metadata capturing
consent terms, withdrawal status, and use restrictions; distinguish training-time governance (was the
data lawfully obtained) from agent-time governance (what may this system do right now); make
governance assessment part of scientific benchmarking; and treat the whole thing as continuous
infrastructure rather than one-time compliance.

Frameworks cited: GA4GH machine-readable consent guidance, the UNESCO Recommendation on the Ethics of
Neurotechnology, and the NIH BRAIN Initiative's Neuroethics Guiding Principles.

## What it motivates

- **`project-ledger`** — the strongest single argument for why administration belongs in the
  provenance chain rather than in a lab wiki. "Technically portable data are not necessarily
  governably reusable data" is precisely the gap between STAMPED Distributability (the bytes move)
  and governable reuse (the terms move with them). The ledger's `obligations[]` is the beginning of
  carrying terms forward; it does not yet carry consent scope or use restrictions, and this source
  argues it should.
- **`govern`** — the training-time versus agent-time distinction maps onto the harness's own
  separation between what was recorded when data entered the project and what a skill may do with it
  now. `govern/obligations` tracks the first; there is no mechanism for the second.
- **`curate`** — machine-readable consent is a controlled-term annotation problem, which puts it in
  the same territory as `add-annotate-capability`. GA4GH's data-use vocabulary is a candidate
  alongside Neurobagel and SNOMED.
- **`liab`** — cross-border complexity is the clearest external argument for the self-hostable arm of
  the living compendium. It is also a caution: self-hosting changes where data sits, which is not the
  same as satisfying a jurisdiction's requirements. `add-liab-capability` records this as a
  constraint — record what was deployed, do not assert compliance.
- **`evaluation-protocol`** — "what gets benchmarked gets built" is a direct argument for defining
  the evaluation before the capabilities it would measure, which is the order this project is
  following.

## Where it differs

This is a perspective piece, not a system. It names what governance infrastructure must carry and
argues for designing it in; it does not specify a mechanism, and it is written at the level of
federated repositories and national frameworks rather than a single lab's dataset.

The harness operates one level down: it is what a lab could actually run. That is a real limitation
of the mapping — most of what this piece asks for (agent-level access control across federated
repositories, machine-decidable consent scope) is not something a project-level tool can provide. The
honest claim is narrower: the harness makes a project's own governance record durable, versioned, and
carried alongside the data, which is a precondition for the larger thing rather than the thing
itself.

The piece is also careful in a way worth carrying into the paper: machine-*readable* consent is not
machine-*decided* consent. A harness that automated the decision would be overreaching.

## Quoted passages

> "Technically portable data are not necessarily governably reusable data."

> "Machine-readable consent should not be confused with machine-decided consent."

> "A model trained on lawfully obtained data is not automatically lawful in every later use."

> "What gets benchmarked gets built."

> "The challenge is not simply to place legal rules inside a machine. It is to build scientific
> systems that can carry consent, provenance, accountability, and human values forward."
