---
name: annotate
description: >
  Enrich a dataset's metadata so it is self-describing and machine-queryable — complete
  dataset_description.json, generate a participants.json data dictionary, fill BIDS sidecars,
  and (optionally) annotate phenotypic variables / assessments with controlled terms
  (Neurobagel/SNOMED, ReproSchema, NIDM). Trigger on "annotate", "add metadata", "describe the
  dataset", "data dictionary", "annotate variables", "standardize variable names", "add sidecars",
  "make this dataset self-describing". This advances the Metadata (M) and Actionable (A) of STAMPED.
plane: workflow
stamped: [M, A]
delegates_to: [annotate, datalad]
---

# Skill: annotate

Make the dataset **Metadata-rich (M)** and **Actionable (A)**: fill in the descriptive and
controlled-vocabulary metadata that lets a human — or an agent — understand and query the data
without opening the raw files. Every metadata edit is a file in the dataset, so you keep it
**provenanced** by delegating the save to the **datalad doer**; you never annotate off to the side.

> Scope note: the always-available core is BIDS/dataset-level metadata — `dataset_description.json`,
> a `participants.json` data dictionary, and BIDS sidecars — which need no extra tools and are fully
> provenanced. Controlled-term annotation against external vocabularies is the richer add-on, and it
> belongs to the **annotate** doer: delegate it rather than constructing terms here. That doer owns
> Neurobagel (`bagel-cli`), NIDM (`pynidm`), ReproSchema and SNOMED CT, and checks each backend
> independently — an uninstalled tool or an unconfigured terminology source comes back unavailable.
> An unavailable backend is not zero matches — report the gap and keep the free-text description,
> never a fabricated code.

## When to use
- Data is in (or near) BIDS form and needs describing: missing/thin `dataset_description.json`,
  `participants.tsv` columns with no data dictionary, imaging files without sidecar metadata, or
  phenotypic variables that should carry standard terms.
- Do NOT use to convert raw data to BIDS (that is a `curate` conversion step / nipoppy `bidsify`)
  or to run a pipeline (`process/run-pipeline`). Annotate describes; it does not compute.

## Steps
1. **Survey current metadata (datalad doer for state)** — inspect what exists: is
   `dataset_description.json` present and complete (Name, BIDSVersion, Authors, License,
   DatasetType)? Does every non-id column in `participants.tsv` have an entry in
   `participants.json`? Which imaging files lack sidecars? Report the gaps before editing.
2. **Dataset-level metadata** — complete `dataset_description.json` (authorship, license, funding,
   references) and any BIDS top-level files (`README`, `CHANGES`). Ask the user for anything you
   cannot derive (authors, license) — do not invent authorship.
3. **Data dictionary** — for each `participants.tsv` column (and other phenotypic `.tsv`s), add a
   `participants.json` entry with `Description`, `Units`, and `Levels` for categoricals. This is
   the highest-value, always-available annotation (M) and makes the columns queryable (A).
4. **BIDS sidecars** — fill/extend JSON sidecars for imaging data as needed (task, acquisition,
   units). Keep edits BIDS-valid; suggest running `bids-validator` after.
5. **Controlled-term annotation (optional, richer M/A)** — when the user wants standardized
   vocabularies, delegate to the **annotate** doer rather than running the tools yourself:
   > "check Neurobagel annotation coverage for `participants.tsv` and report which columns carry a
   > term, which do not, and which backends are unavailable."

   It covers phenotypic variables via Neurobagel (`bagel-cli`), behavioral assessments via
   ReproSchema, imaging provenance via NIDM (`pynidm`), and clinical codes via a SNOMED source the
   user configures — reporting any backend it could not reach as unavailable rather than as an empty
   result. Note that only SNOMED lookup and an interactive `pynidm` session actually *find* new
   terms; the rest validate terms you already have, so expect to supply or confirm them.
   It returns candidates with their source and never selects a term — **you** put each one to
   the user for confirmation, because which term is correct is a research judgment. Pass the
   confirmed term back for it to write. It writes the metadata files and leaves them uncommitted,
   which is what step 6 then saves.
6. **Provenance the edits (datalad doer)** — delegate the save so the annotation is tracked:
   > "save: `datalad save -m 'annotate: <what was added, e.g. participants.json data dictionary +
   > dataset_description authors>'`."
7. **Log it** — append to `project.yaml`:
   `{ ts, op: annotate, stage: curate, note: "<metadata added>", branch: <branch> }`.
8. **Report** — what was annotated and what controlled-term coverage the annotate doer returned,
   keeping its three states distinct: annotated (with the source of each term), unannotated (with
   the reason), and backends that were unavailable. Suggest `bids-validator` and (when ready)
   pushing a Neurobagel graph.

## Constraints
- Delegate the save to the datalad doer so metadata is provenanced — never leave annotation edits
  uncommitted, and never call `datalad` directly.
- Never fabricate controlled-vocabulary codes (SNOMED/Neurobagel/NIDM/ReproSchema) or authorship —
  delegate the lookup to the annotate doer or ask; cite the source of every term. Never call
  `bagel-cli`, `pynidm` or `reproschema` directly.
- Keep edits BIDS-valid; a data dictionary or sidecar that breaks the schema is worse than none.
  Recommend `bids-validator` rather than asserting validity.
- Do not restructure or rename data files here — annotation describes existing data; renaming is a
  curation/conversion concern.
- Keep `project.yaml` append-only.
