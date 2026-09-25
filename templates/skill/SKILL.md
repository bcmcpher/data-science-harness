---
# Universal planner-skill template (harness-generic).
# Keep frontmatter minimal so a skill drops into any harness with little/no change.
# REQUIRED: name, description. Everything else is optional and may be ignored by a harness.
name: skill-name
description: >
  One sentence on what this skill does, followed by the trigger phrases a user would say
  to invoke it (e.g. "start a new project", "propose a comparison"). The description is how
  most harnesses decide when to load the skill, so make the triggers explicit.
# OPTIONAL, advisory only — safe for any harness to ignore:
# plane: workflow            # workflow (planner) | capability (doer/tool)
# stamped: [T, A]            # STAMPED letters this skill advances (see docs/stamped.md)
# delegates_to: [nipoppy]    # doer subagent(s) this planner invokes (never datalad — it is native)
# model: haiku               # AGENTS only: haiku | sonnet | opus | fable; omit = harness default.
#                            # Read-only agents only; the installer translates it per harness.
---

# Skill: skill-name

<!--
AUTHORING CONVENTION — planner vs doer
--------------------------------------
- A PLANNER skill (plane: workflow) holds research-process logic. DataLad, git and git-annex
  are native: the planner runs `datalad save` / `datalad run` itself, the way code runs git.
  For any other tool it DELEGATES to a doer subagent (see step pattern below). This keeps the
  "what/why" separate from the "how".
- A DOER is a subagent (e.g. plugins/nipoppy/agents/nipoppy-doer.md) that owns a peripheral
  tool's mechanics and knows its CLI skills. It returns a command (`run_via: planner`) or the
  files it wrote (`save_via: planner`) plus a `binding`; it never commits.
- Delegation is expressed in plain prose so it ports across harnesses. On harnesses with
  subagents (Claude Code, OpenCode) the model spawns the named doer subagent; on harnesses
  without them, the same prose still guides the model to run the equivalent tool skill.
-->

One-line statement of what invoking this skill accomplishes.

## When to use
- Bullet the situations/trigger phrases that should invoke this skill.
- Note anything that should NOT trigger it.

## Steps
1. **Understand the request** — read arguments / conversation context; ask for anything missing.
2. **Do the planning work** — the research-process judgment this skill owns (choose, record,
   organize). Update `project.yaml` state (products, obligations, contributors) as needed.
3. **Delegate peripheral tool work to a doer** — when a non-DataLad tool is needed, hand off to
   the relevant doer subagent, e.g.:
   > Delegate to the **nipoppy** doer subagent: "construct the `<pipeline>` process command with
   > its inputs and outputs."
   Wait for the doer's result, then run what it returned, e.g. under `datalad run -m "<message>"
   -i <inputs> -o <outputs> "<command>"`.
4. **Save and record in one step** — the commit is the record; nothing is appended to a log:
   ```bash
   datalad save -m "$(printf '<what> — <why>\n\nDSH-Op: skill-name\nDSH-Stage: <stage>')" <paths>
   ```
   Add `DSH-Product: <id>`, `DSH-Obligation: <id> opened|resolved`, or `DSH-Binding:` (copied from
   a doer's `binding`) lines when they apply. Use exactly one `-m`. Report back to the user.

## Constraints
- Run DataLad directly; delegate every other tool to its doer rather than calling its CLI.
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`.
- State assumptions and confirm irreversible actions (push, sibling creation, drop) first.
