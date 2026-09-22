## Context

- `plugins/datalad-cli/hooks/hooks.json` registers one Stop hook. That hook,
  `datalad-checkpoint.sh`, runs `datalad save -m "Auto-checkpoint <ts>: <files>"` whenever the
  tree is dirty. It is opted out with `DATALAD_AUTOSAVE=0`.
- `bin/install.sh` copies skills and agents for OpenCode and Claude Code, but ignores `hooks/`.
- `harness-distribution` requires that there be one authored form, and that harness variants are
  produced at install time and never committed.
- OpenCode plugins are JS/TS modules in `.opencode/plugins/` or `~/.config/opencode/plugins/`,
  loaded at startup. The documented hooks include `tool.execute.before` (a throw blocks the
  call), `session.created` and `session.idle`. There is no documented way to inject a system
  prompt. `opencode.json` takes an `instructions` array of files that are always loaded.
- Claude Code's SessionStart hook stdout is added to context. A Stop hook can return
  `{"decision":"block","reason":…}` to make the assistant continue, and carries
  `stop_hook_active` to stop loops. A PreToolUse hook that exits 2 blocks the call and shows
  stderr to the model.

## Goals / Non-Goals

**Goals:**
- Inside a dataset, the assistant starts each session knowing the dataset's state and the rules,
  on both harnesses.
- The common data-losing mistakes (`git commit` or `git push` in an annexed dataset) are stopped,
  with the right command offered in their place.
- Nothing is committed without a human-meaningful message unless the user opted in.
- One set of scripts, and harness-specific glue generated at install time only.

**Non-Goals:**
- Changing planners, doers or the ledger (that is `native-datalad-planners`).
- Detecting "an analysis ran outside `datalad run`". There is no reliable signal for it. It is
  covered by the rules text, not by the guard.
- Per-harness performance tuning.

## Decisions

**D1. Scripts are harness-neutral and speak Claude's hook JSON.** Each script reads the Claude
Code hook payload on stdin and signals through its exit code and stdout. The OpenCode adapter
builds the same payload, for example `{tool_name:"Bash", tool_input:{command}}`. The scripts then
have one contract and one test suite, and Claude Code needs no adapter.

*Alternative: a separate script per harness.* Rejected, because the two copies would drift.

**D2. The OpenCode adapter is generated, not authored.** `install.sh --harness opencode` reads
each installed plugin's `hooks/hooks.json` and writes one plugin file,
`plugins/dsh-<plugin>.js`, into the target. Each entry maps as follows:

| Claude hook | OpenCode hook | What the adapter does |
|---|---|---|
| PreToolUse with a `Bash` matcher | `tool.execute.before` for the `bash` tool | runs the script; exit 2 → `throw new Error(stderr)` |
| SessionStart | `session.created` event + `experimental.chat.system.transform` | runs the script once per session; stdout is pushed onto the system prompt (verified in task 4.1) |
| Stop | `session.idle` event | runs the script; a block decision's `reason` is sent with `client.session.prompt` |

An event with no mapping produces an installer warning naming the event. It is never dropped
silently. This keeps `harness-distribution`'s rule of a single authored form.

**D3. The rules reach context twice on Claude Code, and once from config on OpenCode.** On Claude
Code, `dsh-status.sh` prints the rules file followed by the status block. On OpenCode, the
installer adds the rules file's installed path to `opencode.json` `instructions`. It creates the
file if it is absent, merges into it if present, and is idempotent. The status block reaches
OpenCode through `session.created`. As a fallback, the rules text tells the assistant to run
`dsh-status.sh` if no status block is in context. So even if the injection path fails, the
harness degrades to an assistant that checks the status itself.

**D4. Stop reminds, once per state.** The script hashes `git status --porcelain` output (empty exactly when the tree is clean, unlike `datalad status`).

- If the tree is dirty and that hash differs from the hash stored in
  `.git/dsh-last-reminded` (per dataset and never committed), it records the hash and returns a
  block with a reason: "tree has unsaved changes: <files>; save with a message stating what and
  why, or tell the user why not."
- If `stop_hook_active` is set, or the hash was already reminded, it exits 0.

With `DATALAD_AUTOSAVE=1` it performs the old silent save instead. With `DATALAD_AUTOSAVE=0` it
does nothing.

*Alternative: remind every turn.* Rejected. It nags when a user is deliberately leaving work
unsaved, and costs a turn each time.

