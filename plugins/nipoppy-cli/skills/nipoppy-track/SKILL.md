---
name: nipoppy-track
description: >
  Auto-invoke to refresh a nipoppy dataset's derived status files — which participants and sessions
  are curated, and which pipeline outputs exist. Trigger on "update the curation status", "refresh
  processing status", "track-curation", "track-processing", "rebuild the bagel", "which subjects
  finished fmriprep", or /nipoppy-track. Do NOT trigger for reading status that is already current
  (/nipoppy-query) or for producing data (/nipoppy-compute).
argument-hint: '[track-curation|track-processing] [--dataset <path>] [--pipeline <name>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: nipoppy-track

Refresh the derived status files — `tabular/curation_status.tsv` and `tabular/bagel.tsv` — that
every other nipoppy answer is read from.

**These commands read the dataset and write a file.** That is why they are neither a query nor a
computation: they can be run directly, because they derive their output from what is already there
and produce nothing a third party would need to re-execute, but they leave the working tree dirty
and the change has to be saved or it will be swept into an unrelated commit.

## Steps

1. **Confirm the dataset state.** `config.json` and `manifest.tsv` must exist. A tracking run
   against an uninitialized dataset is an error, not an empty result.

2. **Read `${CLAUDE_PLUGIN_ROOT}/../references/curation-commands.md`** for `track-curation` and
   `${CLAUDE_PLUGIN_ROOT}/../references/track-extract-commands.md` for `track-processing`, including
   the schema each writes. Report the columns as the reference defines them rather than as they
   appear to mean.

3. **Note the tree's state before running.** If the tree is already dirty, say so — after the run
   there will be no way to tell which changes came from here.
   ```bash
   git -C <dataset> status --porcelain
   ```

4. **Run the tracking command directly.**
   ```bash
   nipoppy track-curation --dataset <path>
   nipoppy track-processing --dataset <path> --pipeline <name> --pipeline-version <version>
   ```
   `track-processing` without an explicit pipeline and version may fan out across every configured
   pipeline. Name both.

5. **Report the files that changed and hand the save back.** The datalad doer owns `datalad save`.
   This is a checkpoint, not a run record: the status file is derived from data that is already
   tracked, so it does not need `datalad run` — it needs a commit that says what it is.
   ```bash
   git -C <dataset> status --porcelain tabular/
   ```

6. **Report.**
   ```
   op:       nipoppy-<track-curation|track-processing>
   dataset:  <path>
   pipeline: <name/version, for track-processing>
   result:   ok | failed
   changed:  <files written — an empty list is a claim, state it>
   counts:   <as the command reported them>
   next:     save through the datalad doer (checkpoint, not a run)
   ```

## Constraints

- **Never present a tracking run as processing.** `track-processing` records which outputs exist; it
  does not produce any. A user who asked to "run fMRIPrep and track it" has asked for two things,
  and the first is `/nipoppy-compute`.
- **Never let the status file reach a commit unannounced.** Report what changed and hand the save
  back. A derived status file swept into an unrelated commit is how a dataset's history stops
  explaining itself.
- **Never edit `curation_status.tsv` or `bagel.tsv` by hand**, and never correct a row that looks
  wrong. They are derived; if they are wrong, the input or the command is wrong.
- **Never edit `manifest.tsv`** to make a tracking run come out differently. The manifest is the
  registry the dataset is checked against, not a knob.
- **Never run these under `datalad run`.** They derive state from tracked data and would record a
  run whose inputs are the whole dataset, which buries the runs that matter.
- Do not commit. The datalad doer owns `datalad save`.
