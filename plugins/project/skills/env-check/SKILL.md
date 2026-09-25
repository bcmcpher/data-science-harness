---
name: env-check
description: >
  Check that the tools this project's workflow depends on are both declared in a committed manifest
  and actually present, and report the two failures separately. Trigger on "env check", "check my
  environment", "what tools do I need", "is everything installed", "why did that skill say
  unavailable", "check dependencies", "undeclared dependency". Do NOT trigger to build a container
  (the containers doer) or to install anything — this reports, it never installs.
plane: workflow
stamped: [P, E]
---

# Skill: env-check

Report the project's tool dependencies as two separate questions: **is it declared**, and **is it
there**.

**Read this before anything else: those two failures have different fixes and must never be merged.**
An *undeclared* tool that happens to be installed works today and breaks for the next person — it is
a Portability defect (`P.1`: procedures MUST NOT depend on undocumented host state). An *absent*
tool that is properly declared is a setup step. Reporting "missing" for both tells the user to
install something when the actual fix is to commit a manifest line.

> Scope note, and a correction to how this skill was previously described: the README said this
> verifies the dependencies declared in each plugin's `requires:` field. **There is no `requires:`
> field** — `grep -rn '^requires:' plugins/` returns nothing. Introducing one would be a
> `skill-format` spec change plus lint and selftest work, and is not this skill. What this skill
> reads instead is the repository's own committed manifests, which is where
> `openspec/specs/dependency-environment/spec.md` requires every tool to be declared.

## When to use
- Before starting work on a new machine, or after a skill reported a backend `unavailable`.
- When a workflow step failed for a reason that might be environmental.
- Do NOT use to install anything, to build or register a container (the `containers` capability
  builds the image; registering and running it is a direct `datalad containers-add`/`containers-run`
  step), or to edit a manifest — report and let the user decide.

## Steps

1. **Read the manifests.** These own different toolchains and a dependency belongs to exactly one
   (`openspec/specs/dependency-environment/spec.md`):
   ```bash
   sed -n '1,60p' pyproject.toml     # Python checks — dependency-groups dev / e2e
   cat package.json                  # Node CLIs
   sed -n '1,60p' environment.yml    # the end-to-end stack: DataLad, git-annex, container runtime
   ```
   Report which manifests exist. A project that has none is not broken — say that its tool set is
   undeclared, which is the finding.

2. **Run each capability's own gate script rather than re-implementing its check.** Each toolbox
   already owns the authoritative answer for its tools, and duplicating the logic here would drift:
   ```bash
   bash plugins/annotate-cli/scripts/check-backends.sh bagel      # and pynidm, reproschema, snomed
   bash plugins/archive-cli/scripts/check-readiness.sh <backend>
   bash plugins/bids-cli/scripts/check-validator.sh
   bash plugins/compendium-cli/scripts/check-tools.sh myst --project .
   bash plugins/liab-cli/scripts/check-tools.sh pyinfra
   ```
   Each exits `0` available, `1` unavailable, `2` usage error. Report the exit code's meaning, not a
   re-interpretation of the output.

3. **Check the tools no gate script covers** — `datalad`, `git-annex`, the container runtime — with
   presence and runnability, since a present-but-broken entry point is a third state:
   ```bash
   for t in datalad git-annex apptainer singularity docker; do
     command -v "$t" >/dev/null 2>&1 && printf '%s: %s\n' "$t" "$("$t" --version 2>&1 | head -1)" \
       || printf '%s: absent\n' "$t"
   done
   ```

4. **Cross-reference, and this is the actual output.** For every tool found in step 2 or 3, ask
   whether a manifest declares it. Sort the results into four buckets:
   - **declared and present** — fine.
   - **declared and absent** — a setup step. Name the manifest and the install route.
   - **present and undeclared** — a Portability defect. It works here and will not elsewhere. Name
     which manifest should own it.
   - **declared and unusable** — present but does not run. Different from absent, and the hint
     differs too.

5. **Report.**
   ```
   op:          env-check
   manifests:   <which exist; which are absent>
   declared+present:   <tools>
   declared+absent:    <tool -> manifest -> how to install>
   present+undeclared: <tool -> which manifest should declare it>   # P.1 defect
   declared+unusable:  <tool -> what failed to start>
   notes:       <gate scripts whose usage errors indicate a tool with no skill behind it>
   ```

6. **Save only if there is something to save.** This skill never edits a manifest itself, so most
   runs commit nothing. If the user fixes a reported defect by editing a manifest and asks it
   recorded, save that edit:
   ```bash
   datalad save -m "$(printf 'env-check: <manifest> — declare <tool>\n\nDSH-Op: env-check\nDSH-Stage: initialize')" <paths>
   ```

## Constraints

- **Never report an undeclared tool as missing, or a missing tool as undeclared.** They are the two
  findings this skill exists to separate, and they have opposite fixes.
- **Never install anything**, never run a package manager, and never add a line to a manifest. Report
  the route and let the user run it. Installing a tool to make a check pass destroys the finding.
- Do not build or register a container to satisfy a check. That work belongs to the `containers`
  capability and a direct `datalad containers-add`/`containers-run` step, and it is a change to the
  project rather than a report on it.
- **Never claim the environment is correct or complete.** Report what is declared, what is present,
  and what disagrees. Whether that is sufficient depends on what the project is about to do.
- **Never re-implement a toolbox's gate check.** Run the script. A second implementation of
  "is SNOMED configured" will disagree with the first one eventually, and the toolbox's answer is the
  one the doer will act on.
- **Never treat a gate script's exit 2 as `unavailable`.** Exit 2 means a usage error — often that
  the tool asked about has no skill behind it — and reporting it as installable promises a path that
  does not exist.
- **Never print the value of a credential.** Several gates check for API keys; report presence only.
- Do not check tools by importing them into the current Python session, and do not add a harness tool
  to a project manifest — `~/.claude-*-tools` environments are not project dependencies, and putting
  one in `pyproject.toml` makes the lockfile lie.
- Record activity in the commit's `DSH-*` lines, never in `project.yaml` `log`; save with `datalad
  save` yourself, and only when there is a file change to commit.
