#!/bin/sh
# dsh-log.sh — read the harness activity history from commit messages.
#
# Prints one JSON object per line, oldest first, for every commit whose message carries a
# `DSH-Op:` line:
#
#   {"sha":"…","ts":"…Z","subject":"…","run":false,"op":"…","stage":"…",
#    "binding":[…],"product":[…],"obligation":[…]}
#
# `run` is true for `datalad run` commits. DataLad appends its run record after the message, which
# hides DSH lines from git's trailer parser, so lines are read from the raw body and reading stops
# at the `=== Do not change lines below ===` marker. Timestamps are author dates in UTC.
#
# --legacy also prints each `log` entry of the dataset's project.yaml (written before activity moved
# to commits) in the same shape, with "sha":null and "legacy":true, merged in timestamp order.
#
# Usage: dsh-log.sh [-C <dir>] [--legacy] [<git log args>…]   e.g. dsh-log.sh -n 50
# Needs git and a POSIX shell with awk. Exit codes: 0 = ok, 1 = not in a git repository.

set -u

dir=.
legacy=0
while [ $# -gt 0 ]; do
  case "$1" in
    -C) dir="$2"; shift 2 ;;
    --legacy) legacy=1; shift ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) break ;;
  esac
done

top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || {
  echo "dsh-log: not in a git repository: $dir" >&2; exit 1; }

# Shared awk: JSON string escaping and object printing.
AWK_LIB='
function esc(s) {
  gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); gsub(/\r/, "", s)
  gsub(/\n/, "\\n", s)
  return "\"" s "\""
}
function arr(s,   n, i, parts, out) {
  if (s == "") return "[]"
  n = split(s, parts, "\034"); out = ""
  for (i = 1; i <= n; i++) out = out (i > 1 ? "," : "") esc(parts[i])
  return "[" out "]"
}
function emit(sha, ts, subject, run, op, stage, binding, product, obligation, extra) {
  printf "{\"sha\":%s,\"ts\":%s,\"subject\":%s,\"run\":%s,\"op\":%s,\"stage\":%s,", \
    (sha == "" ? "null" : esc(sha)), esc(ts), esc(subject), (run ? "true" : "false"), \
    esc(op), (stage == "" ? "null" : esc(stage))
  printf "\"binding\":%s,\"product\":%s,\"obligation\":%s%s}\n", \
    arr(binding), arr(product), arr(obligation), extra
}
function add(list, v) { return list == "" ? v : list "\034" v }
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
'

commits() {
  TZ=UTC git -C "$top" log --reverse --date=format-local:%Y-%m-%dT%H:%M:%SZ \
    --format='%H%x1f%ad%x1f%B%x1e' "$@" |
  awk -v RS='\036' "$AWK_LIB"'
  {
    rec = $0; sub(/^\n+/, "", rec)
    if (rec == "") next
    split(rec, f, "\037"); sha = f[1]; ts = f[2]; body = f[3]
    n = split(body, lines, "\n")
    subject = lines[1]
    run = (subject ~ /^\[DATALAD RUNCMD\]/)
    op = ""; stage = ""; binding = ""; product = ""; obligation = ""
    for (i = 2; i <= n; i++) {
      if (lines[i] ~ /^=== Do not change lines below ===/) { run = 1; break }
      if (lines[i] !~ /^DSH-[A-Za-z]+: /) continue
      key = lines[i]; sub(/: .*/, "", key)
      val = lines[i]; sub(/^DSH-[A-Za-z]+: /, "", val); val = trim(val)
      if (key == "DSH-Op" && op == "") op = val
      else if (key == "DSH-Stage") stage = val
      else if (key == "DSH-Binding") binding = add(binding, val)
      else if (key == "DSH-Product") product = add(product, val)
      else if (key == "DSH-Obligation") obligation = add(obligation, val)
    }
    if (op != "") emit(sha, ts, subject, run, op, stage, binding, product, obligation, "")
  }'
}

# Legacy ledger: `log:` entries in flow style ({ ts: …, op: …, … }, possibly spanning lines) or
# block style (- ts: … / key: … lines). Values may be quoted; comments are dropped.
legacy_log() {
  [ -f "$top/project.yaml" ] || return 0
  awk "$AWK_LIB"'
  function unq(v) {
    v = trim(v)
    if (v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2); gsub(/\\"/, "\"", v) }
    else if (v ~ /^'\''.*'\''$/) v = substr(v, 2, length(v) - 2)
    return v
  }
  function flush(   i, n, c, q, depth, cur, parts, np, k, v, e) {
    if (entry == "") return
    # split on top-level commas outside quotes
    np = 0; cur = ""; q = ""
    n = length(entry)
    for (i = 1; i <= n; i++) {
      c = substr(entry, i, 1)
      if (q != "") { cur = cur c; if (c == q && substr(entry, i - 1, 1) != "\\") q = ""; continue }
      if (c == "\"" || c == "'\''") { q = c; cur = cur c; continue }
      if (c == ",") { parts[++np] = cur; cur = ""; continue }
      cur = cur c
    }
    parts[++np] = cur
    delete kv
    for (i = 1; i <= np; i++) {
      e = index(parts[i], ":")
      if (e == 0) continue
      k = trim(substr(parts[i], 1, e - 1)); v = unq(substr(parts[i], e + 1))
      gsub(/[ \t]+/, " ", v)
      kv[k] = v
    }
    if (kv["op"] != "")
      emit("", kv["ts"], kv["note"], 0, kv["op"], kv["stage"], "", "", "", ",\"legacy\":true")
    entry = ""
  }
  /^log:/ { inlog = 1; next }
  inlog && /^[^ \t#-]/ { flush(); inlog = 0 }
  !inlog { next }
  {
    line = $0
    if (line ~ /^[ \t]*#/) next
    if (line ~ /^[ \t]*$/) next
    if (line ~ /^[ \t]*- /) { flush(); sub(/^[ \t]*- /, "", line); flow = (line ~ /^\{/) }
    if (flow) { gsub(/^[ \t]*\{|\}[ \t]*$/, "", line); entry = entry " " line }
    else entry = entry (entry == "" ? "" : ",") line
  }
  END { flush() }' "$top/project.yaml"
}

if [ "$legacy" = 1 ]; then
  { commits "$@"; legacy_log; } |
    awk '{ t = $0; sub(/^.*"ts":"/, "", t); sub(/".*/, "", t); print t "\t" $0 }' |
    sort -s -t "$(printf '\t')" -k1,1 | cut -f2-
else
  commits "$@"
fi
