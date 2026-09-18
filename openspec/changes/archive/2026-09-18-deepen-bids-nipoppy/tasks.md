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

- [x] 2.1 Split `plugins/nipoppy-cli/skills/` into command-class skills. **Four, not three.** The
      task said read-only, mutating and setup; the doer actually distinguished a fourth —
      *bookkeeping writes* (`track-curation`, `track-processing`), which write derived state files
      and so are neither a query nor a computation. Folding them into the read-only skill would have
      made "read-only" false; folding them into the mutating one would have sent a status refresh
      through `datalad run`, recording a run whose inputs are the whole dataset and burying the runs
      that matter. The spec delta was corrected to name the four classes the doer distinguishes
      rather than the three this task assumed.
      `nipoppy-query` (`status`, `pipeline search`, `pipeline list`) runs directly and saves nothing.
      `nipoppy-track` runs directly, reports the files written and hands the save back as a
      checkpoint. `nipoppy-compute` (`reorg`, `bidsify`, `process`, `extract`) constructs, simulates,
      declares inputs and outputs and **refuses to execute** — `result: constructed` is its success.
      `nipoppy-setup` (`init`, the `pipeline` subgroup) writes declarations rather than data.
      The split is by class because the handling rule is a property of the class, not of the verb.
- [x] 2.2 `plugins/nipoppy-cli/.claude-plugin/plugin.json` lists all four, 0.1.0 → 0.2.0, with the
      description naming the classes. The eight reference files moved from
      `skills/nipoppy-cli/references/` to the plugin-level `references/`, matching `datalad-cli`'s
      layout, so all four skills read the same material; `plugins/nipoppy-cli/README.md` and the
      marketplace entry were rewritten. 68 → 71 skills.
- [x] 2.3 The doer's inline classification is now a four-row table naming the skill per class, and it
      gained the rule the spec delta asks for: **a command that fits none of the four classes is not
      the doer's to run** — it reports which class it believes the command falls into, and why, and
      asks the planner before executing anything that could write. Its `class:` report field gained
      `setup`, and its dataset-state check now says `config.json`, matching the bundled references
      rather than a filename recalled from a different nipoppy version.
      **No e2e coverage was added, and nipoppy still has none.** The doer and all four skills are
      prompts, and nipoppy is not installed here. The split is enforced by the lint's bidirectional
      registration and by nothing else.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` and `python3 tests/lint-plugins-selftest.py` both
      clean — 0 errors, 0 warnings at 21 plugins / 71 skills; 24/24.
- [x] 4.2 `tests/e2e-smoke.sh` — 99 passed. Section 1 added the gated BIDS block; section 2 added
      nothing, because nipoppy is not installed here and every skill in the toolbox is a prompt.
      **nipoppy still has zero behavioural coverage**, which the doer's own table does not disguise.
- [x] 4.3 `npm run spec:validate`, `python3 tests/check-bench-fixtures.py` (clean at 42; no planner
      was rewired, so no fixture moved) and the OpenCode install of `nipoppy`/`nipoppy-cli`, which
      lists all four skills.
- [x] 4.4 **Section 3 left this change.** The guideline references became
      `add-guideline-references`, and the `disseminate` spec delta went with them. The reason is the
      one this change's own section 0 predicted: it is a references change bundled into a toolbox
      change, and it grew. Verifying the four guidelines' redistribution basis produced a result that
      needs its own argument — two of them cannot be bundled at all — and CONSORT 2010 turned out to
      be superseded. Sections 1 and 2 are complete and unaffected.
