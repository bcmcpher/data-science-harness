---
name: myst
description: >
  Auto-invoke when the user wants to scaffold, build or preview a MyST project — a reproducible
  preprint, an executable article, a NeuroLibre-style paper, or this repository's own paper/.
  Trigger on "myst", "mystmd", "myst build", "build the paper", "executable article", "reproducible
  preprint", "NeuroLibre", "preview the article", or /myst. Do NOT trigger for deciding what the
  article should argue, for writing its prose, or for Jupyter Book (a different tool, not yet
  wrapped here).
argument-hint: '[check|init|build|start] [--project <dir>] [--html|--pdf] [--strict]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: myst

Scaffold, build and preview a MyST project, and report what the build actually produced.

**Read this before anything else: `myst` builds a document; it does not make that document
reproducible.** A MyST project whose figures are committed images builds perfectly and reproduces
nothing. What makes an article re-executable is that each figure comes from a provenanced output and
the build runs in the project's pinned environment — and neither of those is something this command
checks. The compendium doer owns those checks; this skill owns the invocation.

## Steps

1. **Check the tool before anything else.**
   ```bash
   bash plugins/compendium-cli/scripts/check-tools.sh myst --project <the project dir>
   ```
   Exit 0 means MyST is usable and the `found:` line says how to invoke it — `myst` on PATH, or
   `<project>/node_modules/.bin/myst` when `mystmd` is a declared project dependency. **Use the form
   and the path the check reported.** A global install and a project-local one are both normal, the
   invocation differs, and a project-local one must be called by absolute path because the build runs
   from the article's own directory. `--project` defaults to the working directory, so pass it
   explicitly whenever you are not already sitting in the project that declares the dependency.

2. **Confirm the surface.** MyST's CLI moves between minor versions.
   ```bash
   myst --version && myst --help
   ```
   Report a divergence from what this skill describes rather than working around it.

3. **Identify the project root** — the directory holding `myst.yml`. That file is the project: its
   `project.id`, `toc`, `bibliography` and `exports` decide what a build does.
   ```bash
   [ -f myst.yml ] && sed -n '1,40p' myst.yml
   ```

4. **Initialize only when there is no `myst.yml`.**
   ```bash
   myst init            # writes myst.yml; prompts unless given flags
   ```
   Never run `myst init` in a directory that already has one — it is how a configured project loses
   its `toc` and `exports`.

5. **Build.** Name the format explicitly; the default changes with configuration.
   ```bash
   myst build --html            # site
   myst build --pdf             # needs a LaTeX toolchain; report its absence rather than retrying
   ```
   Build output and warnings both matter: MyST reports unresolved references and missing figures as
   warnings and still exits 0.

6. **Read the warnings, not just the exit code.** An unresolved citation key, a missing figure file
   or a broken cross-reference is a warning. A build that "succeeded" with unresolved references
   produced a document with holes in it, and reporting that as a clean build is the failure mode
   this step exists to prevent. Where the caller wants a hard gate, `--strict` turns warnings into a
   non-zero exit — prefer it, and say whether it was used.

7. **Preview only when asked.** `myst start` runs a long-lived server and will not return.
   ```bash
   myst start        # blocks; hand this to the user rather than running it yourself
   ```
   Do not launch it from a non-interactive session.

8. **Report.**
   ```
   op:       myst-<init|build|start>
   invoked:  <myst on PATH | node_modules/.bin/myst> <version>
   project:  <path to myst.yml>
   format:   html | pdf | none
   strict:   yes | no
   result:   built | failed | not-run
   warnings: <count, with unresolved references and missing figures named>
   outputs:  <paths produced>
   notes:    <what was not checked here — figure provenance and environment pinning belong to the doer>
   ```

## Constraints

- **Never report a build as clean without reporting its warnings.** MyST exits 0 with unresolved
  references and missing figures. A caller told "built successfully" will not go looking.
- **Never claim an article is reproducible.** This skill can say a document built. Whether its
  figures trace to provenanced runs, and whether the build was pinned, are the compendium doer's
  questions and must not be answered here by implication.
- **Never invent a citation key, a cross-reference target, or a figure path** to make a warning go
  away. An unresolved reference is a finding to report, not an error to silence — and a fabricated
  key resolves cleanly while pointing at the wrong source.
- **Never run `myst init` over an existing `myst.yml`**, and never rewrite a project's `toc` or
  `exports` to make a build succeed. Report what the configuration does not support.
- **Never run `myst start` from a non-interactive session.** It blocks, and a killed preview server
  leaves no artifact while looking like a completed step. Hand the command to the user.
- Do not install `mystmd` globally to work around an absent project dependency without saying so;
  the gate script's `enable:` hint names both routes and the project's own manifest is the one that
  travels with the project.
- Do not commit. The planner owns `datalad save`.
- Do not edit the article's prose. Building the document and writing it are different jobs.
