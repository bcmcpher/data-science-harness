## Context

`resources/` already holds nine source PDFs and is git-ignored ("copyrighted / large reference PDFs
— kept out of the repo"). `docs/writing/index.md` already establishes a source-table convention
(Cite / Source / Local file / Best for) with an attribution note. Both should be reused rather than
duplicated.

The user's direction on benchmarks is explicit: describe how the harness would be evaluated, do not
run anything yet, and keep the configuration composable because which integrations appear in the
paper is undecided.

## Goals / Non-Goals

**Goals:**
- Every motivating source traceable to the harness feature it motivates.
- An evaluation protocol precise enough that someone else could implement and run it.
- A paper skeleton that states the positioning against Brain Researcher accurately.
- CI, so the lint and selftest that already exist actually run.

**Non-Goals:**
- Running any benchmark. No API spend, no results, no numbers in the paper.
- Building an evaluation runner. Fixtures and protocol only.
- Committing copyrighted PDFs. Those go to the git-ignored `resources/`.
- Choosing the paper's final integration list. The fixture format exists so that choice stays open.

## Decisions

- **Probes are independent and declarative.** Four axes — routing, provenance, reproducibility, cost
  — each defined by a YAML file naming its metrics and the capabilities it requires. A probe that
  needs a tool the installation lacks is skipped, not failed. This is what "composable" has to mean
  concretely: adding or dropping an integration is editing fixtures, not code.
- **Metric names for the routing probe deliberately mirror Brain Researcher's** — route@k,
  capability@k, handoff sufficiency. Inventing parallel names for the same measurements would make
  the two sets of numbers incomparable, and comparability is the point of running it at all.
- **Routing ground truth comes from `delegates_to`.** The lint already resolves every declared
  delegation to a real agent-providing plugin, so the correct answer for "which doer should this
  request reach" is machine-derivable from the repository rather than hand-labelled. That makes the
  suite cheap to keep correct as capabilities land.
- **The harness-off control is part of the probe definition, not an afterthought.** Brain
  Researcher's headline number is a difference between conditions; a probe that cannot state its
  control measures nothing.
- **`docs/evaluation.md` states plainly that nothing has been run.** A protocol document that reads
  like a results document is the specific failure this project exists to argue against.
- **Reuse `~/.claude/scripts/model-usage.mjs` for the cost probe** rather than writing a second
  transcript analyzer. It already prices transcripts.
- **The paper is MyST from the start.** Converting later is cheap; but the paper's argument is that
  research products should be re-executable, and drafting it in a static format would be a small
  ongoing embarrassment. It also gives `add-compendium-capability` a real target.
- **Positioning against Brain Researcher is stated as a distinction, not an assumption of
  complementarity.** Brain Researcher governs analytic rigor within a single analysis — admissible
  specifications, commitment cards, multiverse sensitivity, claim adjudication. This harness governs
  the lifecycle around analyses — provenance chain, ledger, obligations, credit, DOI-linked living
  compendium. The interface is real: their review layer adjudicates claims but does not produce the
  durable provenance record those verdicts should attach to, and this harness produces that record
  and has no claim-adjudication layer. The overlap is also real and the paper must say so.

## Risks / Trade-offs

- **A protocol nobody runs can drift from what is implementable.** Grounding the routing probe in
  `delegates_to` mitigates this for one axis; the other three are unvalidated until executed.
- **Mirroring another paper's metric names invites a comparison that may not be fair.** The task
  suites differ, the models will differ, and the conditions differ. The paper has to state the
  limits of the comparison rather than lean on it.
- **A paper directory in the harness repository couples two release cadences.** The alternative — a
  separate repo — loses the tight link between spec, benchmark fixture, and manuscript, which is the
  main reason to draft it here.
- **CI on a repository with no automated behaviour tests can create false confidence.** The workflow
  should be explicit that it checks structure and specs, not behaviour.
