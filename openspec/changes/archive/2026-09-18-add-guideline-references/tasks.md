## Status

Complete as of 2026-09-18, and ready to archive. Split out of `deepen-bids-nipoppy` that day, taking
that change's `disseminate` spec delta with it.

## 0. Minimal working core

All of it. The refusal only means something once at least one guideline is bundled, and the licensing
work is per-guideline, so there is no smaller slice that leaves the planner in a coherent state.

Deliberately **not** here: STARD, TRIPOD and CARE; the Explanation and Elaboration documents; any
judgement about whether an item is adequately reported.

## 1. Verify what may be redistributed

- [x] 1.1 Verified 2026-09-18, licence text quoted verbatim in each reference file: **CONSORT 2025**
      PLOS Medicine 22(4):e1004587 CC BY; **STROBE** PLoS Medicine 4(10):e296 CC BY; **PRISMA 2020**
      prisma-statement.org, which states CC BY 4.0 for the checklists itself; **ARRIVE 2.0** PLOS
      Biology 18(7):e3000410, *"free of all copyright"*; **COBIDAS** bioRxiv 10.1101/054262 CC BY 4.0.
- [x] 1.2 **In four of the five, the obvious copy is not the licensed one.** The checklist PDFs on
      strobe-statement.org and arriveguidelines.org carry a copyright line and no licence; CONSORT
      2025 was published in five journals and only the PLOS Medicine printing may be redistributed;
      the Nature Neuroscience COBIDAS is not open. PRISMA is the single case where the initiative's
      own distribution is licensed. A pass that had started from each guideline's website — the
      obvious place — would have concluded that almost nothing could be bundled, and a pass that had
      not checked at all would have bundled all of it.
      **CONSORT 2010 also turned out to be superseded** by CONSORT 2025 in April 2025, whose authors
      state 2010 should no longer be used. The index had said "CONSORT" with no version, which is how
      that goes unnoticed; the bundled files carry versions in their filenames.

## 2. Bundle the text

- [x] 2.1 `references/equator/consort-2025.md`, `strobe.md`, `prisma-2020.md`, `arrive-2.0.md`.
- [x] 2.2 `references/cobidas/` — the seven Appendix D tables, one file each: experimental-design,
      acquisition, preprocessing, modeling-inference, results, data-sharing, reproducibility.
- [x] 2.3 Rewrite `references/equator-guidelines.md` as an index stating, per guideline, whether it is
      bundled and where its text came from.

## 3. Make the planners read it

- [x] 3.1 `disseminate/reporting-checklist` copies items from the bundled file, in the guideline's
      wording and order.
- [x] 3.2 It refuses for an unbundled guideline rather than producing a partial checklist.
- [x] 3.3 It stops claiming compliance.
- [x] 3.4 `govern/qc-review` reads the two dataset-answerable COBIDAS tables and skips with a reason
      when the reference is absent.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at 21 plugins / 71 skills.
      `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.2 `npm run spec:validate` — 23/23. `python3 tests/check-bench-fixtures.py` — clean at 42; no
      planner's `delegates_to` changed, so no fixture moved. `npm run paper:check` builds.
- [x] 4.3 Every reference file names its source, its redistribution basis quoted verbatim, and the
      date that basis was checked.
- [x] 4.4 `bash tests/e2e-smoke.sh` — 99 passed, unchanged. **This change adds no test coverage.**
      Nothing tests that a checklist is instantiated from the bundled text, because both skills are
      prompts; what is mechanically true is only that the files exist and the lint is clean.
- [x] 4.5 The OpenCode install of `disseminate` and `govern` carries the reference tree under
      `dsh/plugins/...`, which is the path the skills cite.
