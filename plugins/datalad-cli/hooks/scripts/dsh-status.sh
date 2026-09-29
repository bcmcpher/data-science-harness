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
#
# The ledger line counts open obligations and names overdue ones (pending, `due` before today in
# UTC), plus those due within `project.due_warn_days` days when project.yaml sets it.

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
# Obligations: pending counts as open; overdue when `due` is before today (UTC). With
# project.due_warn_days = N > 0, pending and due within today..today+N is due soon. ISO dates of
# fixed width compare as strings, so awk needs only the two boundary dates.
cutoff_date() {
  local n="$1" today="$2" c try
  for try in gnu bsd py; do
    case "$try" in
      gnu) c="$(date -u -d "+$n days" +%F 2>/dev/null)" ;;
      bsd) c="$(date -u -v+"$n"d +%F 2>/dev/null)" ;;
      py)  c="$(python3 -c 'import datetime as d, sys
print(d.datetime.now(d.timezone.utc).date() + d.timedelta(days=int(sys.argv[1])))' "$n" 2>/dev/null)" ;;
    esac
    # A date(1) that ignores the offset prints today; only a later date counts.
    case "$c" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) [[ "$c" > "$today" ]] && { printf '%s' "$c"; return 0; } ;;
    esac
  done
  return 1
}
if [ -f "$root/project.yaml" ]; then
  today="$(date -u +%F)"
  warn_days="$(awk '
    /^[^[:space:]#][^:]*:/ { section = $0; sub(/:.*/, "", section); next }
    section == "project" && /^[ \t]+due_warn_days:/ {
      v = $0; sub(/^[ \t]+due_warn_days:[ \t]*/, "", v); sub(/[ \t]*(#.*)?$/, "", v); print v; exit
    }
  ' "$root/project.yaml")"
  cutoff=""
  case "$warn_days" in
    ''|*[!0-9]*) warn_days=0 ;;
  esac
  warn_days=$((10#$warn_days))
  [ "$warn_days" -gt 0 ] && cutoff="$(cutoff_date "$warn_days" "$today")"
  US=$'\037'
  IFS="$US" read -r ledger_stage open_obl n_over over_ids n_soon soon_ids < <(awk -v today="$today" -v cutoff="$cutoff" -v US="$US" '
    function key(s, k,   v) {
      if (!match(s, "(^|[ \t{,\n])" k ":[ \t]*")) return ""
      v = substr(s, RSTART + RLENGTH)
      if (v ~ /^"/) { v = substr(v, 2); sub(/".*/, "", v) }
      else if (v ~ /^'\''/) { v = substr(v, 2); sub(/'\''.*/, "", v) }
      else { sub(/[,}\n].*/, "", v); sub(/[ \t]+$/, "", v) }
      return v
    }
    function add(list, v) { return list == "" ? v : list ", " v }
    # A quote opens only where a YAML scalar can start, so the apostrophe in `funder'\''s` is text.
    function opens(s, i,   b) { b = substr(s, i - 1, 1); return i == 1 || b ~ /[ \t{[,:]/ }
    # Drop a `#` comment: a `#` at the start or after a blank, outside quotes.
    function nocomment(s,   i, n, c, q) {
      n = length(s); q = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q != "") { if (c == q && (q == "'\''" || substr(s, i - 1, 1) != "\\")) q = ""; continue }
        if ((c == "\"" || c == "'\''") && opens(s, i)) { q = c; continue }
        if (c == "#" && (i == 1 || substr(s, i - 1, 1) ~ /[ \t]/)) { s = substr(s, 1, i - 1); break }
      }
      sub(/[ \t]+$/, "", s)
      return s
    }
    # Flow-style list (`obligations: [ {…}, {…} ]`): each top-level `{…}` is one entry.
    function flow(s,   i, n, c) {
      n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (fq != "") { if (c == fq && (fq == "'\''" || substr(s, i - 1, 1) != "\\")) fq = ""; if (depth) entry = entry c; continue }
        if ((c == "\"" || c == "'\''") && opens(s, i)) fq = c
        else if (c == "{") { if (++depth == 1) { entry = "\n"; continue } }
        else if (c == "}") { if (--depth == 0) { close_entry(); continue } }
        if (depth) entry = entry c
      }
      if (depth) entry = entry "\n"
    }
    function ids(list, n) { return n > 3 ? list ", …" : list }
    function close_entry(   st, due) {
      if (entry == "") return
      st = key(entry, "status"); due = key(entry, "due")
      if (due !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) due = ""
      if (st == "pending") {
        open++
        if (due != "" && due < today) { if (++over <= 3) over_l = add(over_l, key(entry, "id")) }
        else if (due != "" && cutoff != "" && due <= cutoff) { if (++soon <= 3) soon_l = add(soon_l, key(entry, "id")) }
      }
      entry = ""
    }
    # A top-level key starts a section; a `- ` at column 0 is a list item, not a key.
    /^[^[:space:]#-][^:]*:/ {
      close_entry(); section = $0; sub(/:.*/, "", section); flowlist = 0; depth = 0; fq = ""
      if (section == "obligations") {
        rest = nocomment(substr($0, index($0, ":") + 1))
        if (rest ~ /^[ \t]*\[/) { flowlist = 1; flow(rest) }
      }
    }
    section == "log" && match($0, /stage:[[:space:]]*[A-Za-z0-9_-]+/) {
      s = substr($0, RSTART, RLENGTH); sub(/stage:[[:space:]]*/, "", s); last = s
    }
    section == "obligations" && !/^[^[:space:]#-]/ {
      line = nocomment($0)
      if (line ~ /^[ \t]*$/) next
      if (flowlist) { flow(line); next }
      # An entry opens at a `-` (then a blank or the line end) with the indent of the first one;
      # deeper dashes belong to it.
      match(line, /^[ \t]*/); lead = RLENGTH
      if (substr(line, lead + 1) ~ /^-([ \t]|$)/ && (ind == "" || lead == ind)) {
        ind = lead; close_entry(); line = substr(line, lead + 2); entry = "\n"
      }
      if (entry != "") entry = entry line "\n"
    }
    END {
      close_entry()
      printf "%s%s%d%s%d%s%s%s%d%s%s\n", (last == "" ? "-" : last), US, open, US, over, US, ids(over_l, over), US, soon, US, ids(soon_l, soon)
    }
  ' "$root/project.yaml")
  [ -n "$stage" ] || { [ "$ledger_stage" != "-" ] && stage="$ledger_stage"; }
  ledger="${stage:-unset} stage; $open_obl open obligation$([ "$open_obl" = 1 ] || echo s)"
  groups=""
  [ "${n_over:-0}" -gt 0 ] && groups="$n_over overdue: $over_ids"
  [ "${n_soon:-0}" -gt 0 ] && groups="${groups:+$groups; }$n_soon due within ${warn_days}d: $soon_ids"
  [ -n "$groups" ] && ledger="$ledger ($groups)"
fi

printf '## DataLad status\n\n'
printf -- '- dataset: %s (branch %s)\n' "$root" "$branch"
printf -- '- tree: %s\n' "$tree"
[ -n "$subs" ] && printf -- '- subdatasets: %s\n' "$subs"
printf -- '- siblings: %s\n' "${sibs:-none}"
[ -n "$ledger" ] && printf -- '- ledger: %s\n' "$ledger"
exit 0
