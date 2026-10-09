---
name: repronim-containers
description: >
  Auto-invoke before building a pipeline image that ReproNim may already publish (fMRIPrep, MRIQC,
  QSIPrep, a BIDS app), or when the user asks "is there a ready-built container for X", "use the
  ReproNim containers", "install ///repronim/containers", or /repronim-containers. Looks up the
  ReproNim/containers DataLad dataset for a tool and version, reports the match and its size, and
  returns the DataLad commands the planner runs to install, fetch and run it. Do NOT trigger to
  build an image (use oci-build), to generate a recipe (use neurodocker), or to run anything — this
  skill reads a catalog and returns commands; it never installs, fetches or runs.
argument-hint: '<tool> [<version>] [--path containers/repronim]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: repronim-containers

Find whether `///repronim/containers` already provides an image, and hand the planner the DataLad
commands that use it.

ReproNim/containers is a DataLad dataset of ready-built Singularity images for BIDS apps and
neuroimaging tools. Each registered image runs through the dataset's own wrapper, and each is
pinned by git-annex content. Building an image this dataset already provides duplicates work and
loses the wrapper.

**You read and report. The planner runs DataLad.** Installing a subdataset, fetching an image and
running it are DataLad writes. They belong to the main thread, so provenance has one owner.

## What the dataset holds

Measured 2026-10-09, at subdataset commit `76e98307`:

- 340 registered containers in `.datalad/config`, as `datalad.containers.<name>.image` and
  `.cmdexec` entries. Most register only the **latest** version, such as
  `bids-fmriprep` → `images/bids/bids-fmriprep--25.2.6.sif`.
- Older versions are still **files** in the tree, not registered:
  `images/<category>/<name>--<version>.<sif|sing|simg>` (for example
  `images/bids/bids-fmriprep--23.2.0.sing`).
- A metadata-only clone is about 17 MB. Image content is not fetched by a clone.
- Images are large: `bids-mriqc--24.0.2.sif` is 4.95 GB. The size is in the annex key
  (`MD5E-s<bytes>--…`), so it can be reported before any download.

## Steps

1. **Look up the catalog, in one Bash call.** The script below prefers an installed subdataset
   (default path `containers/repronim/`). Otherwise it reads a temporary metadata-only clone
   **outside the dataset**, and its trap removes that clone when the shell exits, whether the
   lookup succeeds or fails. Run it as a single command: a trap and a variable do not survive into
   a second Bash call. It never runs `datalad get`. Substitute the tool and version on the first
   line; leave the version empty to list every version.
   ```bash
   # repronim-lookup:begin
   bash -s -- "<tool>" "<version>" <<'LOOKUP'
   set -u
   tool=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]') ver=${2:-} cat=containers/repronim
   if [ -f "$cat/.datalad/config" ]; then
     echo "source: installed $cat"
   else
     tmp=$(mktemp -d)
     trap 'chmod -R u+w "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
     echo "tmpclone: $tmp"
     if ! datalad -l error clone ///repronim/containers "$tmp/c" >/dev/null 2>&1; then
       echo "catalog: not checked (no installed subdataset, and the clone failed)"; exit 0
     fi
     cat=$tmp/c; echo "source: temporary clone (removed on exit)"
   fi
   echo "binding: containers/repronim@$(git -C "$cat" rev-parse --short HEAD)"
   # Registered images, as "<image path> <name>", to mark which files are registered.
   git config -f "$cat/.datalad/config" --get-regexp '^datalad\.containers\..*\.image$' \
     | sed -E 's/^datalad\.containers\.(.*)\.image (.*)$/\2 \1/' > "${tmp:-/tmp}/.rn-reg.$$"
   # Image files named <name>--<version>.<sif|sing|simg>, where <name> is the tool or ends in -<tool>.
   # Exact string comparison, not a regex: dots in a version are literal.
   git -C "$cat" ls-tree -r --name-only HEAD images \
     | awk -v t="$tool" -v v="$ver" -v reg="${tmp:-/tmp}/.rn-reg.$$" '
         BEGIN { while ((getline l < reg) > 0) { split(l, a, " "); r[a[1]] = a[2] } }
         { b = $0; sub(/.*\//, "", b); i = index(b, "--"); if (!i) next
           n = tolower(substr(b, 1, i - 1)); rest = substr(b, i + 2)
           if (rest !~ /\.(sif|sing|simg)$/) next
           ver = rest; sub(/\.(sif|sing|simg)$/, "", ver)
           if (n != t && substr(n, length(n) - length(t)) != "-" t) next
           if (v != "" && ver != v) next
           print $0, ver, ($0 in r ? "registered:" r[$0] : "unregistered") }' \
     | while read -r path ver state; do
         key=$(git -C "$cat" annex lookupkey "$path" 2>/dev/null)
         size=$(printf '%s' "$key" | sed -nE 's/^[A-Z0-9]+-s([0-9]+)--.*/\1/p')
         here=$(git -C "$cat" annex find --in here "$path" 2>/dev/null)
         echo "file: $path version=$ver $state bytes=${size:-?} fetched=$([ -n "$here" ] && echo yes || echo no)"
         case $state in registered:*) echo "  cmdexec: $(git config -f "$cat/.datalad/config" "datalad.containers.${state#registered:}.cmdexec")";; esac
       done
   rm -f "${tmp:-/tmp}/.rn-reg.$$"
   LOOKUP
   # repronim-lookup:end
   ```

