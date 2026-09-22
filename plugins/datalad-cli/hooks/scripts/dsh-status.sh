#!/usr/bin/env bash
# dsh-status.sh — SessionStart hook: put the dataset's state in context before the first turn.
#
# Prints a compact status block for the innermost enclosing DataLad dataset. With --with-rules it
# first prints plugins/datalad-cli/rules/datalad.md, so Claude Code gets the rules and the status in
# one hook. OpenCode loads the rules through opencode.json instead; its generated adapter sets
# DSH_RULES_IN_CONFIG=1, which suppresses the rules here.
#
# Prints nothing and exits 0 outside a dataset or when datalad is absent. Never touches the network:
# ahead/behind counts come from the last-fetched remote refs.

set -uo pipefail

with_rules=0
dir="$PWD"
for arg in "$@"; do
  case "$arg" in
    --with-rules) with_rules=1 ;;
    *) dir="$arg" ;;
  esac
done

command -v datalad >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

# The innermost repository decides: a plain git repo nested in a dataset is not a dataset.
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -d "$root/.datalad" ] || exit 0

plugin_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "$with_rules" = 1 ] && [ "${DSH_RULES_IN_CONFIG:-0}" != 1 ] && [ -f "$plugin_root/rules/datalad.md" ]; then
  sed "s|\${CLAUDE_PLUGIN_ROOT}|$plugin_root|g" "$plugin_root/rules/datalad.md"
  printf '\n'
fi

g() { git -C "$root" "$@" 2>/dev/null; }

branch="$(g symbolic-ref --short -q HEAD || g rev-parse --short HEAD || echo '?')"

modified=0
untracked=0
while IFS= read -r line; do
  case "$line" in
    '??'*) untracked=$((untracked + 1)) ;;
    '') ;;
    *) modified=$((modified + 1)) ;;
  esac
done < <(g status --porcelain)
if [ $((modified + untracked)) -eq 0 ]; then
  tree="clean"
else
  tree="dirty — $modified modified, $untracked untracked"
fi

subs=""
if [ -f "$root/.gitmodules" ]; then
  while read -r _key path; do
    [ -n "$path" ] || continue
    if [ -e "$root/$path/.git" ]; then state="installed"; else state="not installed"; fi
    subs="${subs:+$subs, }$path ($state)"
  done < <(git config -f "$root/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null)
fi

sibs=""
for remote in $(g remote); do
  ref="refs/remotes/$remote/$branch"
  if g rev-parse -q --verify "$ref" >/dev/null; then
    counts="$(g rev-list --left-right --count "HEAD...$ref")"
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
    if [ "$ahead" = 0 ] && [ "$behind" = 0 ]; then
      rel="up to date as of last fetch"
    else
      rel="$ahead ahead, $behind behind as of last fetch"
    fi
  else
    rel="no fetched $branch"
  fi
  sibs="${sibs:+$sibs; }$remote — $rel"
done

# Stage: the latest DSH-Stage commit line wins; a ledger log entry is the fallback.
stage="$(g log -1 --format=%B --grep='^DSH-Stage:' | sed -n 's/^DSH-Stage:[[:space:]]*//p' | head -1)"
ledger=""
if [ -f "$root/project.yaml" ]; then
  read -r ledger_stage open_obl < <(awk '
    /^[^[:space:]#][^:]*:/ { section = $0; sub(/:.*/, "", section) }
    section == "log" && match($0, /stage:[[:space:]]*[A-Za-z0-9_-]+/) {
      s = substr($0, RSTART, RLENGTH); sub(/stage:[[:space:]]*/, "", s); last = s
    }
    section == "obligations" && /status:[[:space:]]*pending/ { open++ }
    END { printf "%s %d\n", (last == "" ? "-" : last), open }
  ' "$root/project.yaml")
  [ -n "$stage" ] || { [ "$ledger_stage" != "-" ] && stage="$ledger_stage"; }
  ledger="${stage:-unset} stage; $open_obl open obligation$([ "$open_obl" = 1 ] || echo s)"
fi

printf '## DataLad status\n\n'
printf -- '- dataset: %s (branch %s)\n' "$root" "$branch"
printf -- '- tree: %s\n' "$tree"
[ -n "$subs" ] && printf -- '- subdatasets: %s\n' "$subs"
printf -- '- siblings: %s\n' "${sibs:-none}"
[ -n "$ledger" ] && printf -- '- ledger: %s\n' "$ledger"
exit 0
