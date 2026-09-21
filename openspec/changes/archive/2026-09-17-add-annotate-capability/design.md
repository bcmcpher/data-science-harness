## Context

The capability plane is uneven: `datalad` has 19 toolbox skills and is the reference shape, while
`bids`, `containers`, and `archive` have none and their doer is the entire surface. `annotate` does
not exist at all, yet `curate/annotate` is written as though it does. The vocabularies involved
(SNOMED CT, Neurobagel's term set, ReproSchema, NIDM) are exactly the kind of knowledge a language
model will confabulate confidently, which is why this capability must be a tool call and not a
prompt instruction.

## Goals / Non-Goals

**Goals:**
- One doer that owns annotation mechanics, so `curate/annotate` never calls a CLI.
- Toolbox skills that are independently useful, matching `datalad-cli`'s one-skill-per-verb shape.
- Honest coverage reporting: which variables got a controlled term, which did not, and why.
- A gated e2e assertion so the capability is verified, not assumed.

**Non-Goals:**
- Hosting or vendoring a terminology server. Lookup goes to whatever the installed tool provides.
- Deciding *which* term is scientifically correct for a variable — that is a research judgement the
  planner surfaces to the user.
- Pushing to a Neurobagel graph. That is `disseminate/publish`'s concern and a later change.

## Decisions

- **Split doer from toolbox**, mirroring `datalad`/`datalad-cli`. The doer holds the operating
  procedure and the refusal rules; the toolbox holds per-tool invocation detail. This keeps the doer
  readable as tools are added.
- **Never invent an identifier.** The doer reports a variable as unannotated rather than emitting a
  code it did not look up. This mirrors the archive doer's `result: unminted` contract, which is the
  established pattern in this repo for "the tool was unavailable, so the answer is absence".
- **The doer is read-mostly but not read-only.** It writes metadata files (`participants.json`,
  sidecars) but never commits — the save stays with the datalad doer, so annotation joins the same
  provenance chain as everything else.
- **Toolbox scope is the four tools already named in planner bodies**, not a survey of the field.
  One step deep before the next step wide.

## Risks / Trade-offs

- **Tool availability is uneven.** `bagel-cli` and `pynidm` are installable; a SNOMED lookup needs a
  licensed terminology source. The doer must degrade per-tool rather than per-request, so a dataset
  can gain Neurobagel annotation while SNOMED coverage stays empty.
- **A half-built capability is worse than an absent one**, because the planner will try to use it.
  If only some tools land, `curate/annotate`'s `delegates_to` should still grow, but the doer must
  report unavailable backends explicitly rather than silently skipping them.
- **Term choice is research judgement.** Automating lookup risks implying the harness endorses the
  mapping. The doer returns candidates with their source; the planner presents them for confirmation.
