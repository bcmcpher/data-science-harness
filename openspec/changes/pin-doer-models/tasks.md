## 1. Validate before anything declares the field

- [ ] 1.1 Add an allowed-model set to `tests/lint-plugins.py` beside `STAMPED_LETTERS` and `PLANES`.
- [ ] 1.2 Extend `check_agent` to error on a `model:` value outside the set.
- [ ] 1.3 Extend `check_agent` to error when a mutating doer declares `model:` at all.
- [ ] 1.4 Add a selftest case in `tests/lint-plugins-selftest.py` injecting an invalid value.

## 2. Translate at install time

- [ ] 2.1 Extend `install_agent_for_opencode` in `bin/install.sh` to map `model:` to the
      provider-prefixed form OpenCode expects.
- [ ] 2.2 Strip `model:` when no mapping exists for the target, so the agent falls back to the default
      rather than failing to load.
- [ ] 2.3 Leave the Claude Code path passing the authored value through unchanged.
- [ ] 2.4 Verify with `bin/install.sh --harness opencode --dry-run` and by inspecting an installed copy.

## 3. Document the field

- [ ] 3.1 Add `model:` to the optional-field comment block in `templates/skill/SKILL.md`.
- [ ] 3.2 Add it to the README's Universal Skill Format section with the allowed values.

## 4. Only now, pin

- [ ] 4.1 Pin `model:` on `plugins/bids/agents/bids-doer.md`.
- [ ] 4.2 Pin `model:` on `plugins/project/agents/coordinator.md`.
- [ ] 4.3 Leave `datalad-doer`, `archive-doer`, `containers-doer`, and `nipoppy-doer` unpinned.

## 5. Resolve the symbolic value

- [ ] 5.1 `docs/writing/SPEC.md:72` declares `model: strong-writing`, which is not a real identifier.
      Either replace it with an allowed value or mark it explicitly as a placeholder in a spec that
      is not a live file.

## 6. Verify

- [ ] 6.1 `python3 tests/lint-plugins.py` and `python3 tests/lint-plugins-selftest.py` both clean.
- [ ] 6.2 An OpenCode-installed `bids-doer` has a resolvable `model:` or none at all.
