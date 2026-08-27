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

## 4. Catch it next time

- [ ] 4.1 Add the doc-claims check to `tests/lint-plugins.py`, scoped to the manifest filename and the
      plugin count.
- [ ] 4.2 Add the corresponding selftest case.

## 5. Verify

- [ ] 5.1 `grep -c 'plugin\.yaml' README.md` → 0.
- [ ] 5.2 `python3 schemas/validate-ledger.py` passes against the ledger example as written in the README.
- [ ] 5.3 `python3 tests/lint-plugins.py` and `python3 tests/lint-plugins-selftest.py` both clean.
- [ ] 5.4 Follow the Contributing steps end to end for a throwaway skill and confirm they work.
