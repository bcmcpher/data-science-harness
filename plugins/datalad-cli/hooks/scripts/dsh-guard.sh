#!/usr/bin/env bash
# dsh-guard.sh — PreToolUse(Bash) hook: stop the git commands that lose data in a DataLad dataset.
#
# Reads the Claude Code hook payload on stdin ({"tool_input":{"command":…},"cwd":…}).
#   exit 2 + stderr  — block: `git commit` (use datalad save) and `git push` (use datalad push)
#   exit 0 + JSON    — warn:  `git annex add|drop|unlock`, and a repeated -m to datalad save/run
#   exit 0 silent    — everything else, anything outside a dataset, and DSH_GUARD=0
#
# Commands are split on ; && || | and matched by token, so `echo "git commit"` passes and
# `cd code && git commit` does not. A `cd <dir>` segment moves the directory later segments are
# checked in. Needs python3; without it the guard allows everything.

[ "${DSH_GUARD:-1}" = "0" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

exec python3 -c '
import json, os, shlex, subprocess, sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)
command = (payload.get("tool_input") or {}).get("command") or ""
cwd = payload.get("cwd") or os.getcwd()
if not command.strip():
    sys.exit(0)

def is_dataset(d):
    try:
        top = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        return False
    return bool(top) and os.path.isdir(os.path.join(top, ".datalad"))

try:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|")
    lexer.whitespace_split = True
    tokens = list(lexer)
except ValueError:
    sys.exit(0)  # unbalanced quotes: let the shell report it

segments, seg = [], []
for t in tokens:
    if t and set(t) <= set(";&|"):
        segments.append(seg); seg = []
    else:
        seg.append(t)
segments.append(seg)

GIT_OPTS_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
DL_OPTS_WITH_ARG = {"-c", "-l", "--log-level", "-f", "--output-format", "--result-renderer",
                    "--report-status", "--report-type", "--on-failure", "--cmd"}

blocks, warns = [], []
here = cwd
for seg in segments:
    while seg and "=" in seg[0] and not seg[0].startswith("="):
        seg = seg[1:]  # VAR=value prefixes
    while seg and seg[0] in ("command", "exec", "time", "nohup"):
        seg = seg[1:]
    if not seg:
        continue
    prog = os.path.basename(seg[0])
    if prog == "cd":
        target = seg[1] if len(seg) > 1 else os.path.expanduser("~")
        here = os.path.normpath(os.path.join(here, os.path.expanduser(target)))
        continue
    if prog == "git":
        where, i = here, 1
        while i < len(seg) and seg[i].startswith("-"):
            if seg[i] == "-C" and i + 1 < len(seg):
                where = os.path.normpath(os.path.join(where, seg[i + 1]))
            i += 2 if seg[i] in GIT_OPTS_WITH_ARG else 1
        sub = seg[i] if i < len(seg) else ""
        if sub not in ("commit", "push", "annex") or not is_dataset(where):
            continue
        if sub == "commit":
            blocks.append("`git commit` in a DataLad dataset: record the change with "
                          "`datalad save -m \"<what> — <why>\" [paths]` instead, so annexed "
                          "content and subdatasets are saved too.")
        elif sub == "push":
            blocks.append("`git push` in a DataLad dataset sends history without annexed "
                          "content: use `datalad push --to <sibling>` instead.")
        else:
            verb = seg[i + 1] if i + 1 < len(seg) else ""
            alt = {"add": "datalad save", "drop": "datalad drop", "unlock": "datalad unlock"}
            if verb in alt:
                warns.append(f"`git annex {verb}` bypasses DataLad bookkeeping; "
                             f"prefer `{alt[verb]}`.")
    elif prog == "datalad":
        i = 1
        while i < len(seg) and seg[i].startswith("-"):
            i += 2 if seg[i] in DL_OPTS_WITH_ARG else 1
        sub = seg[i] if i < len(seg) else ""
        if sub in ("save", "run", "containers-run"):
            n = sum(1 for t in seg[i + 1:] if t in ("-m", "--message")
                    or t.startswith("--message="))
            if n > 1:
                warns.append(f"`datalad {sub}` was given {n} messages; DataLad keeps only the "
                             "last and drops the rest. Use one -m with the body after a blank line.")

if blocks:
    sys.stderr.write("Blocked by dsh-guard (DSH_GUARD=0 disables):\n- " + "\n- ".join(blocks) + "\n")
    sys.exit(2)
if warns:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": "dsh-guard: " + " ".join(warns)}}))
sys.exit(0)
'
