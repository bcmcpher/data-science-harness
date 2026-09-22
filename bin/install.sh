#!/usr/bin/env bash
# Install data-science-harness skills and agents into supported AI assistant configs.
#
# This is intentionally a small file-copy installer. The source plugin layout remains
# Claude Code-compatible; installed copies are adapted only in the target directory.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bin/install.sh [options] [plugin ...]

Options:
  --harness NAME     Target harness: opencode or claude-code (default: opencode)
  --scope SCOPE      Install scope: project or global (default: project)
  --target DIR       Override target config directory
  --dry-run          Show what would be installed without copying files
  -h, --help         Show this help

Examples:
  bin/install.sh --harness opencode --scope project
  bin/install.sh --harness opencode --scope global project analyze datalad
  bin/install.sh --harness claude-code --scope project

With no plugin names, all plugins under plugins/*/.claude-plugin/plugin.json are installed.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

say() {
  printf '%s\n' "$*"
}

repo_root() {
  local script_dir
  script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  CDPATH= cd -- "$script_dir/.." && pwd
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\''/g")"
}

copy_dir() {
  local src="$1" dest="$2"
  if [ "$DRY_RUN" = 1 ]; then
    say "copy $(shell_quote "$src") -> $(shell_quote "$dest")"
    return
  fi
  rm -rf -- "$dest"
  mkdir -p -- "$(dirname -- "$dest")"
  cp -R -- "$src" "$dest"
}

copy_file() {
  local src="$1" dest="$2"
  if [ "$DRY_RUN" = 1 ]; then
    say "copy $(shell_quote "$src") -> $(shell_quote "$dest")"
    return
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  cp -- "$src" "$dest"
}

install_agent_for_opencode() {
  local src="$1" dest="$2"
  if [ "$DRY_RUN" = 1 ]; then
    say "copy agent $(shell_quote "$src") -> $(shell_quote "$dest")"
    return
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  awk '
    BEGIN {
      fm = 0; inserted = 0
      # Authored alias -> OpenCode provider/model-id. Keys match MODELS in tests/lint-plugins.py;
      # a value with no entry is stripped, so the agent falls back to the OpenCode default.
      model["haiku"] = "anthropic/claude-haiku-4-5"
      model["sonnet"] = "anthropic/claude-sonnet-5"
      model["opus"] = "anthropic/claude-opus-5"
      model["fable"] = "anthropic/claude-fable-5-1"
    }
    $0 == "---" {
      fm++
      if (fm == 2 && inserted == 0) {
        print "mode: subagent"
        inserted = 1
      }
      print
      next
    }
    fm == 1 && $0 ~ /^name:[[:space:]]*/ { next }
    fm == 1 && $0 ~ /^tools:[[:space:]]*/ { next }
    fm == 1 && $0 ~ /^model:[[:space:]]*/ {
      v = $0
      sub(/^model:[[:space:]]*/, "", v)
      sub(/[[:space:]]*#.*$/, "", v)
      sub(/[[:space:]]+$/, "", v)
      gsub(/["\047]/, "", v)
      if (v in model) print "model: " model[v]
      next
    }
    fm == 1 && $0 ~ /^mode:[[:space:]]*/ { inserted = 1; print; next }
    { print }
  ' "$src" > "$dest"
}

rewrite_installed_markdown() {
  local file="$1" root_for_claude_var="$2" bundle_plugins="$3"
  [ "$DRY_RUN" = 1 ] && return
  [ -f "$file" ] || return

  # These are prompt-visible paths, not executable code. Rewrite only installed copies.
  # Relative plugins/ paths first: the substituted plugin root itself contains "plugins/".
  sed -i \
    -e "s|plugins/|$bundle_plugins/|g" \
    -e "s|\${CLAUDE_PLUGIN_ROOT}|$root_for_claude_var|g" \
    -- "$file"
}

all_plugins() {
  local dir manifest
  for manifest in "$ROOT"/plugins/*/.claude-plugin/plugin.json; do
    [ -f "$manifest" ] || continue
    dir="$(basename -- "$(dirname -- "$(dirname -- "$manifest")")")"
    printf '%s\n' "$dir"
  done | sort
}

resolve_target() {
  if [ -n "$TARGET" ]; then
    printf '%s\n' "$TARGET"
    return
  fi

  case "$HARNESS:$SCOPE" in
    opencode:project) printf '%s\n' "$PWD/.opencode" ;;
    opencode:global) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" ;;
    claude-code:project) printf '%s\n' "$PWD/.claude" ;;
    claude-code:global) printf '%s\n' "$HOME/.claude" ;;
    *) die "unsupported --harness/--scope combination: $HARNESS/$SCOPE" ;;
  esac
}

# Claude Code hook events the OpenCode adapter translates. PreToolUse is translated for the Bash
# matcher only; anything else in a hooks.json is reported, never dropped silently.
OPENCODE_MAPPED_EVENTS="SessionStart PreToolUse Stop"

js_string() {
  printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

warn_unmapped_hooks() {
  local plugin="$1" hooks_json="$2" event matcher
  for event in $(grep -oE '"[A-Z][A-Za-z]+"[[:space:]]*:[[:space:]]*\[' "$hooks_json" | grep -oE '[A-Z][A-Za-z]+'); do
    case " $OPENCODE_MAPPED_EVENTS " in
      *" $event "*) ;;
      *) say "WARNING: $plugin: hook event $event has no OpenCode mapping; not installed" >&2 ;;
    esac
  done
  for matcher in $(grep -oE '"matcher"[[:space:]]*:[[:space:]]*"[^"]*"' "$hooks_json" | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'); do
    [ "$matcher" = "Bash" ] || say "WARNING: $plugin: PreToolUse matcher '$matcher' has no OpenCode mapping; only Bash is translated" >&2
  done
}

# Generate an OpenCode plugin that runs a plugin's Claude Code hook scripts. The generated file
# reads the installed hooks.json at load time, so the source layout stays the only authored form.
install_hooks_for_opencode() {
  local plugin="$1" src_plugin="$2" dest_plugin="$3"
  local dest="$TARGET_DIR/plugins/dsh-$plugin.js"
  local rules_flag=false
  [ -d "$src_plugin/rules" ] && rules_flag=true

  warn_unmapped_hooks "$plugin" "$src_plugin/hooks/hooks.json"
  if [ "$DRY_RUN" = 1 ]; then
    say "generate OpenCode hook plugin $(shell_quote "$dest") from $(shell_quote "$src_plugin/hooks/hooks.json")"
    return
  fi
  mkdir -p -- "$(dirname -- "$dest")"
  {
    printf '// Generated by bin/install.sh from %s/hooks/hooks.json. Do not edit: reinstall instead.\n' "$plugin"
    printf 'const PLUGIN_ROOT = %s;\n' "$(js_string "$dest_plugin")"
    printf 'const RULES_IN_CONFIG = %s;\n' "$rules_flag"
    cat <<'JS'
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

const cfg = JSON.parse(readFileSync(`${PLUGIN_ROOT}/hooks/hooks.json`, "utf8"));
const table = cfg.hooks ?? cfg;
const commands = (event, keep = () => true) =>
  (table[event] ?? []).filter(keep).flatMap((e) => e.hooks ?? [])
    .filter((h) => h.type === "command")
    .map((h) => h.command.replaceAll("${CLAUDE_PLUGIN_ROOT}", PLUGIN_ROOT));

function run(cmd, payload, cwd) {
  const r = spawnSync("bash", ["-c", cmd], {
    input: JSON.stringify(payload), cwd, encoding: "utf8", timeout: 60000,
    env: { ...process.env, CLAUDE_PLUGIN_ROOT: PLUGIN_ROOT,
           ...(RULES_IN_CONFIG ? { DSH_RULES_IN_CONFIG: "1" } : {}) },
  });
  return { code: r.status ?? 1, out: r.stdout ?? "", err: r.stderr ?? "" };
}

export const DshHooks = async ({ client, directory }) => {
  const sessionStart = commands("SessionStart");
  const preBash = commands("PreToolUse", (e) => e.matcher === "Bash");
  const stop = commands("Stop");
  const status = new Map();    // sessionID -> SessionStart output, pushed onto the system prompt
  const children = new Set();  // subagent sessions: no Stop reminder, as Claude Code's Stop
  const prompted = new Set();  // sessions whose current turn this adapter started
  const warnings = new Map();  // callID -> guard warning, prepended to the tool output

  const startText = (sid) => {
    if (!status.has(sid)) {
      status.set(sid, sessionStart
        .map((c) => run(c, { hook_event_name: "SessionStart", session_id: sid, cwd: directory }, directory).out.trim())
        .filter(Boolean).join("\n\n"));
    }
    return status.get(sid);
  };

  return {
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const info = event.properties.info;
        if (info.parentID) children.add(info.id);
        else if (sessionStart.length) startText(info.id);
      }
      if (event.type === "session.idle" && stop.length) {
        const sid = event.properties.sessionID;
        if (children.has(sid)) return;
        const active = prompted.delete(sid);
        for (const c of stop) {
          const r = run(c, { hook_event_name: "Stop", session_id: sid, cwd: directory, stop_hook_active: active }, directory);
          let decision;
          try { decision = JSON.parse(r.out); } catch { continue; }
          if (decision?.decision === "block" && decision.reason) {
            prompted.add(sid);
            await client.session.prompt({ path: { id: sid }, body: { parts: [{ type: "text", text: decision.reason }] } });
            return;
          }
        }
      }
    },
    "experimental.chat.system.transform": async (input, output) => {
      if (!sessionStart.length || !input.sessionID || children.has(input.sessionID)) return;
      const text = startText(input.sessionID);
      if (text) output.system.push(text);
    },
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash" || !preBash.length) return;
      const cwd = output.args?.workdir ?? directory;
      const payload = { hook_event_name: "PreToolUse", session_id: input.sessionID, cwd,
                        tool_name: "Bash", tool_input: { command: output.args?.command ?? "" } };
      for (const c of preBash) {
        const r = run(c, payload, cwd);
        if (r.code === 2) throw new Error(r.err.trim() || "Blocked by a hook");
        try {
          const ctx = JSON.parse(r.out)?.hookSpecificOutput?.additionalContext;
          if (ctx) warnings.set(input.callID, ctx);
        } catch {}
      }
    },
    "tool.execute.after": async (input, output) => {
      const w = warnings.get(input.callID);
      if (w === undefined) return;
      warnings.delete(input.callID);
      output.output = `${w}\n\n${output.output ?? ""}`;
    },
  };
};
JS
  } > "$dest"
  say "generated OpenCode hook plugin $dest"
}

# Add a rules file's installed path to the target opencode.json "instructions", creating the file
# when absent, keeping every other key, and never duplicating an entry. Needs python3 or node.
register_opencode_instructions() {
  local rules_path="$1"
  local config="$TARGET_DIR/opencode.json"
  if [ "$DRY_RUN" = 1 ]; then
    say "register instructions $(shell_quote "$rules_path") in $(shell_quote "$config")"
    return
  fi
  if [ -f "$TARGET_DIR/opencode.jsonc" ] && [ ! -f "$config" ]; then
    say "WARNING: $TARGET_DIR/opencode.jsonc exists; add \"$rules_path\" to its \"instructions\" by hand" >&2
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$config" "$rules_path" <<'PY' || say "WARNING: could not update $config; add \"$rules_path\" to \"instructions\" by hand" >&2
import json, os, sys
config, rules = sys.argv[1], sys.argv[2]
data = {"$schema": "https://opencode.ai/config.json"}
if os.path.exists(config):
    with open(config) as f:
        data = json.load(f)
instructions = data.setdefault("instructions", [])
if rules not in instructions:
    instructions.append(rules)
    with open(config, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
PY
  elif command -v node >/dev/null 2>&1; then
    node - "$config" "$rules_path" <<'NODE' || say "WARNING: could not update $config; add \"$rules_path\" to \"instructions\" by hand" >&2
const fs = require("fs");
const [config, rules] = process.argv.slice(2);
const data = fs.existsSync(config) ? JSON.parse(fs.readFileSync(config, "utf8")) : { $schema: "https://opencode.ai/config.json" };
data.instructions ??= [];
if (!data.instructions.includes(rules)) {
  data.instructions.push(rules);
  fs.writeFileSync(config, JSON.stringify(data, null, 2) + "\n");
}
NODE
  else
    say "WARNING: neither python3 nor node found; add \"$rules_path\" to \"instructions\" in $config by hand" >&2
  fi
}

install_plugin() {
  local plugin="$1"
  local src_plugin="$ROOT/plugins/$plugin"
  local dest_plugin="$BUNDLE_PLUGINS/$plugin"
  local skill_dir skill_name dest_skill agent_file agent_name dest_agent rules_file

  [ -d "$src_plugin" ] || die "unknown plugin: $plugin"
  [ -f "$src_plugin/.claude-plugin/plugin.json" ] || die "plugin lacks .claude-plugin/plugin.json: $plugin"

  copy_dir "$src_plugin" "$dest_plugin"

  if [ -d "$src_plugin/skills" ]; then
    for skill_dir in "$src_plugin"/skills/*; do
      [ -f "$skill_dir/SKILL.md" ] || continue
      skill_name="$(basename -- "$skill_dir")"
      dest_skill="$TARGET_DIR/skills/$skill_name"
      copy_dir "$skill_dir" "$dest_skill"
      rewrite_installed_markdown "$dest_skill/SKILL.md" "$dest_skill" "$BUNDLE_PLUGINS"
    done
  fi

  if [ -d "$src_plugin/agents" ]; then
    for agent_file in "$src_plugin"/agents/*.md; do
      [ -f "$agent_file" ] || continue
      agent_name="$(basename -- "$agent_file")"
      dest_agent="$TARGET_DIR/agents/$agent_name"
      if [ "$HARNESS" = "opencode" ]; then
        install_agent_for_opencode "$agent_file" "$dest_agent"
      else
        copy_file "$agent_file" "$dest_agent"
      fi
      rewrite_installed_markdown "$dest_agent" "$dest_plugin" "$BUNDLE_PLUGINS"
    done
  fi

  if [ -d "$src_plugin/rules" ]; then
    for rules_file in "$src_plugin"/rules/*.md; do
      [ -f "$rules_file" ] || continue
      rewrite_installed_markdown "$dest_plugin/rules/$(basename -- "$rules_file")" "$dest_plugin" "$BUNDLE_PLUGINS"
      if [ "$HARNESS" = "opencode" ]; then
        register_opencode_instructions "$dest_plugin/rules/$(basename -- "$rules_file")"
      fi
    done
  fi

  if [ -f "$src_plugin/hooks/hooks.json" ]; then
    if [ "$HARNESS" = "opencode" ]; then
      install_hooks_for_opencode "$plugin" "$src_plugin" "$dest_plugin"
    else
      say "NOTE: $plugin ships hooks; a copy install does not register them. Use: claude plugin install ./plugins/$plugin"
    fi
  fi

  say "installed $plugin -> $TARGET_DIR"
}

HARNESS="opencode"
SCOPE="project"
TARGET=""
DRY_RUN=0
PLUGINS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --harness)
      [ "$#" -ge 2 ] || die "--harness requires a value"
      HARNESS="$2"
      shift 2
      ;;
    --harness=*)
      HARNESS="${1#*=}"
      shift
      ;;
    --scope)
      [ "$#" -ge 2 ] || die "--scope requires a value"
      SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      SCOPE="${1#*=}"
      shift
      ;;
    --target)
      [ "$#" -ge 2 ] || die "--target requires a value"
      TARGET="$2"
      shift 2
      ;;
    --target=*)
      TARGET="${1#*=}"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        PLUGINS+=("$1")
        shift
      done
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      PLUGINS+=("$1")
      shift
      ;;
  esac
done

case "$HARNESS" in
  opencode|claude-code) ;;
  *) die "unsupported harness: $HARNESS" ;;
esac

case "$SCOPE" in
  project|global) ;;
  *) die "unsupported scope: $SCOPE" ;;
esac

ROOT="$(repo_root)"
TARGET_DIR="$(resolve_target)"
BUNDLE_PLUGINS="$TARGET_DIR/dsh/plugins"

if [ "${#PLUGINS[@]}" -eq 0 ]; then
  while IFS= read -r plugin; do
    PLUGINS+=("$plugin")
  done < <(all_plugins)
fi

[ "${#PLUGINS[@]}" -gt 0 ] || die "no plugins found"

say "harness: $HARNESS"
say "scope:   $SCOPE"
say "target:  $TARGET_DIR"
say "plugins: ${PLUGINS[*]}"

if [ "$DRY_RUN" = 0 ]; then
  mkdir -p -- "$TARGET_DIR/skills" "$TARGET_DIR/agents" "$BUNDLE_PLUGINS"
fi

for plugin in "${PLUGINS[@]}"; do
  install_plugin "$plugin"
done

if [ "$HARNESS" = "opencode" ]; then
  say "OpenCode will discover installed skills from $TARGET_DIR/skills and agents from $TARGET_DIR/agents."
else
  say "Claude Code-native files were copied to $TARGET_DIR. The original plugin install path still works: claude plugin install ./plugins/<name>"
fi
