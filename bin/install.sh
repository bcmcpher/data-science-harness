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
    BEGIN { fm = 0; inserted = 0 }
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
    fm == 1 && $0 ~ /^mode:[[:space:]]*/ { inserted = 1; print; next }
    { print }
  ' "$src" > "$dest"
}

rewrite_installed_markdown() {
  local file="$1" root_for_claude_var="$2" bundle_plugins="$3"
  [ "$DRY_RUN" = 1 ] && return
  [ -f "$file" ] || return

  # These are prompt-visible paths, not executable code. Rewrite only installed copies.
  sed -i \
    -e "s|\${CLAUDE_PLUGIN_ROOT}|$root_for_claude_var|g" \
    -e "s|plugins/|$bundle_plugins/|g" \
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

install_plugin() {
  local plugin="$1"
  local src_plugin="$ROOT/plugins/$plugin"
  local dest_plugin="$BUNDLE_PLUGINS/$plugin"
  local skill_dir skill_name dest_skill agent_file agent_name dest_agent

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
