---
name: claude-config
description: >
  Generate or update a project's assistant configuration — CLAUDE.md, settings, MCP server stubs —
  from what the project actually contains, so a fresh session starts oriented instead of
  reconstructing state. Trigger on "generate CLAUDE.md", "claude config", "set up the assistant
  config", "MCP stubs", "project instructions for the agent", "update CLAUDE.md". Do NOT trigger to
  install harness plugins (bin/install.sh) or to write research documentation.
plane: workflow
stamped: [M, P]
---

# Skill: claude-config

Write the project-level assistant configuration from evidence in the project, and keep it small
enough to stay true.

**Read this before anything else: a CLAUDE.md that describes the project inaccurately is worse than
none at all.** It is loaded into every session and treated as authoritative, so a stale instruction
is followed rather than questioned. Every line must come from something in the project, and anything
you cannot source is a question for the user rather than a plausible default.

> The harness's own plugins are installed by `bin/install.sh`, not by this skill. This writes the
> *project's* configuration — the instructions specific to this study — and the two must not be
> conflated: harness content is authored once and installed, project configuration is per-project and
> lives in the dataset.

## When to use
- A project has no assistant configuration and should have one.
- The project changed in a way the configuration now misstates — a new stack, a new pipeline, a
  moved directory.
- Do NOT use to install plugins, to write a README for humans (that is documentation), or to record
  decisions (`project/log-decision`).

## Steps

1. **Read what already exists.** `CLAUDE.md`, `.claude/settings.json`, any `.mcp.json`. Show the user
   the current content before proposing changes; this file may carry instructions someone relied on.
2. **Derive the facts from the project**, not from convention:
   - the stack and how it is pinned — `pyproject.toml`, `environment.yml`, `containers/`;
   - the dataset layout — is it YODA, is it BIDS, where do derivatives go;
   - the pipelines actually configured, from the nipoppy config rather than from what a project like
     this usually runs;
   - the ledger's `project:` header for the study's name and description;
   - the test or validation commands that exist and pass.
3. **Write only what you verified.** A command goes in the configuration if you ran it or read it in
   a manifest. Do not include a lint command, a test invocation or a directory convention because
   projects like this one usually have it.
4. **Keep it short.** Every line is loaded into every session and competes for attention with the
   user's actual request. Prefer the facts an assistant cannot derive — local conventions, gotchas,
   which of two directories is authoritative — over restating what is visible in the tree.
5. **MCP stubs, only for servers the project actually uses**, and with no secrets in them. A stub
   with a placeholder token is fine; a stub with a real one is a credential committed to a dataset
   that may be published.
6. **Save and record in one step**:
   ```bash
   datalad save -m "$(printf 'claude-config: <action> — <why>\n\nDSH-Op: claude-config\nDSH-Stage: initialize')" <paths>
   ```
7. **Report** what was written, and separately **what you left out because you could not verify it**,
   with the question the user would need to answer for each.

## Constraints

- **Never write an instruction you could not source from the project.** A plausible convention in a
  CLAUDE.md is followed as though it were true, and the cost is paid in every later session.
- **Never overwrite an existing `CLAUDE.md` without showing the user the current content first.**
  It may hold instructions that exist for a reason not visible in the tree — which is exactly what
  the file is for.
- **Never put a credential, token, key or password in a configuration or an MCP stub.** These files
  are committed to the dataset and may be published. Use a placeholder and name the environment
  variable.
- **Never add a harness tool to the project's manifests** while configuring, and never instruct the
  assistant to install one into a project environment. Harness CLIs belong in their own environments;
  a project manifest that declares one makes the lockfile lie.
- **Never claim the configuration is complete.** Report what you left out and why.
- Do not invent a test or lint command. If none exists, say so — that is a finding, not a gap to fill
  with a guess.
- Record activity in the commit's `DSH-*` lines, never in `project.yaml` `log`; save with `datalad
  save` yourself.
