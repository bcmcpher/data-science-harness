---
name: nipoppy-setup
description: >
  Auto-invoke to initialize a nipoppy dataset or to manage the pipeline catalog it draws on —
  creating the directory tree and config, installing a pipeline configuration, validating or
  uploading one. Trigger on "set up a nipoppy dataset", "nipoppy init", "install the fmriprep
  pipeline config", "validate this pipeline", "add a pipeline to the catalog", or /nipoppy-setup. Do
  NOT trigger for running a pipeline (/nipoppy-compute) or for reading what is installed
  (/nipoppy-query).
argument-hint: '[init|pipeline-install|pipeline-validate|pipeline-upload] [--dataset <path>] [--pipeline <name>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: nipoppy-setup

Create a nipoppy dataset's scaffolding, and install or author the pipeline configurations it runs.

These commands write, but they write *declarations* rather than data: a directory tree, a config, a
manifest, a pipeline definition. Nothing here is derived from the dataset's contents, so nothing
here needs `datalad run` — but everything here changes what later commands will do, which is why it
is separated from the computations rather than folded in with them.

## Steps

1. **Establish what already exists before creating anything.**
   ```bash
   ls <path>/config.json <path>/manifest.tsv 2>/dev/null
   ```
   `init` against a directory that is already a nipoppy dataset is not a refresh. If the dataset
   exists, report it and stop — the request was probably `/nipoppy-query` or a pipeline install.

2. **Read `${CLAUDE_PLUGIN_ROOT}/../references/setup-commands.md`** for `init`, and
   `${CLAUDE_PLUGIN_ROOT}/../references/pipeline-catalog-commands.md` or
   `${CLAUDE_PLUGIN_ROOT}/../references/pipeline-authoring-commands.md` for the `pipeline` subgroup.
   `${CLAUDE_PLUGIN_ROOT}/../references/workflow-overview.md` holds the layout the tree will have.

3. **Initialize, and say what was created.**
   ```bash
   nipoppy init --dataset <path>
   ```
   Report the tree it produced and which files the user must now fill in themselves — the manifest
   is not populated by `init`, and a dataset with an empty manifest looks initialized and does
   nothing.

4. **Install a pipeline configuration by name and version, both explicit.**
   ```bash
   nipoppy pipeline install <name> --version <version>
   ```
   Report where it landed and what it declares — particularly the container image it expects, which
   is what `/nipoppy-compute` will refuse to proceed without.

5. **Hand the save back.** These files belong in the dataset's history as a checkpoint, with a
   message naming what was set up. The planner owns `datalad save`.

6. **Report.**
   ```
   op:        nipoppy-<init|pipeline-install|pipeline-validate|pipeline-upload>
   dataset:   <path>
   created:   <files and directories written>
   pipeline:  <name/version, where installed, container image it expects>
   result:    ok | exists | failed
   todo:      <what the user must supply — manifest rows, container pull>
   next:      the planner saves with `datalad save`
   ```

## Constraints

- **Never re-initialize an existing dataset.** Report that it exists and stop. `init` over a
  populated tree is not a repair.
- **Never populate `manifest.tsv` yourself.** The manifest is the registry the dataset is checked
  against; filling it from what happens to be on disk makes the check tautological. Say what it
  needs and let the user supply it.
- **Never invent a pipeline version.** Install what was asked for, or report that it is not in the
  catalog.
- **Never upload a pipeline configuration without an explicit instruction to publish.** An upload
  puts a configuration where other people will install it, and that is not a step to take on the way
  to something else.
- **Never edit a pipeline's Boutiques descriptor to make a validation pass.** A descriptor edited to
  satisfy a validator describes a pipeline that was not tested.
- **Never report a dataset as ready to process** after `init`. It has a tree and no participants;
  what is ready is `/nipoppy-query` to confirm the state.
- Do not commit. The planner owns `datalad save`.
