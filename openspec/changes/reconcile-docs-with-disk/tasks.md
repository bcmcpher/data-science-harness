## 1. Correct the wrong facts

- [ ] 1.1 `README.md:171` — "Eleven plugins" → the actual count, and correct the capability/workflow
      split alongside it.
- [ ] 1.2 Replace all 8 `plugin.yaml` references with `.claude-plugin/plugin.json`, including the
      Plugin Manifest section and Contributing step 4, and show the manifest's real shape.
- [ ] 1.3 Reconcile `.claude-plugin/marketplace.json`'s STAMPED expansion with `docs/stamped.md`;
      `docs/stamped.md` is authoritative because the lint validates skill `stamped:` letters against it.

## 2. Mark aspirational content as planned

- [ ] 2.1 Split the Plugins tables into built and planned, so `publish`, `annotate`, and the ~13
      unbuilt workflow skills are visibly not present yet.
- [ ] 2.2 Mark the `harness.yaml` Root Manifest section as planned.
- [ ] 2.3 Mark `analyze/literature-search` (`README.md:228`) as planned.
- [ ] 2.4 Regenerate the Project Ledger example from `examples/project.yaml` so it validates against
      `schemas/project.schema.json`, and note that the richer shape is aspirational.

## 3. Fix omissions

- [ ] 3.1 Update the Repository Structure block: add `docs/writing/`, `docs/references/`,
      `docs/project-ledger.md`, `docs/evaluation.md`, `examples/`, `openspec/`, `bench/`, `paper/`,
      `.github/workflows/`, `tests/lint-plugins-selftest.py`, and `tests/check-bench-fixtures.py`.
- [ ] 3.2 Add OpenCode to the Install section, and state that `bin/install.sh` defaults to it.

## 4. The end-to-end walkthrough

- [ ] 4.1 `docs/end-to-end-workflow.md` Phase 0 — replace `pip install ds-harness` and
      `ds-harness install --harness=...` with `bin/install.sh`, which is what exists. This is the
      first command a new user runs and it currently fails.
- [ ] 4.2 Mark every skill the walkthrough names that is not on disk, using the same built-versus-
      planned distinction section 2 applies to the README. 28 of 48 plugin-qualified references are
      absent; `python3 -c` over `plugins/*/skills/*/SKILL.md` regenerates the list.
- [ ] 4.3 Correct the references that name the wrong plugin rather than a missing skill:
      `datalad/datalad-run`, `datalad/datalad-save`, `datalad/datalad-log` and
      `datalad/datalad-container-run` live in `datalad-cli`; `datalad/checkpoint` is
      `analyze/checkpoint`; `project/obligations` is `govern/obligations`. These are wrong, not
      aspirational, and they are the ones that will send a reader to a file that exists under
      another name.
- [ ] 4.4 Leave the ⚠️ Scaffolding gap and 🔧 Do-it-yourself callouts untouched. They are the part
      of this document that is already honest, and they are load-bearing.

## 5. Catch it next time

- [ ] 5.1 Add the doc-claims check to `tests/lint-plugins.py`, scoped to the manifest filename and the
      plugin count.
- [ ] 5.2 Add the corresponding selftest case.

## 6. Verify

- [ ] 6.1 `grep -c 'plugin\.yaml' README.md` → 0.
- [ ] 6.2 `python3 schemas/validate-ledger.py` passes against the ledger example as written in the README.
- [ ] 6.3 `python3 tests/lint-plugins.py` and `python3 tests/lint-plugins-selftest.py` both clean.
- [ ] 6.4 Follow the Contributing steps end to end for a throwaway skill and confirm they work.
- [ ] 6.5 Every plugin-qualified skill reference in `docs/end-to-end-workflow.md` either resolves
      to a file on disk or sits under a planned marker.
