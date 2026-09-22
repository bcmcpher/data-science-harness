#!/usr/bin/env bash
# datalad-checkpoint.sh — Stop hook: remind, once per dirty state, to save with a real message.
#
# Default: when a turn ends inside a DataLad dataset with unsaved changes that have not already
# been reminded about, print {"decision":"block","reason":…} so the assistant continues once to
# save meaningfully or say why not. It never commits. The reminded state is a hash of
# `git status --porcelain`, kept in .git/dsh-last-reminded so it is never committed.
#
#   DATALAD_AUTOSAVE=1  silent save with an Auto-checkpoint message (the pre-reminder behaviour)
#   DATALAD_AUTOSAVE=0  do nothing at all
#
# Exits 0 silently when datalad is absent, outside a dataset, on a clean tree, when the state was
# already reminded, or when stop_hook_active says this turn was itself caused by the reminder.

set -uo pipefail

[ "${DATALAD_AUTOSAVE:-}" = "0" ] && exit 0
command -v datalad >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"
if printf '%s' "$payload" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -d "$root/.datalad" ] || exit 0
cd "$root" || exit 0

# git's porcelain status is empty exactly when the tree is clean (datalad status is not: it prints
# "nothing to save"), lists modified subdatasets, and needs no annex query.
status_output="$(git status --porcelain --ignore-submodules=none 2>/dev/null || true)"
[ -n "$status_output" ] || exit 0

file_list="$(printf '%s\n' "$status_output" | cut -c4- | tr '\n' ' ' | sed 's/ $//')"
if [ ${#file_list} -gt 200 ]; then
  file_list="${file_list:0:197}..."
fi

if [ "${DATALAD_AUTOSAVE:-}" = "1" ]; then
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  datalad save -m "Auto-checkpoint ${timestamp}: ${file_list:0:80}" >/dev/null 2>&1 || exit 0
  echo "[datalad] checkpoint ${timestamp}: ${file_list:0:80}"
  exit 0
fi

git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null)" || exit 0
state_file="$git_dir/dsh-last-reminded"
hash="$(printf '%s' "$status_output" | git hash-object --stdin)"
[ "$(cat "$state_file" 2>/dev/null)" = "$hash" ] && exit 0
printf '%s\n' "$hash" > "$state_file"

reason="The DataLad dataset has unsaved changes: ${file_list}. Save them with datalad save -m \"<what> — <why>\" (one -m), or tell the user why they stay unsaved. This reminder does not repeat for the same changes."
python3 -c 'import json,sys; print(json.dumps({"decision": "block", "reason": sys.argv[1]}))' "$reason" 2>/dev/null \
  || printf '{"decision":"block","reason":"%s"}\n' "$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')"
exit 0
