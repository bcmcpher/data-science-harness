# Design notes

## Why the lint was extended before the prose was fixed

Correcting eleven claims by hand produces eleven claims that are correct today. The same pass two
merges ago produced the same result, and the drift returned. So the ordering here is deliberate:
write the check, **observe it fail on the unfixed tree**, then fix. Step 1.5 is the load-bearing one
— a rule that has never been seen failing is an assertion about the future, and this repository's
own selftest exists because of that argument.

It also localises the honest answer to "why did `--strict` pass?". It passed because the checks that
existed were each correct and each narrow: a repo-wide plugin count that stayed true while a row
went stale, a marketplace planner count that read a number but not the names beside it, and no link
checking at all. The drift did not defeat the lint; it lived between its checks.

## What the lint still cannot catch

Worth stating plainly, because the temptation after a pass like this is to treat a green lint as a
guarantee about the prose.

Of the eleven drifts, the extended lint catches **five** — the per-plugin skill count, both archived
links, and the two omitted doers. The other six were found by reading:

- "the capability plane is uneven" — a true sentence that stopped being true
- the `containers` and `compendium` `plugin.json` descriptions — well-formed prose about the wrong
  design
- "74 skills" in two docs — the wrong unit in the wrong file, checkable in principle but the regexes
  are scoped to the README and marketplace by design
- the MyST claim — a scope error, true of the plugin and false of the tool
- the `checkpoint` deferral note — prose contradicting a sibling plugin's `hooks.json`

A structural lint checks structure. Claims about *what the software means* remain a reading problem,
and this change does not pretend otherwise.

## Collapsing Stage 4

The lifecycle model had nine stages; checkpointing was the fourth. The evidence that it was never a
stage was already in the repository:

| Evidence | Where |
|---|---|
| a `Stop` hook saves any dirty tree **once per turn** | `plugins/datalad-cli/hooks/hooks.json`, `hooks/scripts/datalad-checkpoint.sh` |
| the ledger logs `{ op: checkpoint, stage: analyze }` | `examples/project.yaml:91` |
| the walkthrough conceded "analysis is iterative — loop Stage 3 ↔ 4" | `docs/end-to-end-workflow.md` |

A step performed automatically on every turn is not a phase of a research project. It is what the
Manage & Comply lane is for: the cross-cutting track the stages run inside, already holding
`log-decision`, `track-milestone` and `obligations`.

**The skill was kept, and that decision is worth recording.** The hook and the skill are not
redundant. The hook writes `Auto-checkpoint <ts>: <files>` and nothing else — it cannot say *what
changed and why*, and it writes no ledger entry. `analyze/checkpoint` composes a described message
and appends to `project.yaml`. Deleting it would trade a describable history for a mechanical one.
What was deleted is the claim that stopping to checkpoint is a stage of the work.

Renumbering was chosen over leaving a gap at 4. The cost was small and measurable — `Stage 4`
appeared once, stage numbers at all appeared in four files, and no machinery keys on the numbers,
because `schemas/project.schema.json` types `stage` as a free string and the fixtures use names.
A numbering with a hole in it invites someone to fill it.

## Deliberately not addressed

These were found while mapping the repository and are recorded here so the next pass starts from
evidence rather than from a fresh survey. None is prose drift; all are gaps in what is *tested*.

| | Gap |
|---|---|
| G1 | `nipoppy` and `process` have **zero** test presence of any kind — no gate test, no real-tool test. `process` is the plugin that runs fMRIPrep |
| G2 | ~19 e2e gate assertions are `[ $RC -eq 0 ] \|\| [ $RC -eq 1 ]`. They pass whether or not the tool exists; they establish that the gate does not crash |
| G3 | the `e2e` job is `if: github.event_name == 'workflow_dispatch'` (`.github/workflows/ci.yml:120`) — it never runs on push or PR |
| G4 | gate scripts are unenforced and inconsistently named: 6 of 8 toolboxes have one, under 5 filenames; `datalad-cli` and `nipoppy-cli` have none |
| G5 | toolbox skills declare no `plane:` and no `stamped:`; `plane: capability` appears on no shipped skill |
| G6 | `paper/figures/` is empty; Figures 1 and 2 are specified in the section comments |
| G7 | the `manuscript` sub-agent in `docs/writing/SPEC.md` is still specified-not-built, carried since `add-compendium-capability/design.md:16` |

G1–G3 are the ones that change what a green suite means, and they are the agenda for the validation
work this change clears the way for.
