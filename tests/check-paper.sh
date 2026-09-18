#!/usr/bin/env bash
# Build paper/ and fail on anything that would ship a broken manuscript.
#
# `myst build --strict` exits non-zero on build ERRORS, but an unresolved citation is a WARNING —
# so a bibliography key that does not exist builds green. That is the failure mode that actually
# matters here: docs/references/references.bib is the single citation source of truth and paper/
# references it rather than carrying a copy, so a rename on one side must fail loudly on the other.
#
# Uses `--site` rather than `--html`: the static HTML export starts the theme server to crawl
# itself and does not terminate, which would hang CI.
#
# Exit codes: 0 = clean, 1 = build error or unresolved reference, 2 = skipped (mystmd not installed).
#
# Usage: tests/check-paper.sh
set -uo pipefail

root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -x "$root/node_modules/.bin/myst" ]; then
  myst_bin="$root/node_modules/.bin/myst"
elif command -v myst >/dev/null 2>&1; then
  myst_bin="$(command -v myst)"
else
  echo "SKIP: mystmd not installed (npm ci, or npm install -g mystmd)" >&2
  exit 2
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

( cd "$root/paper" && "$myst_bin" build --site --strict --ci ) 2>&1 | tee "$log"
rc="${PIPESTATUS[0]}"

if [ "$rc" -ne 0 ]; then
  echo "ERROR: myst build failed (exit $rc)" >&2
  exit 1
fi

# Warnings myst does not treat as errors but that would ship a broken manuscript.
if grep -qE 'Could not link citation|Could not resolve|Unknown reference|No bibliography' "$log"; then
  echo >&2
  echo "ERROR: unresolved reference in paper/ — every citation must resolve from" >&2
  echo "       docs/references/references.bib. Offending lines:" >&2
  grep -nE 'Could not link citation|Could not resolve|Unknown reference|No bibliography' "$log" >&2
  exit 1
fi

echo "paper/ builds; all references resolve"
