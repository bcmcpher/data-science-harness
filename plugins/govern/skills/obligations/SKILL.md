---
name: obligations
description: >
  Track the project's outstanding commitments in the Manage & Comply lane — pre-registered
  confirmatory comparisons, DMP/ethics deliverables, funder reports — and resolve them as they are
  met. Trigger on "what do I owe", "outstanding obligations", "what's due", "list obligations",
  "mark this obligation done", "add an obligation", "confirmatory comparisons still to run",
  "compliance deadlines". Reads/updates the ledger obligations[] registry.
plane: workflow
stamped: [T]
---

# Skill: obligations

Maintain the project's **obligations** — the commitments it must discharge (a frozen confirmatory
comparison that must be run as specified, a Data Management Plan deliverable, an ethics amendment, a
funder report due by a date). This is the "to-do list of promises" of the Manage & Comply lane,
tracked in the ledger `obligations[]` so the administrative record is provenanced alongside the
science. You own the tracking judgment, and you save it yourself with `datalad save`.

## When to use
- The user wants to see what is outstanding/overdue, add a new commitment, or mark one met/waived.
- Do NOT use to *create* a pre-registration (that is `govern/preregister`, which adds the
  obligation) or to run the confirmatory analysis (`analyze/run-comparison`).

## Steps
1. **Read the current obligations** — from `project.yaml` `obligations[]`. Present a concise
   surface: what is `pending` (highlight anything with a `due` date that is near or past), what is
   `met`, what is `waived`. Group by `kind` (preregistration, confirmatory-comparison, dmp, ethics,
   funder-report).
2. **Act on the request**:
   - **Add** — append `{ id, kind, description, due?, status: pending, ref? }` (unique `id`).
   - **Resolve** — flip an entry's `status` to `met` (the commitment was fulfilled — e.g. the
     confirmatory comparison was completed as specified) or `waived` (dropped, with the reason
     stated in the commit message). **Never delete** an obligation; the record of the commitment
     stays.
   - **Update** — add a `ref` once a pending registration is assigned an id/URL, or adjust a `due`.
3. **Save and record in one step** — the commit is the record; nothing is appended to a log.
   ```bash
   datalad save -m "$(printf 'obligations: <added|met|waived> <id> — <why>\n\nDSH-Op: obligations\nDSH-Stage: govern\nDSH-Obligation: <id> opened|resolved')" project.yaml
   ```
   Use `opened` when adding, `resolved` when flipping to `met` or `waived`. Use exactly one `-m`.
4. **Report** — the updated surface, and the next thing due (by date, then by kind). If a
   confirmatory-comparison obligation is still pending, point to `analyze/run-comparison`; if a
   pre-registration lacks a `ref`, point to `govern/preregister`.

## Constraints
- Obligations are never deleted — resolution is a forward `status` change (`pending` → `met`/`waived`)
  with the reason captured in the commit message. This preserves the compliance trail.
- Keep `obligations[]` ids unique; add/resolve per `docs/project-ledger.md`.
- Do not silently mark a confirmatory obligation `met` — confirm the comparison was actually run as
  specified (any deviation from the frozen spec is reportable, not a quiet pass).
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`. Save with
  `datalad save` yourself.
