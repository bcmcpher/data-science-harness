#!/usr/bin/env bash
#
# check-tools.sh — offline presence check for one compendium build tool.
#
# Usage: check-tools.sh <myst> [--project <dir>]
#
# Prints `result: available`, or `result: unavailable` followed by what is missing and how to enable
# it. Exit codes: 0 = available, 1 = not available, 2 = usage error / unknown tool.
#
# It never builds anything, never reads a project and never contacts the network — but it does more
# than check that a file exists. A tool is `available` only if it actually RUNS: `mystmd` needs
# Node >= 20.19, and a node_modules/.bin/myst sitting next to an older Node is present, executable,
# and dies with a SyntaxError on first use. Reporting that as available hands the doer a build that
# fails mid-step instead of a clean `unavailable` it can report and stop on.
#
# This is a different question from a credential check, which stays presence-only: a key can only be
# validated by the service. Whether a local binary starts is answerable locally, so it is answered.
#
# Only tools that have a compendium-cli skill behind them are accepted here. `jupyter-book`,
# `repo2data` and the MCP scaffold are named in add-compendium-capability and are NOT yet built, so
# asking about them is a usage error rather than an `unavailable` answer. That distinction matters:
# `unavailable` tells the doer "installable, try again once it is there", and returning that for a
# tool with no skill would promise an invocation path that does not exist.
#
# MyST ships two ways that both matter here. A repository that declares `mystmd` in package.json has
# it at node_modules/.bin/myst after `npm ci` and does NOT need a global install; a user working
# outside such a repository needs `npm install -g mystmd`. Both are reported as available, and the
# `found:` line says which, because the invocation differs.
#
# A project-local install is found relative to the PROJECT, not to this script and not to whatever
# directory the caller happens to be sitting in — `--project <dir>` names it, defaulting to $PWD.
# Checking a bare relative path would make the answer depend on the caller's cwd, which is how a
# gate reports `unavailable` for a tool that is installed three directories up.

set -uo pipefail

usage() {
  echo "usage: $(basename -- "$0") <myst> [--project <dir>]" >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
tool="$1"
shift
project="$PWD"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) [ "$#" -ge 2 ] || usage; project="$2"; shift 2 ;;
    *)         usage ;;
  esac
done
missing=()
enable=()
found=""

case "$tool" in
  myst)
    candidates=()
    command -v myst >/dev/null 2>&1 && candidates+=("$(command -v myst)")
    [ -x "$project/node_modules/.bin/myst" ] && candidates+=("$project/node_modules/.bin/myst")
    for cand in ${candidates+"${candidates[@]}"}; do
      if "$cand" --version >/dev/null 2>&1; then
        found="$cand ($("$cand" --version 2>/dev/null | head -1))"
        break
      fi
    done
    if [ -z "$found" ]; then
      if [ "${#candidates[@]}" -gt 0 ]; then
        missing+=("a runnable mystmd (found ${candidates[0]}, but it failed to start)")
        enable+=("mystmd needs Node >= 20.19 — check 'node --version'. The binary is present and does not run, which is not the same as absent")
      else
        missing+=("mystmd")
        enable+=("npm install -g mystmd, or declare mystmd in the project's package.json and run npm ci then pass --project <that dir> — the harness's own paper/ builds the second way")
      fi
    fi
    ;;
  jupyter-book|repo2data|mcp-scaffold)
    echo "no skill for: $tool (named in add-compendium-capability, not built) — do not report this as unavailable, there is no invocation path behind it" >&2
    exit 2
    ;;
  *)
    echo "unknown tool: $tool (expected myst)" >&2
    exit 2
    ;;
esac

echo "tool: $tool"
if [ "${#missing[@]}" -eq 0 ]; then
  echo "result: available"
  echo "found: $found"
  exit 0
fi

echo "result: unavailable"
for item in "${missing[@]}"; do echo "missing: $item"; done
for hint in "${enable[@]}"; do echo "enable: $hint"; done
exit 1
