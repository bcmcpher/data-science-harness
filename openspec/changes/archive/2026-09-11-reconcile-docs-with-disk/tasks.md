## 1. Correct the wrong facts

- [x] 1.1 `README.md:171` — "Eleven plugins" → the actual count, and correct the capability/workflow
      split alongside it.
- [x] 1.2 Replace all 8 `plugin.yaml` references with `.claude-plugin/plugin.json`, including the
      Plugin Manifest section and Contributing step 4, and show the manifest's real shape.
- [x] 1.3 Reconcile `.claude-plugin/marketplace.json`'s STAMPED expansion with `docs/stamped.md`;
      `docs/stamped.md` is authoritative because the lint validates skill `stamped:` letters against it.

## 2. Mark aspirational content as planned

- [x] 2.1 Split the Plugins tables into built and planned, so `publish`, `annotate`, and the ~13
      unbuilt workflow skills are visibly not present yet.
- [x] 2.2 Mark the `harness.yaml` Root Manifest section as planned.
- [x] 2.3 Mark `analyze/literature-search` (`README.md:228`) as planned.
- [x] 2.4 Regenerate the Project Ledger example from `examples/project.yaml` so it validates against
      `schemas/project.schema.json`, and note that the richer shape is aspirational.

## 3. Fix omissions

- [x] 3.1 Update the Repository Structure block: add `docs/writing/`, `docs/references/`,
      `docs/project-ledger.md`, `docs/evaluation.md`, `examples/`, `openspec/`, `bench/`, `paper/`,
      `.github/workflows/`, `tests/lint-plugins-selftest.py`, and `tests/check-bench-fixtures.py`.
- [x] 3.2 Add OpenCode to the Install section, and state that `bin/install.sh` defaults to it.

## 4. The end-to-end walkthrough

- [x] 4.1 `docs/end-to-end-workflow.md` Phase 0 — replace `pip install ds-harness` and
      `ds-harness install --harness=...` with `bin/install.sh`, which is what exists. This is the
      first command a new user runs and it currently fails.
- [x] 4.2 Mark every skill the walkthrough names that is not on disk, using the same built-versus-
      planned distinction section 2 applies to the README. 28 of 48 plugin-qualified references are
      absent; `python3 -c` over `plugins/*/skills/*/SKILL.md` regenerates the list.
- [x] 4.3 Correct the references that name the wrong plugin rather than a missing skill:
      `datalad/datalad-run`, `datalad/datalad-save`, `datalad/datalad-log` and
      `datalad/datalad-container-run` live in `datalad-cli`; `datalad/checkpoint` is
      `analyze/checkpoint`; `project/obligations` is `govern/obligations`. These are wrong, not
      aspirational, and they are the ones that will send a reader to a file that exists under
      another name.
- [x] 4.4 Leave the ⚠️ Scaffolding gap and 🔧 Do-it-yourself callouts untouched. They are the part
      of this document that is already honest, and they are load-bearing.

## 5. Catch it next time

- [x] 5.1 Add the doc-claims check to `tests/lint-plugins.py`, scoped to the manifest filename and the
      plugin count.
- [x] 5.2 Add the corresponding selftest case.

## 6. Verify

- [x] 6.1 `grep -c 'plugin\.yaml' README.md` → 0.
- [x] 6.2 `python3 schemas/validate-ledger.py` passes against the ledger example as written in the README.
- [x] 6.3 `python3 tests/lint-plugins.py` and `python3 tests/lint-plugins-selftest.py` both clean.
- [x] 6.4 Follow the Contributing steps end to end for a throwaway skill and confirm they work.
- [x] 6.5 Every plugin-qualified skill reference in `docs/end-to-end-workflow.md` either resolves
      to a file on disk or sits under a planned marker.

## Notes

- **1.1** —Now **13 plugins**, 7 capability / 6 workflow. Stated as a numeral so task 5.1's check can read it.
- **1.2** —0 remain (`grep -c` verifies). The Plugin Manifest section is rewritten around the real `plugin.json`, and notes that `plane`/`stamped`/`delegates_to` live in skill frontmatter, not the manifest — a skill copied out of its plugin must still know its plane.
- **1.3** —marketplace.json now reads Self-contained, Tracked, Actionable, Modular, Portable, Ephemeral, Distributable. Its doer list was also stale (named 3, there are 5).
- **2.1** —Capability and workflow tables split built/planned; each planned plugin links its OpenSpec change. `publish` and `annotate` are gone from built — on disk they are `archive` and unbuilt respectively. `process` was missing entirely and is now listed.
- **2.2** —Marked planned, with a note that `.claude-plugin/marketplace.json` does the job today.
- **2.3** —Marked, along with the other 12 unbuilt workflow skills, inline per bullet.
- **2.4** —Replaced with `examples/project.yaml` verbatim. Verified by extracting the README's fenced block and running the validator over it (task 6.2).
- **3.1** —Added openspec/, paper/, bench/, docs/references/, docs/writing/, the four new tests/, the manifests, and .github/workflows/.
- **3.2** —Added the flag list and the statement that a bare invocation installs every plugin for OpenCode at project scope — confirmed against `HARNESS="opencode"` in bin/install.sh.
- **4.1** —Phase 0 now clones and runs `bin/install.sh`. The absent CLI is recorded as a ⚠️ callout rather than silently dropped, since it is a real gap.
- **4.2** —17 unbuilt references marked across 28 occurrences; a legend at the top says what the marker means.
- **4.3** —6 corrected: four `datalad/datalad-*` to `datalad-cli/`, `datalad/checkpoint` to `analyze/checkpoint`, `project/obligations` to `govern/obligations`. Separately, the capability-plane references (`bids/bids-validate`, `nipoppy/nipoppy-bidsify`, `containers/build-container`) were rewritten to name the doer — those operations exist, they just are not named skills.
- **4.4** —Untouched.
- **5.1** —`check_doc_claims` errors on any `plugin.yaml` mention and on a `**N plugins**` count that disagrees with disk.
- **5.2** —Two cases, both asserting the error. The sandbox has no README, so each case writes one — which also pins that the check skips cleanly when none exists. 20/20.
- **6.1** —0.
- **6.2** —Passes against the block as written in the README.
- **6.3** —Both clean.
- **6.4** —Done in a throwaway copy. After step 3 the lint errors with "exists on disk but is not listed in `skills[]` — it will not load"; after step 4 it is clean at 43 skills. The template's commented optional fields uncomment to valid frontmatter.
- **6.5** —Verified programmatically — no unmarked absent reference remains.
