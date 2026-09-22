## 1. Lint

- [ ] 1.1 Add `PERIPHERAL_BINARIES` closed set and a span counter (inline spans + fenced-block lines, first token only) to `tests/lint-plugins.py`; error per span in workflow-plane bodies
- [ ] 1.2 Selftest: an error case injecting `` `nipoppy process --pipeline x` `` into `analyze/checkpoint`; a negative check that a `datalad save` span passes
- [ ] 1.3 Before the rewrites, confirm the check reports exactly the 20 spans / 7 skills recorded in design.md (recount after `native-datalad-planners` lands)

## 2. Rewrite the seven planners

- [ ] 2.1 `process/run-pipeline` and `curate/raw-to-bids`: nipoppy requests in words; keep pipeline/version/step/scope, simulated preview, inputs/outputs
- [ ] 2.2 `disseminate/executable-article`: build/check requests to the compendium doer in words
- [ ] 2.3 `disseminate/liab-deploy`: plan/deploy requests to the liab doer in words; keep the dry-run-before-deploy rule
- [ ] 2.4 `curate/annotate`, `curate/gen-data-dict`, `curate/deidentify`: backend requests in words
- [ ] 2.5 Review each rewrite against the target doer's "Parse the request" fields; nothing dropped

## 3. Docs and template

- [ ] 3.1 `templates/skill/SKILL.md`: a doer request in intent form; convention comment states the rule and that DataLad is written directly
- [ ] 3.2 `README.md` Axis 1: reword "never calls a CLI directly" to the enforced rule; note the binary set in the Contributing steps (a new toolbox adds its binary)
- [ ] 3.3 `docs/motivation.md` Architecture: the three-layer finding, environment deferred to providers, `project/env-check` as the seam
- [ ] 3.4 `python3 tests/lint-plugins.py --strict` and the selftest pass
