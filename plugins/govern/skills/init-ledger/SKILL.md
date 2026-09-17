---
name: init-ledger
description: >
  Create a project.yaml ledger in a dataset that does not have one — the brownfield entry point for
  a study already under way. Trigger on "init ledger", "create project.yaml", "set up the ledger",
  "add a ledger to this dataset", "start tracking obligations", "adopt the harness in an existing
  project". Do NOT trigger for a new study (project/new-project scaffolds the dataset and the ledger
  together) or to edit an existing ledger.
plane: workflow
stamped: [M, T]
delegates_to: [datalad]
---

# Skill: init-ledger

Give an existing dataset an administrative record it does not yet have, so the Manage & Comply lane
has somewhere to write.

**Read this before anything else: if `project.yaml` already exists, stop.** This skill creates a
ledger; it never repairs, migrates or overwrites one. An existing ledger's append-only `log:` is the
project's history, and replacing it destroys exactly what the file is for.

> Scope note: `project/new-project` scaffolds a new study — dataset, container, ledger — in one step.
> This skill is the **brownfield** case: a dataset that already exists, possibly with years of work
> in it, adopting the ledger now. That is the more common way another group starts using this
> harness, and it is why this exists separately rather than being folded into `new-project`.

## When to use
- A dataset exists and has no `project.yaml`, and the user wants to start recording obligations,
  products, contributors or decisions.
- Do NOT use for a new project (`project/new-project`), and do NOT use to add fields to an existing
  ledger — that is the owning skill's job (`govern/obligations`, `project/people`, and so on).

## Steps

1. **Check for an existing ledger first, before anything else.**
   ```bash
   [ -f project.yaml ] && echo "project.yaml already exists — stop"
   ```
   If it exists, report that and stop. Offer `project/status-report` to read it instead.

2. **Confirm this is a dataset root**, not a subdirectory. A `.datalad/` directory or a `.git/` marks
   it. The ledger belongs at the dataset root, sibling to `dataset_description.json`.

3. **Establish the `project:` header from what the user tells you, not from what you can infer.**
   `name` is required; `description`, `created`, `dataset_root` and `stack` are optional. Ask for the
   name and description. Derive `created` from the dataset's first commit only if the user agrees
   that is the right date — a repository's first commit is often not when the study began.

4. **Write the minimum valid ledger.** A `project:` header and an empty append-only `log:` are the
   only required keys. Do **not** invent `products`, `obligations` or `contributors` entries: a
   ledger that claims commitments nobody made is worse than an empty one.

5. **Append the first log entry** — `{ ts, op: init-ledger, stage: initialize, note: "...", branch }`
   recording that the ledger was added to an existing dataset, and from what date the record is
   therefore complete. That last part matters: everything before this entry is unrecorded, and a
   reader needs to know where the record starts.

6. **Validate before saving.**
   ```bash
   python3 schemas/validate-ledger.py project.yaml
   ```

7. **Save** — delegate to the **datalad doer**: "save: `datalad save -m 'init-ledger: add project
   ledger'`."

8. **Report** the path, the header as written, and **what the ledger does not contain** — no
   obligations, no products, no contributors — with the skill that owns each, so the user knows the
   next step is populating it rather than assuming it is complete.

## Constraints

- **Never overwrite, migrate or repair an existing `project.yaml`.** If one exists, stop and report.
  The append-only `log:` is the project's history; recreating the file destroys it, and no `datalad`
  history can recover a record that was never committed.
- **Never backfill the log.** Do not invent entries for work that happened before the ledger existed.
  The first entry says where the record begins; that honest gap is the whole value of an append-only
  log. A reconstructed history is indistinguishable from a real one and cannot be trusted.
- **Never populate `obligations`, `products` or `contributors` at init.** An obligation nobody
  committed to, or an author who has not confirmed their role, is a fabricated administrative claim.
  Create the structure; let the owning skills fill it.
- **Never derive the `created` date without confirming it.** A first commit is not a study start.
- Do not invent a `name`, a `description` or a funding reference. Ask.
- Do not commit. The datalad doer owns `datalad save`.
