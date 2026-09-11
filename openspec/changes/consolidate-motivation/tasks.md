## 0. Minimal working core

Sections 1 and 2 — the document, and the surfaces reconciled to it. Without both, the document is a
sixth copy rather than a consolidation.

Deferred, explicitly: settling the project's four names (a rename, not a documentation pass);
reconciling `paper/sections/01-intro.md` into written prose (the paper is a skeleton and drafting it
is its own work); and collecting the dates and headcounts the practice record lacks.

## 1. The document

- [x] 1.1 `docs/motivation.md` — Problem, in three paragraphs: the paper's premise
      (`paper/main.md:13-16`), then the README's tooling-mismatch premise (`README.md:9-15`) as why
      existing configurations do not answer it, then the help desk as what it looks like in practice.
- [x] 1.2 `## Who this is for` — early-career researchers working at the intersection of AI and
      neuroscience, reached through a help desk. The repository currently names no user.
- [x] 1.3 `## What changed` and `## Why the obvious fixes are insufficient` — from the argument
      outlines in `paper/sections/01-intro.md`. Mark the two claims that rest on experience rather
      than measurement as such; the paper's own honesty rule binds this document too.
- [x] 1.4 `## The design commitment` — governance as a by-product, stated as the mechanism and the
      reason for it. "First-class, not an afterthought" appears as what it delivers, not as a second
      motto.
- [x] 1.5 `## Principles` and `## Architecture` — STAMPED from `docs/stamped.md:8-13` and the four
      mapping claims; the two-plane split from `README.md:94-114`. Both compressed to what motivates
      the design; neither re-derived.
- [x] 1.6 `## What it claims, and how you would know` — the four probes and their controls from
      `docs/evaluation.md:14-30`, routing included, each with what would falsify it.
- [x] 1.7 `## Positioning` — Brain Researcher and the Botes argument, from
      `docs/references/notes/`. Named mechanisms on both sides; no complementarity claimed without
      naming the interface, and the three places this work is behind stated plainly.
- [x] 1.8 `## Scope` — neuroimaging-first, once, as the domain the evidence comes from.
- [x] 1.9 `## Status` — near the top, not the bottom: workflow plane complete, capability plane
      uneven, evaluation specified and unrun. Real numbers from `openspec/specs/` and disk.
- [x] 1.10 `## Practice` — the help desk, three delivery forms, reach. Reference material
      characterised as distributed, with why it stays that way. No number that was not supplied; one
      line naming which specifics would strengthen it.
- [x] 1.11 Cite from `docs/references/references.bib`, and verify each entry actually used — ten of
      seventeen carry `TODO: verify canonical citation`.

## 2. Reconcile the surfaces

- [x] 2.1 `README.md:7-31` — replace `## What this is` with a short identity statement, the
      by-product slogan, and a link to `docs/motivation.md`. The four priorities and the
      two-plane paragraph stay; the living-compendium list stays.
- [x] 2.2 `README.md` — add the status caveat near the top, so a reader meets it before line 174.
- [x] 2.3 `README.md:762-763` — `publish` and `annotate` are skills in `disseminate` and `curate`,
      not capability plugins. Correct both rows, and the `bids` row that calls the doer a
      "scaffold subset" where `README.md:193` says it never modifies the dataset.
- [x] 2.4 `README.md:3` and `:29` — reconcile the six-harness claim with the two-harness installer
      in place, rather than leaving it to `:604`.
- [x] 2.5 `.claude-plugin/marketplace.json:5` — rewrite to carry the four distinguishing claims and
      one status clause; fix the planner count from two to six.
- [x] 2.6 `.claude-plugin/marketplace.json:32` — remove "Metadata", which is not a STAMPED letter,
      and cover `raw-to-bids` as well as `annotate`.
- [x] 2.7 `.claude-plugin/marketplace.json:42` — rewrite the `disseminate` entry to cover its eight
      skills, including the living-compendium export.
- [x] 2.8 `plugins/datalad-cli/README.md:3` and `plugins/nipoppy-cli/README.md:3` — drop the
      "Claude Code" identity line, which contradicts the harness-agnostic claim, and match the
      plane-labelled register the other eleven plugins use.
