---
name: ethics-track
description: >
  Record an IRB or IACUC protocol — its number, approval, expiry and amendments — as a tracked ledger
  obligation, and surface renewals before they lapse. Trigger on "ethics", "IRB", "IACUC", "REB",
  "ethics approval", "protocol number", "ethics amendment", "when does our approval expire",
  "ethics renewal". Do NOT trigger to write a Data Management Plan (govern/dmp), to de-identify data
  (curate/deidentify), or to decide whether a use is permitted under an approval.
plane: workflow
stamped: [M, T]
delegates_to: [datalad]
---

# Skill: ethics-track

Keep the project's ethics approvals in the ledger, so an expiry is a tracked obligation with a date
rather than something someone remembers in the wrong month.

**Read this before anything else: every date and identifier here comes from a document or from the
user. None is inferred.** An approval date does not imply an expiry — approval periods differ by
board, by protocol type and by jurisdiction. A protocol number is not guessable. An amendment's
scope is whatever the board approved, not what the project asked for. This skill is a recorder, and
the one thing it must never do is produce a plausible date.

> Ledger shape, settled in `extend-ledger-for-planned-skills` so it is not re-decided here: an
> approval is an `obligations[]` entry with `kind: ethics`, the **expiry** in `due`, and the protocol
> number or URL in `ref`. The approval date and every amendment are appended to `log:`, where the
> append-only rule already gives an amendment history for free. See `docs/project-ledger.md`
> convention 5.

## When to use
- An approval, renewal or amendment has been granted and needs recording.
- The user asks what is approved, when it expires, or what the amendment history is.
- A downstream step needs to resolve an ethics obligation — `curate/deidentify` does this, by
  moving the entry to `met` with `resolved_by` naming its recording run.
- Do NOT use to judge whether a planned analysis falls inside an approval's scope. Report what the
  approval says and let the researcher and their board decide.

## Steps

1. **Read what is already recorded** — the `kind: ethics` entries in `obligations[]` and the
   `op: ethics-track` entries in `log:`. Present the current state before changing it: which
   protocols, which expiries, what the amendment history is.

2. **Get the facts from the user or a document.** The protocol number, the approving body, the
   approval date, the expiry date, and what the protocol covers. Ask for each you do not have.
   **Do not compute an expiry from an approval date**, and do not assume a one-year term.

3. **Record the approval as an obligation** — `kind: ethics`, `due` = the expiry date,
   `ref` = the protocol number or the board's URL, `description` naming the approving body and what
   is covered, `status: pending`. Pending is correct: an approval that has not yet expired is an
   outstanding commitment to stay within it and to renew on time.

4. **Record the approval date and the scope in `log:`** —
   `{ ts, op: ethics-track, stage: govern, note: "...", branch }`. The note carries the approval date
   and a short statement of scope, because `due` only holds the expiry.

5. **Record an amendment as a new log entry, never as an edit.** An amendment changes what is
   approved; the history of what was approved when is the thing an audit asks for. If the amendment
   changes the expiry, update `due` on the obligation **and** log what changed and when.

6. **Surface upcoming renewals.** Compare each `due` against today and report anything inside a
   window the user cares about (ask; do not assume 60 days). An expired approval is reported as
   expired, plainly — not as "due soon".

7. **Validate and save.**
   ```bash
   python3 schemas/validate-ledger.py project.yaml
   ```
   Then delegate: "save: `datalad save -m 'ethics-track: <action>'`."

8. **Report** the protocols with their expiries, the amendment history, what is expiring or expired,
   and any fact you could not obtain and therefore did not record.

## Constraints

- **Never infer an expiry from an approval date, and never infer an approval date from anything.**
  Approval terms vary by board and protocol type. A wrong expiry in this field means a renewal
  reminder that fires after the approval lapsed, which is worse than no reminder at all.
- **Never invent or complete a protocol number.** If the user gives a partial number, record the
  partial and say it is partial.
- **Never record an amendment by editing a prior record.** Amendments are new `log:` entries; the
  approval history is the point.
- **Never state that an analysis is permitted, covered, or within scope.** Report what the approval
  text says and name who decides — the researcher and their board. An approval's scope is a legal
  judgment, and this skill's output is evidence for it, not a substitute.
- **Never mark an ethics obligation `met` here.** It is discharged by an action elsewhere —
  `curate/deidentify` resolving it with `resolved_by`, or `govern/obligations` waiving it with a
  reason. The schema requires `resolved_by` when status is `met`, so an obligation cannot be closed
  by assertion.
- **Never record consent scope or data-use restrictions as though the ledger models them.** It does
  not. Note them in `log:` prose and say plainly that the schema does not carry them, rather than
  implying a structured guarantee that does not exist.
- Keep `log:` append-only and the ledger schema-valid; delegate the save to the datalad doer.
