## ADDED Requirements

### Requirement: Hooks are translated for OpenCode at install time

When installing for OpenCode, `bin/install.sh` MUST read each installed plugin's `hooks/hooks.json`.
It MUST generate one OpenCode plugin file per source plugin that invokes the same hook scripts,
passing them a Claude Code-shaped JSON payload on stdin. The mapping is:

- PreToolUse with a `Bash` matcher → `tool.execute.before` on the shell tool, where exit status 2
  blocks the call with the script's stderr;
- SessionStart → `session.created`, where stdout is delivered to the session as context;
- Stop → `session.idle`, where a block decision's reason is delivered to the session as a message.

A hook event with no mapping MUST produce an installer warning naming the plugin and the event.
The generated file MUST NOT be committed to the repository.

#### Scenario: Installing datalad-cli for OpenCode

- **WHEN** `bin/install.sh --harness opencode datalad-cli` runs
- **THEN** the target gains a generated plugin that calls `dsh-status.sh`, `dsh-guard.sh` and the
  checkpoint script, and `--dry-run` lists it without writing

#### Scenario: An unmappable event

- **WHEN** a plugin's `hooks.json` declares an event with no OpenCode equivalent
- **THEN** the installer warns, naming the plugin and the event, and installs everything else

### Requirement: Always-loaded rules are registered for OpenCode

When installing a plugin that has a `rules/` directory for OpenCode, the installer MUST add each
rules file's installed path to the target's `opencode.json` `instructions` array. It MUST create
the file when it is absent, preserve every other key, and not duplicate an existing entry.

#### Scenario: Re-installing

- **WHEN** the installer runs twice against the same target
- **THEN** `instructions` lists the rules file exactly once

#### Scenario: A user's existing config

- **WHEN** `opencode.json` already has a `model` and other `instructions`
- **THEN** those are preserved unchanged
