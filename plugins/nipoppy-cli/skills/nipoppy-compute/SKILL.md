---
name: nipoppy-compute
description: >
  Auto-invoke to construct a nipoppy command that produces data — reorganizing DICOMs, converting to
  BIDS, running a processing pipeline, or extracting imaging-derived phenotypes. Trigger on "run
  fmriprep", "run mriqc", "convert these DICOMs to BIDS", "bidsify", "reorg the source data",
  "extract IDPs", or /nipoppy-compute. Do NOT trigger for recording which outputs already exist
  (/nipoppy-track), for reading state (/nipoppy-query), or for setting a dataset up
  (/nipoppy-setup).
argument-hint: '[reorg|bidsify|process|extract] --pipeline <name> --pipeline-version <version> [--participant-id <id>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: nipoppy-compute

Construct the nipoppy command that produces data, declare its inputs and outputs, and hand it back
to be executed under `datalad run`.

**Read this before anything else: this skill does not execute the command it builds.** Every verb
here writes data or derivatives, and nipoppy on its own records nothing about how they came to be.
A `process` run executed bare produces a `derivatives/` tree that nothing can re-derive and no
commit explains — and it will be indistinguishable, six months later, from one that was provenanced.
The command is constructed, simulated, and returned; the datalad doer runs it.

## Steps

1. **Establish the full invocation before touching anything.** Operation, dataset path, and — for
   `process` and `extract` — `--pipeline`, `--pipeline-version` and `--pipeline-step`, explicitly.
   Omitting them can fan the command out across every configured pipeline. If any is missing, ask;
   do not choose a pipeline or a version.

2. **Read the matching reference.** `${CLAUDE_PLUGIN_ROOT}/../references/curation-commands.md` for
   `reorg`, `${CLAUDE_PLUGIN_ROOT}/../references/bids-commands.md` for `bidsify`,
   `${CLAUDE_PLUGIN_ROOT}/../references/process-command.md` for `process`, and
   `${CLAUDE_PLUGIN_ROOT}/../references/track-extract-commands.md` for `extract`.

3. **Check the platform and the state, and stop rather than work around either.**
   ```bash
   apptainer --version && nipoppy --version
   ```
   `bidsify`, `process` and `extract` need Linux and Apptainer, and the pipeline version in
   `config.json` must match a pulled container image. A missing image is a clean stop with
   the pull command named — never a fallback to a host installation of the tool, which would produce
   derivatives from a different version of the software than the config claims.

4. **Simulate first, and report what the simulation shows.**
   ```bash
   nipoppy process --dataset <path> --pipeline <name> --pipeline-version <v> --simulate
   ```
   This surfaces the Boutiques/Apptainer invocation that would run. `--simulate` and `--dry-run`
   availability varies by command; the reference says which applies.

5. **Declare the inputs and outputs the run needs.** This is the part that cannot be recovered
   afterwards: the datalad doer needs `-i` and `-o` paths to record, and a run whose outputs are
   under-declared saves an incomplete result.
   ```
   inputs:  bids/, config.json, the container image
   outputs: derivatives/<pipeline>/<version>/, logs/
   ```

6. **Hand it back. Do not run it.**
   > "container-run: `<the exact nipoppy command>` with inputs `<...>` and outputs `<...>`,
   > message `<what this produces>`."

7. **Report.**
   ```
   op:       nipoppy-<reorg|bidsify|process|extract>
   dataset:  <path>
   command:  <the exact command constructed>
   run_via:  datalad-run
   inputs:   <-i paths>
   outputs:  <-o paths>
   result:   constructed | failed
   platform: <linux + apptainer confirmed, or the gap that stopped this>
   notes:    <what the simulation showed; what was not verified>
   ```

## Constraints

- **Never execute one of these commands.** Not with `--simulate` removed "just to check", not on a
  single participant "as a test". `result: constructed` is the successful outcome of this skill.
- **Never guess a pipeline name, version or step.** A pipeline version is the difference between two
  sets of derivatives that look identical and are not comparable.
- **Never fall back to a host installation** when the container image is missing. The recorded
  environment is the claim; a run outside it produces derivatives the config misdescribes.
- **Never under-declare outputs to make a run tidier.** An output produced but not declared is
  untracked, and the next `datalad run` will report a dirty tree that nobody can attribute.
- **Never edit `manifest.tsv` or `config.json`** to make a command succeed. Both are the
  dataset's declarations, and changing them to fit a command inverts which one is authoritative.
- **Never report a completed pipeline as good results.** Exit 0 means the container ran. Whether the
  outputs are usable is `govern/qc-review`'s question.
- Do not commit, and do not run `datalad run` yourself. The datalad doer owns both.
