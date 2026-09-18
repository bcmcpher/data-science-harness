---
name: repo2data
description: >
  Auto-invoke when a project declares the data it needs in a data requirement file and that data has
  to be fetched before an article or notebook can build. Trigger on "repo2data",
  "data_requirement.json", "fetch the data for this paper", "download the inputs declaratively",
  "get the data the notebook needs", or /repo2data. Do NOT trigger for retrieving annexed content
  the dataset already tracks (that is a datalad get), or for deciding where data should come from.
argument-hint: '[check|describe|fetch] [--requirement <data_requirement.json>] [--dest <dir>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: repo2data

Fetch the data a project declares it needs, from the declaration rather than from instructions in a
README.

**Read this before anything else: a fetch is not provenance.** repo2data downloads what a
`data_requirement.json` names and puts it where that file says. It records nothing about having done
so — no commit, no input declaration, no checksum in the dataset's history. Data that arrives this
way and is then analysed produces results whose inputs cannot be traced, which is the exact gap this
harness exists to close. So a fetch that matters is run **through the datalad doer** as a recorded
run, and this skill's job is to construct it and say so, not to quietly download.

The second thing: **if the dataset already tracks the data, this is the wrong tool.** Annexed content
that DataLad knows about is retrieved with `datalad get`, which restores it with its provenance
intact. Fetching a second copy from a URL gives you the same bytes with none of the history.

## Steps

1. **Check the tool.**
   ```bash
   bash plugins/compendium-cli/scripts/check-tools.sh repo2data
   ```
   Exit 1 → report the `enable:` hint and stop. Do not substitute `curl` or `wget`: the declaration
   is the artifact, and a hand-written download leaves nothing that describes what was fetched.

2. **Read the declaration and say what it names, before fetching anything.**
   ```bash
   cat <project>/binder/data_requirement.json 2>/dev/null || cat <project>/data_requirement.json
   ```
   Report each source: its URL or identifier, its destination, and its size if declared. **If the
   file does not exist, stop and ask for it** — a data requirement invented here would be a claim
   about where the project's data comes from, and that is the author's to make.

3. **Check whether DataLad already has it.** Ask the datalad doer whether the destination path is
   tracked and whether its content is present. If it is, report that and stop: `datalad get` is the
   right retrieval, and it preserves the link between the data and the runs that used it.

4. **Say where it will land, in absolute terms.** repo2data's destination comes from the declaration
   and can be relative to the working directory. Resolve it and state it. A fetch that lands outside
   the dataset is invisible to every subsequent `datalad run`, and a fetch that lands *inside* it and
   is not committed will surface as a dirty tree at the next save.

5. **Construct the fetch as a recorded run, and hand it back.**
   ```
   repo2data --repo2data-fetch --repo2docker <the declaration>
   ```
   Hand that command to the datalad doer with the declaration as the input and the destination as
   the output:
   > "run: `<command>` with input `<data_requirement.json>` and output `<dest>`, message
   > `fetch declared data for <product>`."
   Do not run it directly. A fetch executed here is bytes on disk with nothing to say where they came
   from.

6. **Report.**
   ```
   op:          repo2data-<check|describe|fetch>
   requirement: <path to the declaration>
   sources:     <each URL/identifier and its declared destination>
   dest:        <absolute resolved destination, and whether it is inside the dataset>
   run_via:     datalad-run
   result:      described | constructed | already-present | failed | unavailable
   notes:       <what was not verified: that the source still serves what the declaration says>
   ```

## Constraints

- **Never fetch directly.** Construct the command and hand it to the datalad doer. `constructed` is
  this skill's successful outcome, in the same way it is for a nipoppy computation.
- **Never invent a URL, DOI or destination**, and never repair one that 404s by finding a similar
  dataset. A declaration that points at something that has moved is a finding about the project, and
  substituting a lookalike source silently changes what was analysed.
- **Never fetch data the dataset already tracks.** Report it and route to `datalad get`, which keeps
  the data's provenance attached.
- **Never write outside the declared destination**, and never reorganise what was fetched to suit a
  later step. The layout is part of what the declaration promises.
- **Never report a fetch as verified.** This skill cannot check that the bytes are what the project
  expects; unless the declaration carries a checksum and it was verified, say that it did not.
- **Never treat a successful download as a licence to use the data.** Whether the terms permit the
  intended use is a governance question and belongs in the ledger's obligations.
- Do not commit. The datalad doer owns `datalad save` and `datalad run`.
