## 0. Minimal working core

Sections 1–3: the two tables, the limitations, and the read that checks no row overclaims. That is
the whole of what makes a two-pager writable from evidence.

Deferred, explicitly: the two-page proposal itself (`docs/funding/catalyst-exploratory.md`); the
Track 2 `## Scaling to Impact` section; a budget, which depends on the unsettled shape of the probe
runner; and piloting the routing probe, which is engineering rather than documentation and belongs in
its own change.

## 1. Table A — the five named risks

- [x] 1.1 `docs/funding/catalyst-fit.md` with a header recording that the fund's text is
      **transcribed from notes, not fetched**, and must be re-verified against the published call
      before submission.
- [x] 1.2 One row per risk: evidence with a file path, source (*repo* / *training* / *reference*),
      status (*built* / *specified* / *gap*). Quote each risk in the fund's own words.
- [x] 1.3 Risk 2 (circular validation) first and fullest — `tests/lint-plugins-selftest.py` as a test
      of the test, CI verified red as well as green, per-probe controls and `invalidators`, routing
      ground truth machine-derived from `delegates_to`, and the exit-2 skip contract.
- [x] 1.4 Risks 1 and 4 attributed to the training work, with the repository's structural support
      named separately so the two kinds of evidence stay distinguishable.
- [x] 1.5 State plainly which risks land in repository territory and which lean on training, rather
      than claiming all five equally.

## 2. Table B — the review criteria

- [x] 2.1 One row per published criterion: feasibility within six months, concrete shareable outputs
      under open licenses, relevance to trustworthy AI-assisted research software, broader community
      benefit beyond the applicants, budget proportionality.
- [x] 2.2 Evidence and status per row; the budget row is *to write* and says so.
- [x] 2.3 A deliverables list drawn from the adoption gaps — artifacts, not intentions: a probe
      runner, executed results reported per-model and per-dimension, fixtures and rubrics published
      as reusable instruments, an adoption package (real install path, worked example, portability
      beyond two harnesses), and a practice write-up paired with the training material.

## 3. What it cannot claim

- [x] 3.1 A limitations section taken from `paper/sections/05-discussion.md` unsoftened: the
      capability plane is uneven, portability is designed for six harnesses and exercised on two, and
      no probe has been run.
- [x] 3.2 Read every row and confirm no evidence cited from `openspec/changes/` is marked *built*.
      `changes/` is the authoritative list of what is not built; a row citing it is *specified* at
      best.
- [x] 3.3 Confirm no number in the document comes from an unrun measurement, and that any figure
      belonging to overlapping work is attributed to it.
- [x] 3.4 Confirm the training rows carry no date, headcount or institutional reach that was not
      supplied, and name no individual.

## 4. Verify

- [x] 4.1 Every Table A row names a file path or is explicitly attributed to training or reference
      work, and carries a status.
- [x] 4.2 Spot-check each cited path exists on disk.
- [x] 4.3 `openspec validate --all --strict --no-interactive` passes.
- [x] 4.4 `python3 tests/lint-plugins.py --strict` — unchanged at 0 errors; this change touches no
      plugin.
- [x] 4.5 Read Table A against `docs/motivation.md`. The two documents make the same claims about
      what is built; if they disagree, `motivation.md` is canonical and the matrix is wrong.

## Notes

Verified 2026-09-11 on `openspec-and-paper`.

- **3.2** — one clarification was needed that the change did not anticipate. Risk 2 cites
  `openspec/changes/archive/2026-09-11-add-research-communication/tasks.md` as evidence and marks it
  *built*, which the stated rule would forbid. The rule was about **active** changes; archived ones
  shipped, and their task records are evidence of what was done. The status vocabulary section now
  says so explicitly, rather than leaving the matrix to contradict its own rule. No active change is
  cited anywhere in the document.
- **3.3 / 4.2** — every path cited in the matrix was checked to exist: 16 relative links and 15
  backticked paths, all resolving. Numbers verified against disk rather than carried over: 19 specs;
  4 probes, 1 suite, 27 tasks; 16 rows in the decision-locking table (the working plan said 17);
  `docs/writing/` is 6 files distilled from 10 sources; the self-test is 22 cases *including* the
  pristine control, not 22 plus a control.
- **3.4** — the training rows carry no date, headcount or institutional figure, and name no
  individual. The institutional initiative is described and left unnamed.
- **Fund text is transcribed, not fetched.** Applications were not open when this was written. The
  five risks and five criteria come from notes and are flagged as such in the document header. This
  is the single largest correctness risk in the change and is deliberately visible at the top of the
  file rather than recorded only here.
- **4.5** — Table A and `docs/motivation.md` agree on what is built. Both describe the capability
  plane as uneven with `datalad` at 19 toolbox skills and `bids`/`containers`/`archive` at none, both
  state the evaluation as specified and unrun, and both give portability as two harnesses exercised
  of six designed for.
- **4.3 / 4.4** — `openspec validate --all --strict` and `lint-plugins.py --strict` both pass; this
  change touches no plugin, so the lint result is unchanged by construction.
