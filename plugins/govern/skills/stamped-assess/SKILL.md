---
name: stamped-assess
description: >
  Score a research object against the STAMPED checklist — Self-containment, Tracking, Actionability,
  Modularity, Portability, Ephemerality, Distributability — reporting each dimension separately with
  the evidence behind it. Trigger on "STAMPED", "stamped assess", "score this dataset", "how
  reproducible is this", "reproducibility audit", "readiness for sharing", "compliance audit",
  "what's missing before we publish". Do NOT trigger to fix what it finds, or to validate BIDS
  conformance alone (that is the bids doer).
plane: workflow
stamped: [M, T]
delegates_to: [bids]
---

# Skill: stamped-assess

Report how the research object stands against the seven STAMPED principles, per dimension, with the
evidence for each score.

**Read this before anything else: a dimension you have no evidence for scores `unassessed`, never
zero.** This is the same contract the `annotate` doer uses for `unavailable` versus `unannotated`,
and the `archive` doer for `unminted`. A zero says "we looked and it is not there". `unassessed` says
"we could not look". Collapsing them produces a score that is wrong in the direction that makes the
project look worse than it is, and a reader cannot tell which happened.

**And do not produce a single composite score.** `docs/stamped.md` treats each principle as a
spectrum rather than a pass/fail gate, and averaging seven dimensions into one number implies a pass
mark the framework declines to set. The same rule governs the provenance probe in
`docs/evaluation.md`. Report seven answers.

Load `plugins/govern/references/stamped.md` for the normative requirements (S.1 … D.3) before
scoring, and score against those ids rather than against the principle names.

## When to use
- Before a release, a deposit, or a submission, to see what is missing.
- When a funder or collaborator asks how reproducible the object is.
- Do NOT use to *fix* anything it finds — each gap points at the skill that owns it. Do NOT use it
  as a BIDS validation (delegate that to the **bids** doer, which this skill does for S).

## Steps

1. **Establish what you are assessing.** A dataset, a product within it, or the whole project.
   The answer changes what counts as "all modules" for S.1 and M.1.

2. **Gather evidence per dimension, from tools and files rather than impression.** Delegate:
   - **S** — `dataset_description.json`, licence files, subdataset registration; BIDS conformance
     via the **bids** doer (S.1, S.2).
   - **T** — DataLad history read directly (`datalad status`,
     `bash plugins/datalad-cli/scripts/dsh-log.sh --legacy`): are outputs reachable through
     `datalad run` commits, are component versions recorded (T.1–T.4)?
   - **A** — a README with reproduction instructions, and whether they are executable specifications
     rather than prose (A.1, A.2).
   - **M** — directory structure, subdatasets, per-module licences (M.1–M.3).
   - **P** — a container recipe, a pinned environment, and whether runs used it (P.1–P.3).
   - **E** — whether results were produced in a rebuilt environment (E.1).
   - **D** — siblings, published identifiers, SPDX/REUSE licence identifiers (D.1–D.3).

3. **Score each dimension against its requirement ids**, and write down the evidence you used. A
   score with no evidence line is not a score.

4. **Mark as `unassessed` anything you could not check**, with the reason: a tool absent, a
   credential missing, a file outside the dataset. Name what would make it assessable.

5. **Report per dimension. No total.**
   ```
   op:         stamped-assess
   target:     <dataset | product id | project>
   S:          <score> — <evidence> | unassessed: <why>
   T:          <score> — <evidence> | unassessed: <why>
   A:          ...
   M:          ...
   P:          ...
   E:          ...
   D:          ...
   unassessed: <the dimensions above that could not be checked, and what would fix that>
   gaps:       <per dimension: the requirement id unmet, and the skill that owns closing it>
   ```

6. **Report, and nothing else.** Do not write scores into `products[]` or `obligations[]`, and do
   not run `datalad save`: the ledger has no field for a score, an assessment is an observation at a
   moment rather than a commitment, and there is nothing else on disk this skill changes.

## Constraints

- **A dimension with no evidence is `unassessed`, never zero, and never omitted.** Silence reads as
  a pass; a zero reads as a failure. Both are wrong when the truth is "not checked".
- **Never produce a composite or average score.** Seven dimensions, seven answers. The framework
  sets no pass mark and neither do you.
- **Never state that the object is reproducible, compliant, publication-ready, or FAIR.** Report
  evidence per dimension. Those words are conclusions someone else draws, and the pull toward them
  comes from the question being asked, not from what you found.
- **Never score a dimension from a plausible inference.** "There is a Dockerfile, so P is satisfied"
  is not evidence that runs used it — P.1 is about undocumented host state and only the run records
  answer it. Check the DataLad history.
- **Never infer PHI exposure or its absence.** You can report that de-identification has no recorded
  action (`curate/deidentify` owns that record); you cannot report that a dataset contains no
  identifiers. Absence of a record is not absence of risk.
- **Never write a score into the ledger's structured fields.** There is no schema field for it, and
  inventing one in prose that reads structured is worse than a fabricated record.
- Do not fix what you find, and do not edit dataset files. Each gap names the owning skill.
- Read-only: never write to `project.yaml`, never run `datalad save`. This skill commits nothing.
