#!/usr/bin/env bash
#
# check-runtimes.sh — offline presence check for one container runtime.
#
# Usage: check-runtimes.sh <docker|podman|apptainer|oci|digest>
#
# Prints `result: available`, or `result: unavailable` followed by what is missing and how to enable
# it. Exit codes: 0 = available, 1 = not available, 2 = usage error / unknown tool.
#
# It never builds anything, never pulls an image and never contacts a registry.
#
# Two things this gate answers that a presence check would not:
#
# 1. Whether the runtime RUNS, not merely whether the binary exists. A `docker` client with no
#    reachable daemon is on PATH, is executable, and fails on first use — reporting it as available
#    hands the caller a build that dies mid-step instead of a clean `unavailable` it can stop on.
#    Same property compendium-cli's gate needed, for the same reason.
#
# 2. Whether the runtime is ROOTLESS. This is the one genuinely new question here. A rootful-only
#    docker is "available" and still unusable to a user who is not in the docker group and cannot be
#    added to it — a normal situation on shared and institutional machines. Reporting it as plainly
#    available would send that user down a path that ends in a permission error, so the privilege
#    requirement is stated on the `found:` line and repeated as an explicit `caveat:`.
#
# Podman and Docker build the same layers from the same Dockerfile, so the artifact does not depend
# on which one ran. What differs is what each demands of the machine: podman is rootless and
# daemonless by default, docker normally is not. That is why `oci` prefers podman when both are
# present rather than treating them as interchangeable.
#
# `digest` is not a runtime. It asks a narrower question: is anything here able to resolve a mutable
# tag to an immutable digest? A vendored pipeline image pinned by tag is not pinned at all, and this
# is the check that tells a skill whether it can do anything about that. Note that resolution also
# needs a reachable registry, which this gate deliberately does not test — it is an offline check,
# and the skill reports an unresolved pin at the point of use.

set -uo pipefail

usage() {
  echo "usage: $(basename -- "$0") <docker|podman|apptainer|oci|digest>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
tool="$1"
missing=()
enable=()
caveat=()
found=""

# Sets found/caveat for docker, or leaves found empty. Split out because `oci` asks the same question.
probe_docker() {
  command -v docker >/dev/null 2>&1 || return 1
  docker info >/dev/null 2>&1 || return 2
  local ver sec
  ver="$(docker --version 2>/dev/null | head -1)"
  sec="$(docker info --format '{{json .SecurityOptions}}' 2>/dev/null)"
  if printf '%s' "$sec" | grep -q rootless; then
    found="docker ($ver, rootless)"
  else
    found="docker ($ver, rootful — needs the docker group or sudo)"
    caveat+=("docker is rootful here: building requires docker-group membership or sudo, which a user on a shared machine may not have and may not be able to obtain. podman needs neither")
  fi
  return 0
}

probe_podman() {
  command -v podman >/dev/null 2>&1 || return 1
  podman info >/dev/null 2>&1 || return 2
  local ver rootless
  ver="$(podman --version 2>/dev/null | head -1)"
  rootless="$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null)"
  if [ "$rootless" = "true" ]; then
    found="podman ($ver, rootless)"
  else
    found="podman ($ver, running as root)"
    caveat+=("podman is running rootful here, which is unusual — images it builds may carry root-owned paths")
  fi
  return 0
}

case "$tool" in
  docker)
    probe_docker
    case "$?" in
      1) missing+=("docker")
         enable+=("install Docker Engine or Docker Desktop. If you cannot get docker-group membership on this machine, install podman instead — it builds the same layers rootlessly") ;;
      2) missing+=("a reachable Docker daemon — the client is on PATH but 'docker info' failed")
         enable+=("start the daemon (systemctl --user start docker, or Docker Desktop). The client being present is not the same as the daemon being up, and a build would fail mid-step") ;;
    esac
    ;;
  podman)
    probe_podman
    case "$?" in
      1) missing+=("podman")
         enable+=("install podman. It is CLI-compatible with docker for build and save, and rootless by default — no daemon, no group membership") ;;
      2) missing+=("a working podman — the binary is on PATH but 'podman info' failed")
         enable+=("run 'podman info' to see why; a common cause is missing subuid/subgid ranges for rootless operation") ;;
    esac
    ;;
  apptainer)
    bin=""
    command -v apptainer >/dev/null 2>&1 && bin=apptainer
    [ -z "$bin" ] && command -v singularity >/dev/null 2>&1 && bin=singularity
    if [ -n "$bin" ] && "$bin" --version >/dev/null 2>&1; then
      found="$bin ($("$bin" --version 2>/dev/null | head -1))"
    elif [ -n "$bin" ]; then
      missing+=("a runnable $bin — the command is on PATH but failed to start")
      enable+=("reinstall it; present and broken is not the same as absent")
    else
      missing+=("apptainer (or singularity)")
      enable+=("install Apptainer. This is the runtime compute clusters provide, and .sif is what 'datalad containers-run' registers — an OCI image alone does not reach a cluster")
    fi
    ;;
  oci)
    # Prefer podman: same layers, no daemon, no group membership. Say which was chosen and why.
    probe_podman
    if [ -z "$found" ]; then
      probe_docker
      if [ -n "$found" ]; then
        found="$found [selected: docker; podman not usable]"
      else
        missing+=("an OCI builder (podman or docker)")
        enable+=("install podman (preferred: rootless, daemonless) or Docker Engine. Either builds the same layers from the same Dockerfile")
      fi
    else
      found="$found [selected: podman, preferred — rootless and daemonless]"
    fi
    ;;
  digest)
    # Not a runtime. Can anything here turn a mutable tag into an immutable digest?
    if command -v skopeo >/dev/null 2>&1 && skopeo --version >/dev/null 2>&1; then
      found="skopeo ($(skopeo --version 2>/dev/null | head -1)) — 'skopeo inspect docker://<ref>' returns the digest without pulling"
    elif command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
      found="podman ('podman manifest inspect <ref>')"
    elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      found="docker ('docker buildx imagetools inspect <ref>')"
    else
      missing+=("a way to resolve an image tag to a digest (skopeo, podman or docker)")
      enable+=("install skopeo — it resolves a tag without pulling the image, which is the cheapest way to pin a vendored pipeline container. Without one of these, a tag cannot be pinned and MUST NOT be recorded as if it were")
    fi
    ;;
  *)
    echo "unknown tool: $tool (expected docker, podman, apptainer, oci or digest)" >&2
    exit 2
    ;;
esac

echo "tool: $tool"
if [ "${#missing[@]}" -eq 0 ]; then
  echo "result: available"
  echo "found: $found"
  for c in ${caveat+"${caveat[@]}"}; do echo "caveat: $c"; done
  exit 0
fi

echo "result: unavailable"
for item in "${missing[@]}"; do echo "missing: $item"; done
for hint in "${enable[@]}"; do echo "enable: $hint"; done
exit 1
