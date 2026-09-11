## 0. Minimal working core

**Section 1 alone.** It is already self-gating: 1.5 requires a clean lint before section 2 starts.

Deferred: the `nipoppy-cli` split (section 2) and the guideline references (section 3). These are
independent of section 1 and of each other. Section 3 in particular is a references change bundled
into a toolbox change - if it grows, it belongs in its own change rather than here.

## 1. bids first, verified before moving on

- [ ] 1.1 `plugins/bids-cli/skills/bids-validator/SKILL.md` — `user-invocable: true`, `argument-hint`,
      scoped `allowed-tools`.
- [ ] 1.2 `plugins/bids-cli/.claude-plugin/plugin.json` and a marketplace entry.
- [ ] 1.3 Point `plugins/bids/agents/bids-doer.md` at the toolbox skill instead of inlining the
      invocation; leave the read-only contract untouched.
- [ ] 1.4 Add a gated BIDS validation assertion to `tests/e2e-smoke.sh`.
- [ ] 1.5 `python3 tests/lint-plugins.py` clean before starting section 2.

## 2. nipoppy

- [ ] 2.1 Split `plugins/nipoppy-cli/skills/` into read-only, mutating, and setup command-class skills.
- [ ] 2.2 Update `plugins/nipoppy-cli/.claude-plugin/plugin.json` to list them all — the lint requires
      bidirectional registration.
- [ ] 2.3 Replace the doer's inline command knowledge with a toolbox table naming the skill per class.

## 3. Guideline references

- [ ] 3.1 Expand `plugins/disseminate/references/` with per-guideline EQUATOR files (CONSORT, STROBE,
      PRISMA, ARRIVE), each stating what it contains and linking the authoritative version.
- [ ] 3.2 Add a COBIDAS reference set for the neuroimaging path.
- [ ] 3.3 Rewrite `plugins/disseminate/skills/reporting-checklist/SKILL.md` to read items from the
      reference files and to refuse when the applicable guideline is not bundled.
- [ ] 3.4 Point `plugins/govern/skills/qc-review/SKILL.md` at the COBIDAS reference for its
      neuroimaging checks.

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py` and `python3 tests/lint-plugins-selftest.py` both clean.
- [ ] 4.2 `tests/e2e-smoke.sh` passes with the new gated assertions.
- [ ] 4.3 Every new reference file names its authoritative source and its redistribution basis.