2. **Classify the result** from the `file:` lines:
   - **registered match**: a `registered:<name>` line at the requested version.
   - **file match**: an `unregistered` line at the requested version. The version is in the tree
     but not registered, and needs a `containers-add` by the planner (step 3).
   - **no match**: no line at the requested version. Rerun with an empty version, and say which
     versions the catalog has.
   - **not checked**: the script printed `catalog: not checked`. Report it with the reason and stop.
     That never blocks a build.

   `bytes=` comes from the annex key (`MD5E-s<bytes>--…`), so the size is known before any download.
   Report it in human units with the match.

   Nearly every entry runs `{img_dspath}/scripts/singularity_cmd run {img} {cmd}`. That wrapper:
   - runs with a cleaned environment and a bound temporary `HOME` and `/tmp`;
   - reads `SINGULARITY_CMD` (`run` by default, or `exec`);
   - uses a Docker shim when `REPRONIM_USE_DOCKER` is set, or on a non-Linux host;
   - wraps the run in `duct` when `REPRONIM_USE_DUCT` is set;
   - calls `singularity`. A host with only `apptainer` needs a `singularity` symlink, or
     `REPRONIM_USE_DOCKER`.

3. **Return the commands for the planner.** From the superdataset root:
   ```bash
   datalad clone -d . ///repronim/containers containers/repronim      # once; ~17 MB, no images
   datalad get containers/repronim/<image path>                         # this one image only
   datalad containers-run -n containers/repronim/<name> \
     --input <inputs> --output <outputs> -- <args>
   ```
   `datalad containers-run` fetches a missing image by itself, so the size from step 2 must reach
   the caller before the planner runs either command, not only before `datalad get`.
   From the superdataset, a subdataset's container is named with its path prefix
   (`containers/repronim/bids-mriqc`), and `datalad containers-list -r` lists them.
   For a **file match**, the planner registers that version in the **superdataset**, so ReproNim's
   subdataset stays at the upstream commit the pin names. `{img_dspath}` is then the superdataset
   root, so the call format reaches the wrapper through the subdataset path:
   ```bash
   datalad containers-add <name>-<version> \
     -i containers/repronim/<image path> \
     --call-fmt '{img_dspath}/containers/repronim/scripts/singularity_cmd run {img} {cmd}'
   datalad containers-run -n <name>-<version> --input <inputs> --output <outputs> -- <args>
   ```
   Registering fetches nothing; the run fetches the image.

4. **Report.**
   ```
   op:       repronim-containers-lookup
   request:  <tool> <version>
   catalog:  match <name> <version> | file match <path> | no match (has: <versions>) | not checked (<why>)
   source:   installed containers/repronim | temporary clone (removed)
   image:    <path> (<size>, fetched: yes|no)
   callfmt:  <cmdexec>
   binding:  containers/repronim@<subdataset commit>
   commands: <the step-3 commands, for the planner>
   notes:    the pin is the subdataset commit plus the annex key; updating the subdataset is a
             version change the planner records
   ```

## Constraints

- **Never report an image as available to run when its content is not fetched.** `fetched: no`
  until `datalad get` has run.
- **Never fetch annex content.** A lookup reads git metadata only. The planner runs `datalad get`
  (or `containers-run`, which fetches too) for the one image chosen, after the caller has seen its
  size.
- **Never leave the temporary clone behind.** Remove it on every exit path.
- **Never install the subdataset, register, or run.** Return the commands; the planner runs them.
- **Never treat a match as a decision.** Report it and let the caller choose; they may need a version
  ReproNim does not carry, or a derived image.
- A ReproNim image is **vendored**. Its pin is the subdataset commit the superdataset records plus
  the image's annex key. It needs no OCI digest. Moving the subdataset to a newer commit is a version
  change, not a no-op.
