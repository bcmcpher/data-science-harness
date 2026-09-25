## Context

Facts this design relies on, checked on 2026-09-25 against HeuDiConv v1.5.1 (PyPI, `requires-python
>=3.9`) and its source on `master`:

- `-c/--converter` takes `dcm2niix` (the default) or `none`. With `none`, HeuDiConv writes
  `<outdir>/.heudiconv/<subject>/info/dicominfo[_ses-<ses>].tsv` and converts nothing.
- `-f/--heuristic` takes the name of a built-in heuristic (`reproin`, `convertall`, …) or a path
  to a Python file.
- Input comes from `--files <paths…>` or `-d <template>`. The template uses `{subject}` and
  `{session}`; these two are mutually exclusive.
- `-b/--bids` writes a BIDS layout. `--datalad` makes HeuDiConv create and save DataLad datasets
  itself. `--overwrite` replaces existing output.
- `-l/--locator` is the study path under `-o`. `reproin` derives it from the DICOM Study
  Description (`Region^Exam` split into directories). `"unknown"` skips the study. An empty value
  places the output directly in `-o` (`main.py`: `op.join(outdir, locator or "")`).
- The `dicominfo` table includes `patient_id`, `patient_age` and `patient_sex` columns, so it
  holds identifiers.
- `reproin` recognizes the datatypes `anat`, `func`, `fmap` and `dwi`. It knows `beh` but does
  not convert it. It skips other datatypes with a warning, and strips a leading `PREFIX:` and
  `WIP `.
- `dcm2niix` is a separate binary (here `/usr/bin/dcm2niix`, v1.0.20240202).

In the harness:

- `curate/raw-to-bids` delegates only to the nipoppy doer. The nipoppy-cli `bids-commands.md`
  already covers `bidsify` with HeuDiConv as a configured converter.
- `project/new-project` puts raw BIDS at the dataset root and linked sources under `inputs/`.
- `PINNABLE_AGENTS` is `{"bids-doer", "coordinator"}`, so only read-only agents may pin a model.
- `bids-doer` pins `haiku` and never modifies a dataset.

## Goals / Non-Goals

**Goals:**
- A YODA dataset with DICOMs reaches BIDS through a provenanced run, without nipoppy.
- ReproIn-named data needs no hand-written heuristic. Other data gets a scaffold the user
  confirms, versioned in the dataset.
- The planner stays tool-agnostic. It asks for a conversion in words and runs what comes back.

**Non-Goals:**
- Replacing the nipoppy path. A nipoppy dataset keeps its converter configuration, its
  curation-status file and its doer.
- Anonymizing subject IDs (`--anon-cmd`) or defacing. Those are `curate/deidentify` decisions.
- Scanner-side ReproIn setup (naming sequences, the `reproin` study scripts).

## Decisions

**D1. A new plugin pair, not an extension of `bids`.** `heudiconv` (doer) and `heudiconv-cli`
(toolbox) follow the 1:1 doer-to-toolbox pattern of the other seven capabilities. The bids doer is
read-only and pins `haiku`. Adding conversion would force it to drop both properties, which
govern/qc-review relies on.

*Alternative: fold conversion into the bids doer.* Rejected for the reason above. Validation and
conversion also fail differently: a validator that errors changed nothing, while a converter that
errors may have written half a subject.

**D2. Two passes; the first runs outside the dataset.** The doer runs the first pass itself
(`-c none -f convertall`) with `-o` set to a scratch directory, and reads `dicominfo` from there.
Nothing is written into the dataset, so the doer can run it without a provenance record. The
series table the user sees comes from the DICOMs actually present. Annexed DICOMs must be present
first: the planner runs `datalad get` on the source before delegating, and the doer reports
missing content rather than fetching it.

*Alternative: record the first pass as its own `datalad run`.* Rejected: it commits identifiers
(`dicominfo`) to history for an inspection step whose result is already captured by the second
pass.

**D3. ReproIn is detected, and the detection is shown.** The doer selects `reproin` when every
non-derived series' protocol name parses as ReproIn: after stripping `PREFIX:` and `WIP `, it
starts with `anat`, `func`, `fmap` or `dwi`, followed by `-<suffix>` or `_<entity>-<value>`
fields. It returns the series table with the BIDS name each series will receive. The planner
shows that table with the command before the run, which is where a mismatch is caught. If only
some series parse, the result is treated as not ReproIn.

*Alternative: always ask the user whether the data is ReproIn.* Rejected: most users do not know
the convention's name, and the series names answer the question more reliably.

