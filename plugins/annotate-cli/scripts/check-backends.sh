#!/usr/bin/env bash
#
# check-backends.sh — offline presence check for one annotation backend.
#
# Usage: check-backends.sh <bagel|pynidm|reproschema|snomed>
#
# Prints `result: available`, or `result: unavailable` followed by what is missing and how to enable
# it. Exit codes: 0 = available, 1 = not available (the doer reports that backend unavailable),
# 2 = usage error.
#
# This checks presence only. It never contacts the network and never prints a credential's value, so
# a present-but-invalid key passes here and fails at the tool, where the doer reports
# `result: failed`.
#
# "unavailable" is not "no term matched". The doer must report the two differently: an uninstalled
# backend means the question was never asked. That distinction is the point of this script — a
# per-backend answer lets a dataset gain Neurobagel annotation while SNOMED coverage stays empty,
# instead of failing the whole request.
#
# Only `bagel` has an annotate-cli skill today. The other three are checked here so the doer can
# name what is missing precisely, but even when their tool is installed there is no invocation path
# yet, which their `enable:` hint says.

set -uo pipefail

usage() {
  echo "usage: $(basename -- "$0") <bagel|pynidm|reproschema|snomed>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
backend="$1"
missing=()
enable=()

case "$backend" in
  bagel)
    if ! command -v bagel >/dev/null 2>&1; then
      missing+=("bagel executable")
      enable+=("pip install bagel-cli (provides the 'bagel' command), or run the neurobagel/bagelcli container")
    fi
    ;;
  pynidm)
    if ! python3 -c 'import nidm' 2>/dev/null; then
      missing+=("pynidm package")
      enable+=("pip install pynidm — note that no annotate-cli/skills/pynidm skill exists yet, so the doer still has no invocation path")
    fi
    ;;
  reproschema)
    if ! python3 -c 'import reproschema' 2>/dev/null; then
      missing+=("reproschema package")
      enable+=("pip install reproschema — note that no annotate-cli/skills/reproschema skill exists yet, so the doer still has no invocation path")
    fi
    ;;
  snomed)
    if [ -z "${SNOMED_API_KEY:-}" ] && { [ -z "${SNOMED_OWL:-}" ] || [ ! -f "${SNOMED_OWL:-}" ]; }; then
      missing+=("SNOMED CT source")
      enable+=("export SNOMED_API_KEY for a licensed terminology server, or SNOMED_OWL=/path/to/snomed.owl for a local release — SNOMED CT requires a licence in most countries, and no annotate-cli/skills/snomed-lookup skill exists yet")
    fi
    ;;
  *)
    echo "unknown backend: $backend (expected bagel, pynidm, reproschema or snomed)" >&2
    exit 2
    ;;
esac

echo "backend: $backend"
if [ "${#missing[@]}" -eq 0 ]; then
  echo "result: available"
  exit 0
fi

echo "result: unavailable"
for item in "${missing[@]}"; do
  echo "missing: $item"
done
for hint in "${enable[@]}"; do
  echo "enable: $hint"
done
exit 1
