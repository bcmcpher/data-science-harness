---
name: bagel-cli
description: >
  Auto-invoke when the user wants to prepare a phenotypic table for Neurobagel, validate a data
  dictionary's controlled-term annotations, convert an annotated dataset into a Neurobagel graph
  file, or check whether Neurobagel tooling is usable. Trigger on "annotate for Neurobagel",
  "neurobagel", "bagel pheno", "build a Neurobagel graph", "validate my data dictionary",
  "check annotation coverage", or /bagel-cli. Do NOT trigger for writing plain BIDS sidecars with no
  controlled terms, for BIDS validation (use bids-validator), or for pushing a graph to a Neurobagel
  node — that is a deployment step, not this skill.
argument-hint: '[check|coverage|pheno|bids|derivatives] [--pheno <tsv>] [--dictionary <json>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: bagel-cli

Turn an annotated phenotypic table into a Neurobagel-queryable graph file, and report honestly which
columns carry controlled terms and which do not.

**Read this before anything else: `bagel-cli` is a validator and converter, not a lookup service.**
It checks that a data dictionary's `Annotations` blocks use terms from Neurobagel's vocabularies and
converts an annotated dataset into JSONLD. It will not tell you which term a column *should* carry.
Term selection happens in Neurobagel's annotation tool (`annotate.neurobagel.org`) or with the user,
and the terms themselves come from Neurobagel's own vocabulary plus SNOMED CT for diagnoses and
assessments. Any workflow that assumes this command produces codes out of a bare `participants.tsv`
is wrong, and will produce codes that only look right.

## Steps

1. **Check availability** — run the toolbox's offline presence check:
   ```bash
   plugins/annotate-cli/scripts/check-backends.sh bagel
   ```
   Exit 1 prints `result: unavailable` and the missing item. Stop there and report it with the
   `enable:` hint. Do not fall back to hand-writing the JSONLD a converter would have produced.

2. **Confirm the command surface before using it** — the subcommands and flags below are the
   expected shape, not a promise about the installed version. Check it, and record the version for
   the doer's report:
   ```bash
   bagel --version
   bagel --help
   bagel pheno --help
   ```
   If a flag named here is absent, follow `--help` and say in your report that the invocation
   differed from this skill's, so the skill gets corrected rather than worked around.

3. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): step 1 only.
   - **coverage**: steps 4-5 — report annotation state, write nothing.
   - **pheno**: steps 4-6 — the phenotypic table into a graph file.
   - **bids**: step 7 — tabulate the BIDS tree, then merge imaging availability into an existing
     graph file.
   - **derivatives**: step 8 — merge processing status into an existing graph file.

4. **Locate and read the inputs** — a phenotypic TSV, its data dictionary, and a dataset
   description, conventionally `participants.tsv`, `participants.json` and
   `dataset_description.json` at the dataset root. `bagel pheno` requires all three; a BIDS
   `dataset_description.json` can be reused as-is:
   ```bash
   ls participants.tsv participants.json dataset_description.json
   head -2 participants.tsv
   ```
   Every column in the TSV should have a key in the dictionary. Columns present in one and not the
   other are the first thing to report — a dictionary that describes columns the table does not have
   is as much a defect as a column with no description.

5. **Report annotation coverage per column** — for each dictionary key, which of three states it is
   in. This is the step that makes the result honest, so do it before any conversion:
   ```bash
   python3 - <<'PY'
   import json
   d = json.load(open("participants.json"))
   for col, spec in d.items():
       if not isinstance(spec, dict):
           print(f"{col}: malformed entry"); continue
       ann = spec.get("Annotations")
       if ann:
           print(f"{col}: annotated -> {ann.get('IsAbout', {}).get('TermURL', 'no IsAbout.TermURL')}")
       elif spec.get("Description"):
           print(f"{col}: free text only")
       else:
           print(f"{col}: undescribed")
   PY
   ```
   A column in `free text only` is **unannotated**, and that is a legitimate end state — say why
   (no candidate term, or the user has not confirmed one). Never fill an `Annotations` block from
   memory to make this output look better.

6. **Convert the phenotypic table** — only once the dictionary carries the annotations you intend to
   ship. The dataset label that appears in query results comes from the `Name` field of the
   `--dataset-description` file; there is no `--name` flag. `--output` is a single `.jsonld` file:
   ```bash
   bagel pheno \
     --pheno participants.tsv \
     --dictionary participants.json \
     --dataset-description dataset_description.json \
     --output pheno.jsonld
   ```
   `bagel` validates the annotations here and fails on a term it does not recognize, or on a
   dictionary with no Neurobagel annotations at all. **That failure is the tool working.** Report
   it; do not edit the term until it passes.

   `bagel pheno` needs network access: it fetches its vocabulary configurations at start-up. Offline
   it fails before reading any input, with `BadParameter: 'Neurobagel' is not one of .` — report
   that as "network unavailable", not as an annotation failure. An existing output file makes it
   exit 1 unless you pass `--overwrite`; do not add `--overwrite` without saying you replaced a
   file.

7. **Merge imaging availability** — adds which sessions/modalities exist in the BIDS tree to the
   graph file `bagel pheno` produced. `bagel bids` does not read a BIDS directory; it reads a table
   of image files, which `bagel bids2tsv` builds first:
   ```bash
   bagel bids2tsv --bids-dir <bids dir> --output bids.tsv
   bagel bids --jsonld-path pheno.jsonld --bids-table bids.tsv --output bids.jsonld
   ```
   `bids2tsv` validates the BIDS layout and fails if `dataset_description.json` lacks
   `BIDSVersion`. Subject and session IDs in the table must match the phenotypic table's: pass
   `--strip-id-prefixes` to `bids2tsv` when `participants.tsv` holds `01` rather than `sub-01`.

8. **Merge processing status** — adds derivative/pipeline completeness from a Nipoppy-style
   processing-status table:
   ```bash
   bagel derivatives --tabular <processing_status.tsv> --jsonld-path pheno.jsonld --output derivatives.jsonld
   ```

9. **Report** — the version you ran, the exact invocation, the files written (uncommitted), and the
   per-column coverage from step 5 split into annotated / unannotated / undescribed. Hand the save
   back to the caller.

## Constraints
- **Never write an `Annotations` block whose `TermURL` you did not get from the annotation tool, the
  installed vocabulary, or the user in this session.** A recalled SNOMED code is the exact failure
  this toolbox exists to prevent, and it is invisible in the output — it looks like a real code.
- Never hand-write the JSONLD that `bagel pheno` would emit. If the tool is unavailable, the answer
  is that the graph file was not produced.
- Do not commit. Write the outputs and let the calling planner save them with `datalad save`.
- Do not edit `participants.tsv` — no renamed columns, no recoded values. This skill describes the
  table; changing it is a curation step with its own provenance.
- Do not push a graph to a Neurobagel node. Producing the file is in scope; standing up or feeding a
  node is not.
- Report a validation failure as a failure. A graph file that exists because a term was quietly
  changed to one that passes is worse than no graph file.
