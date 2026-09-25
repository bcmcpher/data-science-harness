---
name: run-comparison
description: >
  Execute a proposed comparison's analysis script with full DataLad provenance, on its branch,
  inside the project container. Trigger on "run the comparison", "run this analysis with
  provenance", "execute the comparison", "container-run this script", or after the user has
  written the analysis script for a branch created by propose-comparison.
plane: workflow
stamped: [A, T, P, E]
delegates_to: [containers]
---

# Skill: run-comparison

Run the user's analysis script as a provenanced, containerized computation so inputs, command,
container image, and outputs are all recorded (Actionability + Tracking) in a disposable,
rebuilt-from-spec environment (Portability + Ephemerality). DataLad is native, so you run
`datalad containers-run` yourself; you delegate only the image build to the **containers doer**.

## When to use
- A comparison branch exists (`analyze/propose-comparison`) and the analysis script is written.
- Do NOT use for one-off exploratory commands that produce no output files — those need no run
  record. Do NOT use to create the branch (that is `propose-comparison`).

## Steps
1. **Confirm context** — verify you are on the comparison's branch (`cmp/<slug>`) and the script
   exists in `code/`. If not, ask the user which branch/script, or route to `propose-comparison`.
2. **Gather run parameters**:
   - `command` — how to invoke the script (e.g. `python code/stats.py`)
   - `-i` inputs — the data files/globs the script reads (e.g. `participants.tsv`, `sub-*/…`)
   - `-o` outputs — where results land (prefer `derivatives/cmp-<slug>/…`)
   - `-m` message — a meaningful description of the run
   - container — **which** of the project's environments this comparison runs in (build/register on
     first use). A project has several; name the one, do not assume there is only one
3. **Ensure the container image exists (containers doer)** — if no `.sif` has been built yet for the
   environment this comparison needs, delegate to the **containers doer**:
   > "build a `.sif` for the `<name>` environment into `containers/<name>.sif`."
   It returns the image path, how that environment is pinned, its `containers_add` command, and a
   `binding`. Check `datalad containers-list`; if `<name>` is not registered, run the returned
   command yourself:
   ```bash
   datalad containers-add <name> --url <sif> --call-fmt "..."
   ```
   Skip both if the image is already built and registered.

   **Carry its pin forward rather than smoothing it over.** If the doer reports a pin as
   `unresolved` — a vendored image whose tag could not be resolved to a digest, or a manifest that
   is not pinned — the comparison can still run, and what it produces is not rebuildable. Say so in
   the report instead of letting a green run imply otherwise.
4. **Run it yourself**, with exactly one `-m` carrying the doer's `binding`:
   ```bash
   datalad containers-run -n <name> \
     -m "$(printf '<command> — cmp/<slug>\n\nDSH-Op: run-comparison\nDSH-Stage: analyze\nDSH-Binding: <binding>')" \
     -i <inputs> -o <outputs> "<command>"
   ```
5. **Handle the result**:
   - **ok** — note the commit sha and output paths.
   - **failed** — relay the error and suggested fix; nothing was committed. Stop.
6. **If confirmatory, resolve the obligation** — if `cmp/<slug>` was registered by
   `govern/preregister` (a `prereg-<slug>` obligation is `pending` in `obligations[]`), check the
   run against the frozen spec at `code/prereg/<slug>.md`; report any deviation, do not absorb it
   silently. Flip the obligation to `met` with `resolved_by` set to the run commit's sha, and save:
   ```bash
   datalad save -m "$(printf 'run-comparison: cmp/<slug> resolves prereg-<slug>\n\nDSH-Op: run-comparison\nDSH-Stage: analyze\nDSH-Obligation: prereg-<slug> resolved')" project.yaml
   ```
7. **Report** — commit(s), outputs, any deviation from a frozen spec, and that the run is
   replayable via `datalad rerun`.

## Constraints
- Always run through `datalad containers-run` so the environment is captured — do not fall back to
  a bare `datalad run` or a raw shell command for an analysis with outputs.
- Require a meaningful `-m` message; never a placeholder. Use exactly one `-m`.
- Do not write or "fix" the analysis script's science — if it errors on its own logic, surface it
  to the user; the harness owns provenance, not the model.
- Record activity in the run commit's `DSH-*` lines; never append to `project.yaml` `log`.
- Delegate the image build to the **containers doer**; run `containers-add` and
  `containers-run` yourself — DataLad is native, not a doer.
