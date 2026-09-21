---
name: merge-data
description: >
  Combine tabular phenotypic or clinical sources into one table as a provenanced run, reporting the
  row and column arithmetic so a silent join failure cannot pass as success. Trigger on "merge the
  data", "combine these tables", "join the clinical data", "merge participants", "combine
  phenotypic files", "add these columns to participants.tsv". Do NOT trigger to describe the merged
  columns (curate/gen-data-dict) or to remove identifiers (curate/deidentify).
plane: workflow
stamped: [S, T]
delegates_to: [datalad]
---

# Skill: merge-data

Combine tabular sources through the provenance chain, and report the arithmetic that shows whether
the join did what was intended.

**Read this before anything else: a wrong join does not fail. It produces a table.** Joining on a
mistyped id column silently drops every row. Joining on a non-unique key silently multiplies them.
Both return a plausible file, and neither raises an error. That is why every step below reports
counts, and why the join key is supplied rather than inferred.

## When to use
- Two or more tabular sources describing the same participants need to become one table.
- A clinical or phenotypic export needs to be brought alongside `participants.tsv`.
- Do NOT use to write the data dictionary for the result (`curate/gen-data-dict`), to strip
  identifiers (`curate/deidentify`), or to convert imaging data (`curate/raw-to-bids`).

## Steps

1. **Inspect every source before merging anything.** For each: the column names, the row count, and
   the candidate key's uniqueness.
   ```bash
   for f in <sources>; do
     printf '%s: %s rows\n' "$f" "$(( $(wc -l < "$f") - 1 ))"
     head -1 "$f"
   done
   ```
   Report this table to the user. It is the baseline every later count is checked against.

2. **Get the join key from the user, and verify it is unique in each source.** Do not infer it from
   a column name that looks like an id.
   ```bash
   cut -f<n> <source> | tail -n +2 | sort | uniq -d | head    # duplicates in the key
   ```
   A non-unique key is not a blocker — a long-format table legitimately repeats it — but it changes
   what the merge means, and the user must say which it is.

3. **Establish the join type explicitly, with the user.** Inner, left, outer. This decides which
   participants survive, and the default in whatever tool is used is not a decision the skill gets to
   make silently.

4. **Check key overlap before merging.** How many keys are in both sources, how many only in the
   left, how many only in the right. If the overlap is zero or surprisingly small, stop and report —
   that is a mismatched-identifier problem (a prefix, a zero-pad, a case difference), not a merge to
   perform.

5. **Check for colliding column names.** Two sources with the same non-key column will either
   overwrite or produce suffixed duplicates. Name the collisions and ask how to resolve them.

6. **Run the merge through the datalad doer**, so it is a recorded transformation:
   > "run `<the merge command>` on `<sources>` producing `<output>`, and record it with
   > `datalad run`."

   Never edit a table in place to add columns. The merge is a derivation and its inputs must stay
   readable.

7. **Report the arithmetic, and check it.** Rows in, rows out, keys matched, keys dropped from each
   side, columns in, columns out. A row count that changed in a way the join type does not explain is
   a failure even if the file looks right.

8. **Log and save** — `{ ts, op: merge-data, stage: curate, note: "...", branch }` with the
   arithmetic in the note, then delegate the save.

9. **Report**, and point at `curate/gen-data-dict` for the new columns: a merged table whose
   provenance is clean and whose columns are undescribed is only half-curated.

## Constraints

- **Never infer the join key.** It is supplied by the user. A column called `id`, `subject` or
  `participant_id` in two files is not evidence that they mean the same thing — one may be a scanner
  id and the other a study id.
- **Never report a merge without its row and column arithmetic.** Rows in, rows out, keys matched,
  keys dropped per side. This is the only way a silent drop or a silent multiplication is visible,
  and both produce a file that looks correct.
- **Never proceed past a zero or near-zero key overlap.** Report it as an identifier-format mismatch
  and stop. Merging anyway produces an empty or tiny table that will be mistaken for a real one.
- **Never resolve a column-name collision by picking a side.** Name the collision and ask.
- **Never reconcile conflicting values silently.** If two sources disagree on a participant's age,
  that is a data-quality finding for the user, not a precedence rule for you to apply.
- **Never fabricate, impute or forward-fill a missing value**, and never convert a unit you were not
  told the source uses. An imputed cell is indistinguishable from a measured one once written.
- **Never edit a source table in place.** The merge produces a new file through `datalad run`; the
  inputs stay as they are so the derivation is checkable.
- Do not commit. The datalad doer owns `datalad save` and `datalad run`.
