#!/usr/bin/env bash
#
# check-tools.sh — offline presence check for one Lab-in-a-Box deployment tool.
#
# Usage: check-tools.sh <pyinfra|forgejo>
#
# Prints `result: available`, or `result: unavailable` followed by what is missing and how to enable
# it. Exit codes: 0 = available, 1 = not available, 2 = usage error / unknown tool.
#
# It never contacts a target host, never reads an inventory and never runs a deployment. A tool is
# `available` only if it actually RUNS (`--version`), because a present-but-broken entry point here
# would hand the doer a failure part-way through a deployment rather than a clean stop.
#
# `forgejo` checks for an API client and a credential, not for a server. Standing an instance UP is a
# pyinfra deployment; this capability's forgejo skill only creates and inspects repositories on an
# instance that already runs. A present token is not a valid one — this contacts nothing, so a
# revoked or under-scoped token passes here and fails at the instance, where it is `failed` rather
# than `unavailable`.
#
# What this script deliberately does NOT check: whether the operator can reach the target hosts,
# whether SSH keys are loaded, or whether the inventory is correct. Those need the network or the
# inventory, and getting them wrong is the failure this capability is most careful about — so they
# belong to the doer's confirmation step, where a human reads a hostname before anything runs.

set -uo pipefail

usage() {
  echo "usage: $(basename -- "$0") <pyinfra|forgejo>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
tool="$1"
missing=()
enable=()
found=""

case "$tool" in
  pyinfra)
    if command -v pyinfra >/dev/null 2>&1 && pyinfra --version >/dev/null 2>&1; then
      found="pyinfra ($(pyinfra --version 2>/dev/null | head -1))"
    elif command -v pyinfra >/dev/null 2>&1; then
      missing+=("a runnable pyinfra — the command is on PATH but failed to start")
      enable+=("reinstall it — 'pip install --force-reinstall pyinfra' — the entry point is present and broken, which is not the same as absent")
    else
      missing+=("pyinfra is not installed")
      enable+=("pip install pyinfra (provides the 'pyinfra' command). Deploying additionally needs SSH access to the target hosts, which this check does not and cannot verify")
    fi
    ;;
  forgejo)
    if command -v curl >/dev/null 2>&1; then
      found="curl ($(curl --version 2>/dev/null | head -1 | cut -d' ' -f1-2))"
    else
      missing+=("curl is not installed")
      enable+=("install curl — the Forgejo API is reached over HTTP and there is no offline path to a repository")
    fi
    if [ -z "${FORGEJO_URL:-}" ]; then
      missing+=("FORGEJO_URL")
      enable+=("export FORGEJO_URL (the instance's base URL, for example https://git.lab.example.org). A self-hosted instance has no default hostname, so there is deliberately nothing to fall back to")
    fi
    if [ -z "${FORGEJO_TOKEN:-}" ]; then
      missing+=("FORGEJO_TOKEN")
      enable+=("export FORGEJO_TOKEN (a Forgejo access token with write:repository). Creating a repository needs it; probing the instance version does not")
    fi
    ;;
  *)
    echo "unknown tool: $tool (expected pyinfra or forgejo)" >&2
    exit 2
    ;;
esac

echo "tool: $tool"
if [ "${#missing[@]}" -eq 0 ]; then
  echo "result: available"
  echo "found: $found"
  # Printed on the AVAILABLE path deliberately. This is the moment a green check is most likely to
  # be read as "ready to deploy", and it is not: host reachability, SSH keys and the correctness of
  # the inventory are unchecked here, on purpose, because checking them needs the network.
  case "$tool" in
    pyinfra)
      echo "note: this does not and cannot verify host reachability, SSH access, or that the inventory names the hosts you intend — those are confirmed by a human reading the plan"
      ;;
    forgejo)
      echo "note: a present token is not a valid one — this contacts nothing, so a revoked or under-scoped token passes here and fails at the instance. It also says nothing about whether the instance is running"
      ;;
  esac
  exit 0
fi

echo "result: unavailable"
for item in "${missing[@]}"; do echo "missing: $item"; done
for hint in "${enable[@]}"; do echo "enable: $hint"; done
exit 1