- [x] 2.9 Read `paper/sections/01-intro.md` against the finished document and confirm no
      contradiction. The paper keeps its own prose; it must not disagree.

## 3. Ground it in a check that exists

- [x] 3.1 Extend `check_doc_claims` in `tests/lint-plugins.py`: every STAMPED letter named in
      `.claude-plugin/marketplace.json` prose validates against `STAMPED_LETTERS`, the same closed
      set already enforced on skills' `stamped:` frontmatter.
- [x] 3.2 Extend it again: the workflow-planner count in the marketplace description matches the
      number of plugins on disk containing a `plane: workflow` skill — the shape of the existing
      `**N plugins**` check, applied to the other manifest.
- [x] 3.3 Add one self-test case per check in `tests/lint-plugins-selftest.py`, each injecting the
      fault this change is fixing, so the check is proven to react rather than assumed to.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, with both new checks live.
- [x] 4.2 `python3 tests/lint-plugins-selftest.py` — 22/22.
- [x] 4.3 `openspec validate --all --strict --no-interactive` passes.
- [x] 4.4 `npm run paper:check` — builds, all references resolve.
- [x] 4.5 Read `docs/motivation.md` against `README.md:1-31` and `paper/main.md:13-23`. One problem
      statement, one slogan, one claim set. If a reader could form two impressions of what the tool
      is for, the consolidation has not happened.
- [x] 4.6 Every claim in the document is built, specified in `openspec/specs/`, or labelled a gap.
      No fourth category.
- [x] 4.7 Confirm no number appears in `## Practice` that was not supplied, and that no individual
      is named.

## Notes

Verified 2026-09-11 on `openspec-and-paper`.

- **1.11** — the document cites only the three primary sources, each by URL:
  `chen2026brainresearcher` and `botes2026lawinsidemachine` are verified records;
  `macdonald2026stamped` carries a `TODO` on author order and report number, which is a
  bibliographic detail and not a claim the document rests on. The nine placeholder entries for
  integrated standards are not cited here, so none needed verifying for this change. `docs/` cites
  in prose with links rather than `@key`, matching `docs/references/index.md`; the BibTeX file stays
  the single source of truth for `paper/`.
- **3.1 / 3.2** — landed as a new `check_marketplace_claims()` rather than inside
  `check_doc_claims()`. The two functions read different files and the existing one is documented as
  "the README's mechanically checkable claims"; folding a marketplace check into it would have made
  that comment false. Both are called from `main()` in sequence.
- **3.1** — the closed set had to be expressed as names, not letters. `STAMPED_LETTERS` is
  `set("STAMPED")`, which is correct for frontmatter where the value *is* a letter, but marketplace
  prose names principles ("Distributability", "Self-containment"). A new `STAMPED_NAMES` map covers
  both the noun and adjective forms and maps each to its letter, so the two spellings the repository
  already uses both pass.
- **3.3** — the two cases fire for exactly their own reason: `names 'STAMPED Metadata', which is not
  one of the seven principles` and `claims 2 workflow-plane planners; 6 plugins on disk contain a
  'plane: workflow' skill`. Suite is 22/22; the pristine-repo control stays clean.
- **4.1–4.4** — lint 0/0 over 13 plugins, 42 skills, 6 agents; selftest 22/22; `openspec validate`
  27/27; `paper:check` builds with all references resolving. Also re-ran `validate-ledger.py`
  (VALID) and `check-bench-fixtures.py` (4 probes, 1 suite, 27 tasks, clean), neither of which this
  change touches.
- **4.5** — README, marketplace and `paper/main.md` now open from the same premise in the same order:
  governance as a by-product, assistants outrunning the record, then the tooling mismatch as why
  existing configurations do not answer it. "First-class" survives in README priority 4 and in the
  motivation document, in both cases as what the by-product commitment delivers rather than as a
  second motto.
- **4.7** — `## Practice` contains no digit, and names the programme and the role without naming any
  individual. The internal institutional initiative is described and deliberately left unnamed.
- **2.9** — `paper/sections/01-intro.md` is still a comment skeleton, so there was nothing to
  contradict. Added a note at its head pointing drafting at `docs/motivation.md` while stating that
  the section must carry its own prose rather than link outward.