**D4. A non-ReproIn heuristic is scaffolded into `code/heuristics/<name>.py`, confirmed, and
saved before conversion.** The doer writes a heuristic with one `create_key` per series in the
table and a proposed BIDS name for each. Series it cannot place are left out, marked in a comment,
and listed in its result (`result: needs-confirmation`, `save_via: planner`). The planner shows
the mapping, the user edits or confirms it, and the planner saves it with `datalad save`. Only
then does the planner ask the doer for the conversion command. The heuristic becomes a declared
input of the run, so a rerun uses the committed file. `code/` follows YODA: it is the dataset's
own code, in git.

*Alternative: keep heuristics under `.heudiconv/` or in the toolbox.* Rejected: the heuristic is
the study's decision about naming, and it must be versioned with the data it named.

**D5. The conversion command is constructed, never run, and never uses `--datalad`.** The doer
returns a command using `--files`, `-b`, `-c dcm2niix`, `-o .` and an explicit empty locator
(`-l ''`), so output lands at the dataset root rather than under a Study Description path. It
also returns the inputs (the DICOM source and the heuristic file when custom), the outputs (the
subject directories, `.heudiconv/<subject>`, `sourcedata/sub-<subject>` for ReproIn's DICOM
tarballs, and the top-level BIDS files HeuDiConv updates) and `run_via: planner`. `--datalad`
would create nested datasets and commits inside the planner's run. If a `-d` template is used,
its braces are doubled, because `datalad run` formats the command string.

*Alternative: let HeuDiConv's own `--datalad` mode record the conversion.* Rejected: it records
the result but not the command, inputs and heuristic in a replayable run record. It also conflicts
with the dataset the planner already owns.

**D6. Two bindings.** The result carries `binding: [heudiconv/heudiconv@<version>,
heudiconv/dcm2niix@<version>]`, read from `heudiconv --version` and `dcm2niix -v`. The planner
copies both into `DSH-Binding` lines. The heuristic is identified by the command (a built-in
name) or by the committed input file.

**D7. `.heudiconv/` is annexed.** It holds `dicominfo` with patient identifiers and a copy of the
heuristic. The toolbox's convert skill has the planner add a `.gitattributes` rule
(`.heudiconv/** annex.largefiles=anything`) and save it before the first conversion, so these
files follow the dataset's content policy instead of sitting in git blobs on every sibling.

*Alternative: leave `.heudiconv/` untracked.* Rejected: `datalad run` saves the whole tree without
`--explicit`, and the rules forbid `--explicit` as a workaround.

**D8. Routing in `raw-to-bids` is by layout.** `config.json` and `manifest.tsv` present →
nipoppy doer, unchanged. Otherwise → heudiconv doer. The planner states the route in its
report. A user who wants HeuDiConv on a nipoppy dataset configures it as nipoppy's `bidsify`
converter; the planner does not bypass nipoppy's layout.

## Risks / Trade-offs

- [The heudiconv doer is not read-only (scratch first pass, heuristic scaffold)] → It runs on the
  session default model, per `PINNABLE_AGENTS`, and writes nothing into the dataset except the
  scaffold, which the planner saves.
- [HeuDiConv updates existing top-level files (`participants.tsv`, `dataset_description.json`)
  that `new-project` created] → Those files are declared outputs. The e2e checks that a
  pre-existing `dataset_description.json` survives. `--overwrite` is never set by default.
- [ReproIn detection passes on names that are ReproIn-shaped but wrong] → The series table with
  target names is shown before the run (D3). The bids doer's validation is the next suggested
  step.
- [The first pass on a large session is slow] → It reads headers only; the doer scopes it to the
  requested subject and session.
- [Upstream flag behavior differs across versions] → The e2e runs against the version in
  `tool_env heudiconv` and records it.

## Migration Plan

Additive. The nipoppy route is unchanged in behavior. Rollback means removing the two plugins
and reverting `raw-to-bids`, its `delegates_to` and the counts. Datasets converted in the meantime
remain ordinary BIDS with ordinary run records.

## Open Questions

- For near-ReproIn names (one misnamed series), should the doer offer ReproIn's `protocols2fix`
  renaming in a small custom heuristic instead of a full scaffold? Default: full scaffold.
- Should conversion run from a ReproNim container image through `datalad containers-run` rather
  than a host install? That would pin HeuDiConv and dcm2niix in one image hash. Default: host
  install, pinned by the bindings; revisit once the concurrent `repronim-containers` change
  lands.
- Does the scout tarball (`sourcedata/…_scout.dicom.tgz`) that ReproIn writes need its own
  `.gitattributes` rule? It is binary, so `text2git` already annexes it; confirm in the e2e.
