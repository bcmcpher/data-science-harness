## Status

The three skills landed in `29d1532`; this change records the reasoning, the spec delta and the
routing fixtures that pass deliberately left undone. Complete as of 2026-09-18. Ready to archive.

## 0. Minimal working core

All of it, and most of it is already on disk. Three planner skills over the `datalad` doer, which
exists. What this change adds is the half `29d1532` skipped: `openspec/specs/project-mgmt` deltas,
three routing tasks, and the workflow document's marker cleanup.

Deliberately **not** here: a `requires:` field in the skill format, any install action, and a
parallel `milestones[]` registry. The first is a `skill-format` change; the second would destroy the
finding `env-check` exists to report; the third was settled against in
`extend-ledger-for-planned-skills`.

## 1. The skills

- [x] 1.1 `plugins/project/skills/track-milestone/SKILL.md` — `stamped: [T]`, `delegates_to:
      [datalad]`. A milestone is an `obligations[]` entry with `kind: milestone`, per the shape
      settled in `extend-ledger-for-planned-skills`, so "what's due" has one answer rather than two.
- [x] 1.2 `plugins/project/skills/env-check/SKILL.md` — `stamped: [P, E]`, `delegates_to:
      [datalad]`. Four buckets, not one list: declared+present, declared+absent, present+undeclared,
      declared+unusable.
- [x] 1.3 `plugins/project/skills/claude-config/SKILL.md` — `stamped: [M, P]`, `delegates_to:
      [datalad]`. Writes the *project's* configuration; harness plugins are installed by
      `bin/install.sh` and the two must not be conflated.
- [x] 1.4 Registered in `plugins/project/.claude-plugin/plugin.json`.
- [x] 1.5 **`requires:` does not exist.** `grep -rn '^requires:' plugins/` returns nothing. README
      described `env-check` as verifying it; the skill reads the committed manifests and each
      capability's gate script instead, and README was corrected in `29d1532`. Recorded here because
      the claim stood for months and will look like an omission rather than a decision otherwise.

## 2. The refusals

- [x] 2.1 `track-milestone` **never invents a date** — not from a conference's usual deadline, not
      from a funder's reporting cycle, not from "about three months". A confidently wrong deadline
      in a tracking system is worse than an absent one, because it will be trusted.
- [x] 2.2 `track-milestone` **never silently moves a date.** `due` is updated and the old value,
      the new value and the reason are logged. Overwriting erases the only evidence the timeline
      changed.
- [x] 2.3 `track-milestone` never deletes a milestone and never marks one `met`; the schema requires
      `resolved_by`, and `govern/obligations` owns resolution.
- [x] 2.4 `track-milestone` never duplicates a commitment another `kind` already records.
- [x] 2.5 `env-check` **never reports an undeclared tool as missing, or a missing tool as
      undeclared.** They have opposite fixes: one is a setup step, the other is a `P.1` Portability
      defect, and merging them tells the user to install something when the fix is a manifest line.
- [x] 2.6 `env-check` **never installs anything** and never edits a manifest. Installing a tool to
      make a check pass destroys the finding.
- [x] 2.7 `env-check` **never re-implements a toolbox's gate check** — it runs the script, because a
      second implementation of "is SNOMED configured" will eventually disagree with the one the doer
      acts on. Exit `2` is a usage error, never folded into `unavailable`.
- [x] 2.8 `env-check` never claims the environment is correct, and never prints a credential's value.
- [x] 2.9 `claude-config` **never writes an instruction it could not source from the project**, and
      never overwrites an existing `CLAUDE.md` without showing its content first. The file is loaded
      into every session and treated as authoritative, so a stale line is followed rather than
      questioned.
- [x] 2.10 `claude-config` never writes a credential into a committed file or an MCP stub, and never
      invents a test or lint command — no such command is a finding, not a gap to fill with a guess.

## 3. Wire them into the surrounding documents

- [x] 3.1 `README.md` — three *(planned)* markers dropped and the entries rewritten, in `29d1532`.
      The **Built skills** table and the planner count were reconciled in `complete-analyze-skills`,
      which found them stale in every row.
- [x] 3.2 `openspec/specs/project-mgmt/spec.md` Purpose — "four planner skills" → seven, naming them,
      matching the `govern` precedent.
- [x] 3.3 `docs/end-to-end-workflow.md` — the Stage-0/1 🔧 callouts said `env-check` and
      `claude-config` did not exist and told the reader to write configuration by hand. Both now
      describe what the skills do and, for `env-check`, why it will not install. The Manage & Comply
      lane drops its *(planned)* marker and states the moved-date rule.
- [x] 3.4 Three routing tasks in `bench/tasks/routing-lifecycle.yaml`. 36 → 39. `project-env-check`
      and `project-milestone` carry near-miss notes: one list of "missing tools" loses the
      distinction the skill exists for, and `govern/obligations` resolves commitments rather than
      adding dates.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py --strict` — 0 errors, 0 warnings at 67 skills.
- [x] 4.2 `python3 tests/check-bench-fixtures.py` — clean at 39 tasks.
- [x] 4.3 `npm run spec:validate` — passes with this change present.
- [x] 4.4 `python3 tests/lint-plugins-selftest.py` — 24/24.
- [x] 4.5 `python3 schemas/validate-ledger.py examples/project.yaml` — valid; no schema change.
- [x] 4.6 `bash tests/e2e-smoke.sh` — unchanged at 95. **This change adds no test coverage**, and
      neither did `29d1532`: three skills' operating procedures are prose.
- [x] 4.7 Merged spec diffed after archive — addition only, no scenario dropped.
