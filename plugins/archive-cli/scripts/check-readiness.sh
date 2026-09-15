#!/usr/bin/env bash
#
# check-readiness.sh — offline presence check for one archive backend.
#
# Usage: check-readiness.sh <osf|zenodo|datacite>
#
# Prints `result: ready`, or `result: unminted` followed by what is missing and how to enable it.
# Exit codes: 0 = ready, 1 = not ready (the doer reports `result: unminted`), 2 = usage error.
#
# This checks presence only. It never prints a credential's value and never contacts the network,
# so a present-but-invalid token passes here and fails at the backend, where the doer reports
# `result: failed`. A credential stored only in DataLad's credential store (for example by
# `datalad osf-credentials`) is not visible to it; export it instead. That errs toward refusal.

set -uo pipefail

usage() {
  echo "usage: $(basename -- "$0") <osf|zenodo|datacite>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
backend="$1"
missing=()
enable=()

case "$backend" in
  zenodo)
    if [ -z "${ZENODO_TOKEN:-}" ]; then
      missing+=("ZENODO_TOKEN")
      enable+=("export ZENODO_TOKEN (a Zenodo personal access token with deposit:write and deposit:actions; use a sandbox.zenodo.org token with ZENODO_API=https://sandbox.zenodo.org/api for testing)")
    fi
    ;;
  osf)
    if ! python3 -c 'import datalad_osf' 2>/dev/null; then
      missing+=("datalad-osf extension")
      enable+=("install the datalad-osf extension into the environment that runs datalad")
    fi
    if [ -z "${OSF_TOKEN:-}" ] && { [ -z "${OSF_USERNAME:-}" ] || [ -z "${OSF_PASSWORD:-}" ]; }; then
      missing+=("OSF_TOKEN")
      enable+=("export OSF_TOKEN (an OSF personal access token), or both OSF_USERNAME and OSF_PASSWORD")
    fi
    ;;
  datacite)
    for var in DATACITE_REPOSITORY_ID DATACITE_PASSWORD DATACITE_PREFIX; do
      [ -n "${!var:-}" ] || missing+=("$var")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
      enable+=("export DATACITE_REPOSITORY_ID, DATACITE_PASSWORD and DATACITE_PREFIX from your DataCite repository account; set DATACITE_API=https://api.test.datacite.org for testing")
    fi
    ;;
  *)
    echo "unknown backend: $backend (expected osf, zenodo or datacite)" >&2
    exit 2
    ;;
esac

echo "backend: $backend"
if [ "${#missing[@]}" -eq 0 ]; then
  echo "result: ready"
  exit 0
fi

echo "result: unminted"
for item in "${missing[@]}"; do
  echo "missing: $item"
done
for hint in "${enable[@]}"; do
  echo "enable: $hint"
done
exit 1
