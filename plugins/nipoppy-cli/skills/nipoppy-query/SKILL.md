---
name: nipoppy-query
description: >
  Auto-invoke to read the state of a nipoppy dataset or the pipeline catalog without changing
  anything — what the dataset contains, how far curation and processing have got, which pipelines
  are available or installed. Trigger on "nipoppy status", "how far along is this dataset", "what
  pipelines are available", "is this dataset initialized", "which nipoppy version", or
  /nipoppy-query. Do NOT trigger for commands that write — curation and processing status files are
  /nipoppy-track, and reorg/bidsify/process/extract are /nipoppy-compute.
argument-hint: '[status|pipeline-search|pipeline-list] [--dataset <path>] [query]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: nipoppy-query

Read nipoppy state. Nothing in this skill writes to the dataset.

This is the only nipoppy command class that can be run directly without further thought, and that is
the whole reason it is a separate skill: everything else in this toolbox either writes derived state
that has to be saved, or produces data that has to be produced under `datalad run`. Keeping the
read-only verbs apart means a read never has to be reasoned about as though it might mutate.

## Steps

1. **Confirm the dataset is a nipoppy dataset before reading it.**
   ```bash
   ls <dataset>/config.json <dataset>/manifest.tsv 2>/dev/null
   ```
   A directory without them is not initialized, and `status` against it reports an error rather than
   an empty dataset. Say which of the two is missing — `init` is the answer, and it is
   `/nipoppy-setup`.

2. **Read the reference before quoting an option.**
   `${CLAUDE_PLUGIN_ROOT}/../references/setup-commands.md` for `status`,
   `${CLAUDE_PLUGIN_ROOT}/../references/pipeline-catalog-commands.md` for `pipeline search` and
   `pipeline list`. The CLI's flags have changed across versions; a flag recalled rather than read is
   how a query turns into a usage error the user has to debug.

3. **Run the query.**
   ```bash
   nipoppy status --dataset <path>
   nipoppy pipeline search <term>
   nipoppy pipeline list
   ```

4. **Report what the output actually says, including the parts that are empty.** A dataset with no
   processed participants and a dataset whose status file has not been refreshed look similar in a
   summary and are different situations. The second is answered by `/nipoppy-track`, not by reading
   harder.

5. **Report.**
   ```
   op:       nipoppy-<status|pipeline-search|pipeline-list>
   dataset:  <path, and whether config.json + manifest.tsv are present>
   version:  <nipoppy --version>
   result:   ok | failed | not-initialized
   summary:  <counts as reported, per stage — never inferred from the filesystem>
   notes:    <when the underlying status files were last written, if known>
   ```

## Constraints

- **Never run a command that writes from here.** `track-curation` and `track-processing` write
  derived state even though they read like queries; they are `/nipoppy-track`.
- **Never infer a count from the filesystem.** The number of directories under `bids/` is not the
  number of curated participants, and reporting it as though it were invents a status nipoppy did
  not report.
- **Never report a stale status as current.** These files are written by a previous
  `track-curation` / `track-processing`; if they predate the data, say so rather than presenting
  their numbers as the dataset's present state.
- **Never guess a pipeline name or version** from a partial match in a catalog search. Report what
  the search returned.
- Do not commit. Nothing here changes the dataset, so there is nothing to save.
