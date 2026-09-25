## Context

After `datalad-ambient-layer`, every session inside a dataset has the DataLad rules and the dataset
status in the main thread, and guards against `git commit` and `git push`. The datalad doer is then
a pure indirection:

- 37 planners declare `delegates_to: [datalad, …]`;
- six other doers hand commands to it;
- 10 specs name it.

The ledger `log` duplicates commit messages. `examples/project.yaml` shows entries whose `note` is
the commit message restated. The coordinator's rule "if the log and DataLad history disagree,
report the discrepancy" exists only because there are two records.

Verified on 2026-09-22 with DataLad in the conda `datalad` env: the subject line of a
`datalad run` commit is prefixed `[DATALAD RUNCMD]`, and a `=== Do not change lines below ===`
JSON record is appended. As a result, `git log --format='%(trailers)'` returns **nothing** for
`DSH-*` lines placed in a run message. On a plain `datalad save` commit, the same lines parse as
git trailers.

## Goals / Non-Goals

**Goals:**
- One record of activity: the commit history, which DataLad already makes authoritative.
- Planners use DataLad the way code uses git: directly, briefly, correctly.
- Fewer skills competing for the trigger decision (19 → 1 in the toolbox).
- Existing ledgers keep validating, and their history stays readable.

**Non-Goals:**
- Re-scoping tool-intent rules for non-core tools (that is `planner-intent-delegation`, which
  follows).
- Changing what state `project.yaml` holds: products, obligations and contributors are unchanged.
- A reconciliation or drift-check skill. That is the natural next step, and it will read
  `dsh-log`, but it is out of scope here.

## Decisions

**D1. `DSH-*` lines, parsed by the harness, not by git.** The vocabulary is closed:

| Key | Cardinality | Meaning |
|---|---|---|
| `DSH-Op` | exactly 1 | the skill name |
| `DSH-Stage` | 0–1 | the lifecycle stage |
| `DSH-Binding` | 0–n | `doer/tool@version`, copied from a doer's structured result |
| `DSH-Product` | 0–n | a product id |
| `DSH-Obligation` | 0–n | `<id> opened\|resolved` |

The lines sit in the message body after a blank line. `dsh-log.sh` reads each commit with
`git log --format='%H%x1f%aI%x1f%B%x1e'` and stops at `=== Do not change lines below ===`. It
collects `^DSH-[A-Za-z]+: ` lines and prints one JSON object per commit: `sha`, `ts`, `subject`,
`run` (bool) and the fields. With `--legacy` it also prints the `project.yaml` `log` entries in
the same shape, with `sha: null`.

*Alternative: git trailers.* Rejected. They are invisible on run commits (verified above).

*Alternative: git notes.* Rejected. Notes are not pushed or cloned by default, so the record would
not travel with the dataset.

*Alternative: keep the YAML log.* Rejected by the user. It is the drift this change removes.

**D2. `log` stays in the schema as optional and legacy.** It is removed from `required`. Its
description is marked legacy: no skill writes it, and `dsh-log --legacy` reads it. This avoids a
migration step and keeps every existing ledger valid. `resolved_by` accepts a commit SHA
(preferred), a legacy log timestamp, or a product id.

**D3. Decisions become files.** `log-decision` has no file change to commit once `log` is
retired, and `datalad save` refuses an empty save. The decision is therefore written to
`docs/decisions/<YYYY-MM-DD>-<slug>.md`, with decision, rationale, alternatives and scope, and
saved with `DSH-Op: log-decision`. This is ADR-shaped, reviewable, and travels with the dataset.

**D4. Status is read-only.** `status-report` currently appends a log entry for a read. After this
change it writes nothing and commits nothing. If the user asks for a saved report, it writes
`reports/status-<date>.md` and saves that.

**D5. Planners run DataLad in the main thread, and stay terse.** A save step reads:

    datalad save -m "$(printf '<what> — <why>\n\nDSH-Op: <skill>\nDSH-Stage: <stage>')"

This must be a **single** `-m`. It was verified on 2026-09-22 that `datalad save -m a -m b` keeps
only `b`, silently dropping the subject, unlike git. Run steps use the same form. In a save commit
the lines are then the final paragraph, and valid git trailers too. The always-loaded rules carry
the pattern, so planners don't repeat an explanation of it. `dsh-guard.sh` (from
`datalad-ambient-layer`) gains a warning for a repeated `-m` on `datalad save` or `datalad run`.

**D6. Doers stop at the command.** Each remaining doer's result gains `run_via: planner`, meaning
the planner runs it under `datalad run`, or `save_via: planner`, meaning the doer wrote files and
the planner saves them. Every doer's result also carries `binding`, so the planner can emit a
`DSH-Binding` line. For nipoppy, `run_via: datalad-run` already exists; the value keeps its
meaning, but the executor becomes the planner.

**D7. The toolbox becomes one skill with per-verb references.** `plugins/datalad-cli/skills/datalad/SKILL.md`
routes by verb to `references/verbs/<verb>.md`. The 19 per-verb skills become those files, and
their constraints are kept verbatim. The existing shared references stay. The skill's description
keeps the "inside a DataLad dataset, instead of git add/commit" trigger.

**D8. The retired term is linted.** An error fires for "datalad doer" or `datalad-doer` anywhere
under `plugins/`, `templates/`, or `docs/` (but not `docs/talk/`, which is not versioned), so the
old instruction cannot creep back in. Archived OpenSpec changes are exempt.

## Risks / Trade-offs

- [The main thread's context grows with DataLad detail formerly isolated in the doer] → Only the
  rules (≤ 300 words) are always loaded. Verb detail loads on demand from the one skill, and quiet
  output flags cap command noise.
- [Losing per-verb slash commands such as `/datalad-save` breaks user muscle memory] →
  `/datalad save …` covers them. The README lists the mapping.
- [Planners forget the `DSH-*` lines] → The e2e smoke test asserts them for every exercised
  planner. A later reconciliation check can flag harness commits that lack `DSH-Op`.
- [37-file edit churn] → The edit is mechanical and done in one pass. The lint's retired-term
  check and the e2e test catch misses.
- [Other harnesses without hooks rely only on the rules file] → That is accepted in
  `datalad-ambient-layer`. The planners themselves carry the literal DataLad commands, so they
  work with no ambient layer at all.

## Migration Plan

Land this after `datalad-ambient-layer`. Users reinstall. `plugins/datalad/` disappears, and an
installer run with `--prune` removes an installed `datalad-doer` (task 7.3). Existing
`project.yaml` files validate unchanged, and their `log` history appears in `dsh-log --legacy`.
Rollback means reverting the change, since no data format is destroyed.

## Open Questions

- Should `dsh-log` output also be available as a planner-facing skill (e.g. `project/history`),
  or stay a script used by the coordinator and status-report? It is a script for now.
