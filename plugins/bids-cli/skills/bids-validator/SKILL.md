---
name: bids-validator
description: >
  Auto-invoke when the user wants to check a dataset against the Brain Imaging Data Structure, find
  out why a dataset is failing BIDS validation, see which files a validator is ignoring, or check
  whether a BIDS validator is installed at all. Trigger on "validate BIDS", "is this BIDS-valid",
  "bids-validator", "what BIDS errors", "check my dataset structure", "BIDS conformance", or
  /bids-validator. Do NOT trigger for fixing the errors it reports (that is a curation planner's
  job), for converting raw data into BIDS (use the nipoppy toolbox), or for phenotypic-term
  annotation (use the annotate toolbox).
argument-hint: '[check|validate|explain] [--dataset <bids root>] [--json] [--ignore-warnings]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: bids-validator

Run a BIDS validator against a dataset root and report what it found — errors, warnings, and what it
did not look at.

**Read this before anything else: two different programs are called "the BIDS validator", they take
different flags, and no BIDS validator ships with this harness.** Guessing the invocation produces a
confident wrong answer, and the most damaging version of that answer is a clean report from a command
that silently validated nothing.

| Distribution | Invocation | State |
|---|---|---|
| `@bids/validator` | `deno run -A jsr:@bids/validator <dataset>` | current, schema-driven |
| `bids-validator` | `bids-validator <dataset>` | legacy Node CLI, still what most install docs say |
| `bids_validator` (Python) | — | **not a dataset validator**; see below |

The Python `bids_validator` package is a common trap. It exposes a `BIDSValidator` class that tests
whether a single *filename* matches the BIDS naming patterns, it installs no console script, and it
cannot validate a dataset. If it is the only thing installed, there is no validator installed.

## Steps

1. **Establish whether a validator exists, before reading the dataset.**
   ```bash
   bash plugins/bids-cli/scripts/check-validator.sh
   ```
   Exit 0 means a validator is present and the `found:` line names which distribution. Exit 1 means
   none is, and the `enable:` line says how to install one. Do not proceed to step 3 on exit 1.

2. **Confirm the surface before trusting it.** The distributions diverge on flags, output shape and
   exit codes, and they change between versions.
   ```bash
   bids-validator --version && bids-validator --help    # legacy
   deno run -A jsr:@bids/validator --help               # current
   ```
   If what you see differs from what this skill describes, **report the difference and follow the
   installed tool's own help.** Do not translate a flag from one distribution to the other.

3. **Validate the dataset root.** The target is the directory holding `dataset_description.json`,
   not a subject directory and not the derivatives tree.
   ```bash
   deno run -A jsr:@bids/validator <dataset root> --json     # current
   bids-validator <dataset root> --json                       # legacy
   ```
   Machine-readable output is worth asking for when the caller wants counts; plain output is easier
   to quote back when the caller wants to understand one error.

4. **Read the exit code as well as the output.** A validator that cannot parse the dataset at all and
   a validator that parsed it and found nothing wrong can both print very little. Report which one
   happened.

5. **Report what was not checked.** Validators skip files they do not recognize and honour
   `.bidsignore`. A dataset can validate cleanly with half its contents ignored, and that is not the
   same as a clean dataset.
   ```bash
   [ -f <dataset root>/.bidsignore ] && cat <dataset root>/.bidsignore
   ```

6. **Separate errors from warnings, and name the codes.** A caller deciding whether data can move
   downstream needs the issue codes and the affected file counts, not the full dump. Quote the top
   few messages verbatim rather than paraphrasing them.

7. **Report.** Use the shape the bids doer expects:
   ```
   op:        validate-bids
   validator: <distribution and version> | none
   result:    valid | invalid | unverified
   errors:    <count, with the top issue codes>
   warnings:  <count, with notable ones>
   ignored:   <what .bidsignore or the validator skipped>
   notes:     <install hint if no validator; which distribution was used>
   ```

## Constraints

- **Never report `valid` without having run a validator.** With no validator installed the result is
  `unverified`, and the structural checks the doer performs are findings, not a pass. "I could not
  check" and "I checked and it is fine" are different answers and must never be conflated.
- **Never invent or infer an issue code.** Every code in a report came out of the validator's own
  output in this session. A BIDS error code recalled from memory is the failure this skill exists to
  prevent, because it looks exactly like a real one.
- **Never report a clean validation without saying what was ignored.** A pass over a dataset whose
  contents are `.bidsignore`d is a misleading pass.
- **Read-only.** Never create, rename, move, delete or edit a dataset file, including
  `dataset_description.json`, `.bidsignore` and sidecars. Never "fix" a reported error. The bids doer
  is read-only by contract and this skill inherits that.
- **Do not commit.** The datalad doer owns `datalad save`. This skill has nothing to save.
- Do not run a validator against a derivatives directory as if it were the dataset root, and do not
  validate a path with no `dataset_description.json` — report that the target is not a BIDS dataset.
- Do not translate flags between distributions, and do not fall back to the Python `bids_validator`
  package to produce a dataset-level answer. It cannot give one.
