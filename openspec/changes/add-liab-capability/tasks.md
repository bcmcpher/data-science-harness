## Status

Section 0's minimal working core shipped 2026-09-17: the doer, `pyinfra` in plan-only mode, the
planner rewired, and the plan path asserted. `forgejo` (2.2) remains, so this change stays open.

## 0. Minimal working core

The doer (1.1-1.4) plus **`pyinfra` in plan-only mode** (2.1, 2.3), with the planner rewired
(3.1-3.2) and verified (4.1-4.3). A plan that names its target host and touches no network is the
smallest thing that demonstrably works, and 4.3 already states that the apply path is exercised
manually rather than by the suite.

Deferred: `forgejo` (2.2).

## 1. The liab doer

- [x] 1.1 Write `plugins/liab/agents/liab-doer.md`: parse request, build inventory, plan, confirm
      target, apply, verify sibling, report. No `model:` — it changes hosts and a dataset.
- [x] 1.2 Make plan-by-default and the target-naming confirmation explicit constraints, not prose
      suggestions. Both are constraints, and the doer opens by saying why: it is the only doer whose
      mistakes are not confined to a working tree. Step 5 is literally "Stop" — a plan is a complete
      deliverable, and an apply is a separate turn. "Yes" is explicitly not confirmation; the
      hostname is.
- [x] 1.3 State the partial-application reporting rule and the no-automatic-retry rule. A third
      distinction was needed and added: **`applied` is not `working`.** A green pyinfra run means the
      operations applied, not that the service serves — only a `datalad get` that retrieves annexed
      content from the self-hosted remote earns `working`, which is the standard
      `disseminate/publish` already applies to a cloud sibling. Collapsing the two is how a
      half-configured box becomes the place the data gets pushed.
- [x] 1.4 `plugins/liab/.claude-plugin/plugin.json`.

## 2. The liab-cli toolbox

- [x] 2.1 `plugins/liab-cli/skills/pyinfra/SKILL.md` — defaults to a plan; `allowed-tools` scoped.
      Names the trap plainly: pyinfra's flag is `--dry`, and a run *without* it is an apply.
- [ ] 2.2 `plugins/liab-cli/skills/forgejo/SKILL.md` — instance setup and repository/remote creation.
- [x] 2.3 `plugins/liab-cli/.claude-plugin/plugin.json` and marketplace entries for both plugins.
- [x] 2.4 **Added during implementation:** `plugins/liab-cli/scripts/check-tools.sh`. It verifies
      pyinfra **runs**, not just that the command exists, so a broken entry point is a clean stop
      rather than a failure part-way through a deployment. It prints what it did **not** check — host
      reachability, SSH access, whether the inventory names the intended hosts — **on the `available`
      path as well as the unavailable one**, because a green check is exactly when someone mistakes
      it for deployment readiness. (The first version printed that caveat only when unavailable; the
      e2e caught it.) A request for `forgejo` is exit 2, not `unavailable`.

## 3. Rewire the planner

- [x] 3.1 `plugins/disseminate/skills/liab-deploy/SKILL.md` → `delegates_to: [liab, datalad]`, with
      prose naming the doer. The planner gained a step 3 that gets a plan and **stops**, and is told
      the user's approval of a plan is not approval to apply. Its old "never run pyinfra" constraint
      was imprecise once a doer exists, and now distinguishes a plan (delegable, safe by
      construction) from an apply (not the planner's to request).
- [x] 3.2 Add the "record what was deployed, do not claim compliance" constraint to the skill body.
      Self-hosting is not by itself a compliance outcome — data residency, institutional policy and
      DUA terms are governance judgments made by a person against the ledger's obligations, and a
      deployment record that reads as though it settled them is worse than no record.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings; 21 plugins, 53 skills,
      9 agents.
- [x] 4.2 e2e assertion: a `--dry` plan against an `@local` inventory, asserting the plan names its
      operation **and that the directory the deploy would have created does not exist afterwards** —
      the plan changed nothing. `@local` is the only target a test may name; planning against a real
      hostname would itself be the network operation being ruled out. Verified by installing pyinfra
      in a throwaway venv and watching all three assertions pass, rather than committing assertions
      never seen to run. e2e 90 -> 95 with pyinfra absent (the three plan assertions skip), 98 with it.
- [x] 4.3 The doer carries a closing **"Verification gap, stated rather than implied"** section: the
      suite covers the plan path only, the apply path is exercised by hand because it needs a
      disposable host, and a green suite must not be read as coverage of an apply.
- [x] 4.4 **Added:** the `disseminate-liab` routing fixture updated to `[liab, datalad]`, caught by
      `tests/check-bench-fixtures.py` in the same pass.
