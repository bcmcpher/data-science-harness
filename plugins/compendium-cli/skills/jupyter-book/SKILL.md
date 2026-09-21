---
name: jupyter-book
description: >
  Auto-invoke when the user wants to build or preview a Jupyter Book — a book-style collection of
  notebooks and Markdown, executed and rendered as a site. Trigger on "jupyter book",
  "jupyter-book build", "build the book", "_toc.yml", "_config.yml", "turn these notebooks into a
  book", or /jupyter-book. Do NOT trigger for a MyST article (that is /myst), for deciding what the
  book should contain, or for writing its prose.
argument-hint: '[check|build] [--project <dir>] [--all] [--html]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: jupyter-book

Build a Jupyter Book, and report what the build executed as well as what it rendered.

**Read this before anything else: "Jupyter Book" is two different tools.** Version 2 is `mystmd`
under a different entry point and reads `myst.yml`; version 1 is Sphinx-based and reads `_config.yml`
and `_toc.yml`. Their command lines, their configuration and their failure modes differ. A procedure
written for one applied to the other fails in ways that read as a broken project rather than a wrong
tool, so the version is established first, every time, and reported.

The second thing to know: **Jupyter Book executes notebooks.** That is the point of it and it is also
where the reproducibility claim is won or lost — a book built by executing notebooks against whatever
is installed on the host is a book that reproduces on one machine. Whether the execution happened in
the project's pinned environment is the compendium doer's check, not this skill's, but this skill
must report *whether execution happened at all* so that check has something to work with.

## Steps

1. **Check the tool.**
   ```bash
   bash plugins/compendium-cli/scripts/check-tools.sh jupyter-book
   ```
   Exit 1 → report the `enable:` hint and stop. Do not fall back to `myst build` on a version-1
   project, or to `sphinx-build` on a version-2 one.

2. **Establish which major version, from the project rather than from the tool.**
   ```bash
   jupyter-book --version
   ls <project>/myst.yml <project>/_config.yml <project>/_toc.yml 2>/dev/null
   ```
   A `myst.yml` means a v2 project; `_config.yml` plus `_toc.yml` means v1. **If the installed tool's
   major version and the project's configuration disagree, stop and say so** — that mismatch is the
   most common cause of a Jupyter Book build failing with an error about the wrong file.

3. **Report what will be executed before executing it.** List the notebooks in the table of contents
   and say whether the configuration asks for execution, caching, or neither. A book whose
   configuration is `execute: off` renders stored outputs: that is a legitimate choice and a
   different artifact, and the difference must not be silent.

4. **Build.**
   ```bash
   jupyter-book build <project> --all      # v1
   jupyter-book build --html               # v2, from inside the project
   ```
   `--all` forces a rebuild rather than reusing the cache. Say which you used, because a cached build
   can succeed over a notebook that no longer runs.

5. **Read the build log for execution errors, not just the exit code.** Jupyter Book can complete
   with a non-zero number of notebooks that failed to execute, and still exit 0 with the failures
   rendered into the page as tracebacks. Report the count of notebooks executed, cached and failed.

6. **Report.**
   ```
   op:        jupyter-book-<check|build>
   version:   <as reported by the tool, and the major version the project is configured for>
   project:   <path, and which config file marked it>
   execution: executed <n> | cached <n> | off (stored outputs rendered)
   failed:    <notebooks that errored — empty is a claim, state it>
   result:    built | partial | failed | unavailable
   outputs:   <path to the built site>
   notes:     <what was not verified: whether execution used a pinned environment>
   ```

## Constraints

- **Never build a v1 project with a v2 tool or the reverse**, and never migrate a project between
  them to make a build succeed. A migration is a change to the author's project, not a build step.
- **Never report a build as successful when notebooks failed to execute.** Jupyter Book renders the
  traceback into the page and exits 0; a reader sees a finished-looking book with a stack trace in
  it. That is `partial`, with the failing notebooks named.
- **Never turn execution off to make a build pass.** A book of stored outputs is a different artifact
  from a book that ran, and silently swapping one for the other removes the only evidence the
  notebooks still work.
- **Never clear or edit a notebook's outputs**, and never edit a notebook to fix an execution error.
  The error is the finding.
- **Never claim the book is reproducible.** This skill reports what was executed and where. Whether
  the environment was pinned is the compendium doer's check, and whether that adds up to
  reproducible is someone else's claim to make.
- **Never install a missing package to make a notebook run.** A build that needed an undeclared
  dependency has found a real gap in the project's environment declaration; report it.
- Do not commit. The datalad doer owns `datalad save`.