**D5. The guard's scope is small and exact.** It only acts inside a dataset (`.datalad/` found
upward from the command's working directory).

| Command | Action |
|---|---|
| `git commit` | block → `datalad save -m` |
| `git push` | block → `datalad push --to <sibling>` |
| `git annex add`, `drop`, `unlock` | warn with the DataLad equivalent |
| `git add` | allow; staging is harmless and `datalad save` supersedes it |

Commands are matched on tokens after splitting on `;`, `&&`, `||` and `|`, so `cd x && git commit`
is caught and `echo "git commit"` is not. `DSH_GUARD=0` turns the guard off for a session.

**D6. Quiet output is a rule, not a wrapper.** The rules tell the assistant to use
`--result-renderer disabled` or `-f json` together with a summary for `get`, `push` and `clone`.
No command wrapper is shipped.

## Risks / Trade-offs

- [The OpenCode SDK call for injecting a message may differ from what is assumed] → Task 4.1
  verifies it against the current docs and a live install before the adapter template is
  finalised. The instructions fallback in D3 keeps the rules loaded regardless.
- [A user in a plain git repo nested inside a dataset is guarded unexpectedly] → The guard
  resolves the *innermost* repo, and only acts when that repo has `.datalad/`.
- [Behaviour change for users relying on auto-save] → The README states the change. The old
  opt-out variable keeps its meaning, and `DATALAD_AUTOSAVE=1` restores the old default.
- [Rules text grows until it is costly to keep always loaded] → The rules file carries a word
  budget (≤ 300 words), and a lint check enforces it.

## Migration Plan

Reinstalling the plugin picks up the new hooks. Existing datasets need nothing. Rollback: set
`DSH_GUARD=0` and `DATALAD_AUTOSAVE=1`, or reinstall the previous version.

## Verified OpenCode behaviour (task 4.1)

Checked on 2026-09-22 against `@opencode-ai/plugin` 1.14.22 type definitions and a live
`opencode run` (1.18.31) in a scratch project with a probe plugin and a local model.

- **Session events arrive through the generic `event` hook**, not as named hooks:
  `event({event})` with `event.type === "session.created"` or `"session.idle"`, and
  `event.properties.sessionID` (for idle) or `event.properties.info.id` (for created). Both fired
  in the live run.
- **Status injection uses `experimental.chat.system.transform`**, not a session message. The hook
  receives `(input: {sessionID, model}, output: {system: string[]})` before every model call, and
  anything pushed onto `output.system` reaches the model. The adapter computes the status once
  per session (on `session.created`, or lazily on the first transform) and pushes the cached
  text on each call. This is invisible in the transcript, as SessionStart output is in Claude
  Code. It is marked experimental; if it disappears, D3's fallback (the rules tell the assistant
  to run `dsh-status.sh`) still holds.
- **Stop maps to `session.idle` plus `client.session.prompt`.** The adapter runs the checkpoint
  script with `{"stop_hook_active": <bool>}` and, on a block decision, calls
  `client.session.prompt({path: {id}, body: {parts: [{type: "text", text: reason}]}})`, which
  starts a new turn as a Claude Code block does. The adapter sets `stop_hook_active` to true for
  the idle that follows its own prompt, so the loop guard carries over.
- **`tool.execute.before`** receives `(input: {tool, sessionID, callID}, output: {args})`; the
  shell tool is `bash` and its command is `output.args.command`. A throw blocks the call and the
  message is shown to the model. Guard *warnings* (exit 0 with `additionalContext`) are stashed by
  `callID` and prepended to the tool's output in `tool.execute.after`.
- **End to end.** A live `opencode run -m opencode/big-pickle` in a dirty scratch dataset with the
  generated plugin installed: the model quoted the status block's `tree:` line from its system
  prompt, `git commit -am wip` was blocked with the guard's message, and on `session.idle` the
  reminder was delivered to the session as a user message. The same run in Claude Code
  (`claude -p --plugin-dir`) showed the same three behaviours, with the Stop block producing
  exactly one follow-up turn. The reminder shows in OpenCode as an ordinary user message, which
  is visible in the transcript, unlike Claude Code's hook feedback.
- **`opencode.json` `instructions` accepts absolute paths.** A rules file listed as
  `/tmp/…/r.md` in a project `.opencode/opencode.json` was in the system prompt of the live run.

## Open Questions

- Should `dsh-status.sh` also surface ledger obligations that are overdue? It will, once
  `native-datalad-planners` defines where due dates live. For now it only counts open items.
