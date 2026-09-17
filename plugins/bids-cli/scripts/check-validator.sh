#!/usr/bin/env bash
#
# check-validator.sh — offline presence check for a BIDS validator.
#
# Usage: check-validator.sh [--quiet]
#
# Prints `result: available` and which distribution was found, or `result: unavailable` followed by
# what is missing and how to enable it. Exit codes: 0 = available, 1 = not available (the doer
# reports `unverified` and falls back to structural checks), 2 = usage error.
#
# This checks presence only. It never runs a validation, never reads a dataset and never contacts
# the network, so it is safe to run before the doer has been told what to look at.
#
# "unavailable" is not "the dataset is invalid", and it is not "the dataset is valid". It means the
# question was never asked. The bids doer's read-only contract already names that third state
# `unverified`; this script is what lets it tell the difference without guessing.
#
# Two distributions validate a whole dataset, and they do not share a command line:
#
#   @bids/validator   the current Deno/JSR implementation, run via `deno` or `npx`
#   bids-validator    the legacy Node implementation, still what most install instructions say
#
# This script reports which one it found and stops there. Picking the right invocation for that
# distribution is the skill's job, because the flags differ and guessing them produces a confident
# wrong answer — see skills/bids-validator/SKILL.md.
#
# The Python `bids_validator` package deliberately does NOT count. It exposes a `BIDSValidator`
# class that tests whether a single *path* matches the BIDS naming patterns, it installs no console
# script, and it does not validate a dataset. Treating it as a validator would report `available`
# for a capability that does not exist, which is the one thing this script must never do.

set -uo pipefail

quiet=0
case "${1:-}" in
  --quiet) quiet=1 ;;
  "")      ;;
  *)       echo "usage: $(basename -- "$0") [--quiet]" >&2; exit 2 ;;
esac
[ "$#" -le 1 ] || { echo "usage: $(basename -- "$0") [--quiet]" >&2; exit 2; }

found=""
if command -v bids-validator >/dev/null 2>&1; then
  found="bids-validator (legacy Node CLI on PATH)"
elif command -v deno >/dev/null 2>&1; then
  found="deno (can run jsr:@bids/validator)"
fi

echo "tool: bids-validator"
if [ -n "$found" ]; then
  echo "result: available"
  [ "$quiet" -eq 1 ] || echo "found: $found"
  exit 0
fi

echo "result: unavailable"
echo "missing: a BIDS validator"
echo "enable: deno run -A jsr:@bids/validator (current), or npm install -g bids-validator (legacy) — neither ships with the harness, and the doer reports 'unverified' rather than a pass until one is present. The Python bids_validator package is not a substitute: it matches single filenames against the naming patterns and cannot validate a dataset"
exit 1
