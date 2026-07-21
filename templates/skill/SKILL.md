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
# delegates_to: [datalad]    # doer subagent(s) this planner invokes
---

# Skill: skill-name

<!--
AUTHORING CONVENTION — planner vs doer
--------------------------------------
- A PLANNER skill (plane: workflow) holds research-process logic. It does NOT call CLIs
  directly. When it needs a tool operation, it DELEGATES to a doer subagent (see step
  pattern below). This keeps the "what/why" separate from the "how".
- A DOER is a subagent (e.g. plugins/datalad/agents/datalad-doer.md) that owns the tool
  mechanics and knows the underlying CLI skills. Doers are the only things that run tools.
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
   organize). Read/append `project.yaml` (the append-only project log) as needed.
3. **Delegate tool work to the doer** — when a tool operation is required, hand off to the
   relevant doer subagent, e.g.:
   > Delegate to the **datalad** doer subagent: "run `<script>` on branch `<branch>` with
   > inputs `<...>` and outputs `<...>`, message `<...>`."
   Wait for the doer's result before continuing.
4. **Record the outcome** — append a log entry to `project.yaml`
   (`{ts, op, stage, note, branch?}`) describing what happened, and report back to the user.

## Constraints
- Planner skills never call a CLI directly — always delegate tool operations to a doer.
- Keep `project.yaml` append-only; do not rewrite or reorder prior entries.
- State assumptions and confirm irreversible actions before delegating them.
