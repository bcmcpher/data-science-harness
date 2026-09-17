## 0. Minimal working core

**Section 1 alone.** It is already self-gating: 1.5 requires a clean lint before section 2 starts.

Deferred: the `nipoppy-cli` split (section 2) and the guideline references (section 3). These are
independent of section 1 and of each other. Section 3 in particular is a references change bundled
into a toolbox change - if it grows, it belongs in its own change rather than here.

## 1. bids first, verified before moving on

Section 1 shipped 2026-09-17. Sections 2 and 3 remain, so this change stays open.

- [x] 1.1 `plugins/bids-cli/skills/bids-validator/SKILL.md` — `user-invocable: true`, `argument-hint`,
      scoped `allowed-tools`.
- [x] 1.2 `plugins/bids-cli/.claude-plugin/plugin.json` and a marketplace entry.
- [x] 1.3 Point `plugins/bids/agents/bids-doer.md` at the toolbox skill instead of inlining the
      invocation; leave the read-only contract untouched. The doer gained a `## Toolbox` table and
      two constraints (never invent an issue code, never report a clean pass without saying what was
      ignored); the read-only contract is unchanged.
- [x] 1.4 Add a gated BIDS validation assertion to `tests/e2e-smoke.sh`. Five assertions plus two
      gated skips; e2e goes 77 → 82.
- [x] 1.5 `python3 tests/lint-plugins.py` clean before starting section 2 — 0 errors, 0 warnings at
      17 plugins / 50 skills.
- [x] 1.6 **Added during implementation:** `plugins/bids-cli/scripts/check-validator.sh`, the offline
      presence check, modelled on `annotate-cli/scripts/check-backends.sh` with the same
      `0 = available / 1 = unavailable / 2 = usage error` contract. Not in the original task list;
      without it the e2e has nothing deterministic to assert, because the doer is a prompt.

### What section 1 discovered

The original proposal treated the validator as one tool. There are **two** that validate a dataset —
the current `@bids/validator` (Deno/JSR) and the legacy `bids-validator` Node CLI — and they do not
share a command line, so the skill confirms `--help` before trusting a flag rather than translating
between them.

The Python `bids_validator` package is a trap and the gate script deliberately refuses to count it.
It exposes a `BIDSValidator` class that matches a single *filename* against the naming patterns,
installs no console script, and cannot validate a dataset. It is importable on this machine, so the
first version of the check reported `available` and would have green-lit a validation path that does
not exist — the same "green light into nothing" failure the annotate per-backend check was built to
avoid. The e2e asserts the exclusion whenever that package is importable.

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
