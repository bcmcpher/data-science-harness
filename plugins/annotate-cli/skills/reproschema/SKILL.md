---
name: reproschema
description: >
  Auto-invoke when the user wants a behavioral assessment, questionnaire, or protocol represented as
  a machine-readable ReproSchema, validated, or converted to/from a REDCap data dictionary. Trigger
  on "reproschema", "repronim schema", "questionnaire schema", "assessment schema", "validate my
  protocol", "redcap data dictionary", "redcap2reproschema", "reproschema2redcap", or /reproschema.
  Do NOT trigger for annotating the columns of a phenotypic table (use bagel-cli for Neurobagel or
  snomed-lookup for clinical codes), for NIDM (use pynidm), or for scoring an instrument's responses
  — this skill describes instruments, it does not compute from them.
argument-hint: '[check|validate|convert|from-redcap|to-redcap] [--path <schema dir or file>] [--redcap <csv>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: reproschema

Describe the *instrument* rather than the table. ReproSchema represents a protocol as JSON-LD —
protocol → activity → item, with each item's question text and response options spelled out — so an
assessment a dataset used is reusable and citable instead of being a column name and a guess.

**Read this before anything else: `reproschema` is a validator and converter, not a lookup service
and not a phenotypic-table annotator.** It checks that a schema you already have conforms, and it
moves between ReproSchema JSON-LD and a REDCap data dictionary. It will not tell you which published
questionnaire a column came from, and it holds no term vocabulary. Existing schemas for common
instruments live in the ReproNim ReproSchema library, which is a repository you fetch — not
something this command searches.

This is also the skill whose failure mode is least visible. A hand-written schema claiming to be the
standard form of a named questionnaire, with item wording and response codes recalled rather than
copied, will validate cleanly: structural validity says nothing about whether the instrument is the
real one. So the rule is that a schema's *content* comes from the library, from the user, or from a
REDCap dictionary the user supplied — never from recall.

## Steps

1. **Check availability** — the toolbox's offline presence check, then the console script, since a
   package installed into an environment that is not on `PATH` passes the first and fails the second:
   ```bash
   plugins/annotate-cli/scripts/check-backends.sh reproschema
   command -v reproschema
   ```
   Exit 1 prints `result: unavailable` and the missing item. Stop there and report it with the
   `enable:` hint. Do not hand-write the JSON-LD a converter would have produced.

2. **Confirm the command surface before using it** — the subcommands below are the expected shape,
   not a promise about the installed version. Record the version for the report:
   ```bash
   reproschema --version
   reproschema --help
   ```
   If a subcommand named here is absent, follow `--help` and say in your report that the invocation
   differed from this skill's, so the skill gets corrected rather than worked around.

3. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): steps 1-2 only.
   - **validate**: step 4 — conformance of a schema that already exists.
   - **convert**: step 5 — a schema into another serialization.
   - **from-redcap**: step 6 — a REDCap data dictionary into a ReproSchema protocol.
   - **to-redcap**: step 7 — a ReproSchema protocol into a REDCap data dictionary.

4. **Validate a schema** — run this first on anything you did not just generate, and again on
   anything you did:
   ```bash
   reproschema validate <path to schema dir or file>
   ```
   A validation failure is the tool working. Report the error text and fix the schema's structure —
   never change an item's wording or response codes to make validation pass, because those are the
   instrument's content, not its structure.

5. **Convert a schema** — between serializations, for a consumer that wants RDF rather than JSON-LD:
   ```bash
   reproschema convert --help
   reproschema convert <path> --format <format from --help>
   ```
   Take the format names from `--help`; do not guess one.

6. **Convert a REDCap data dictionary into a protocol** — the realistic path into ReproSchema for a
   study that already collected data, because the REDCap dictionary is a record of the instrument as
   it was actually administered:
   ```bash
   reproschema redcap2reproschema --help
   reproschema redcap2reproschema <redcap_data_dictionary.csv> <protocol config>
   ```
   Check `--help` for whether the installed version wants a YAML config alongside the CSV. Then
   validate the result with step 4 before reporting it.

7. **Convert a protocol into a REDCap data dictionary** — the reverse, for deploying an existing
   instrument into a REDCap project:
   ```bash
   reproschema reproschema2redcap --help
   reproschema reproschema2redcap <input> <output csv>
   ```

8. **Relate the schema to the dataset's columns, without editing either.** This is the step that
   makes the work useful to `curate/annotate`: say which `participants.tsv` columns correspond to
   which items, and which columns no item covers. Report that mapping — do not write it into
   `participants.json`, and do not rename a column to match an item identifier.

9. **Report** — the version you ran, the exact invocation, the files written (uncommitted), whether
   validation passed, and the column-to-item correspondence from step 8 with the uncovered columns
   named. Where a schema's content came from — library, user, or REDCap dictionary — say so
   explicitly. Hand the save back to the caller.

## Constraints
- **Never author an item's question text, response options, or response codes from memory**, and
  never present a hand-written schema as the standard form of a named instrument. Content comes from
  the ReproSchema library, the user, or a REDCap dictionary they supplied. A recalled questionnaire
  validates perfectly and is still wrong.
- Never hand-write the JSON-LD a converter would emit. If the tool is unavailable, the answer is
  that the schema was not produced.
- Structural validity is not content validity. Saying a schema validated is a claim about its shape
  only, and the report must not let it read as a claim that the instrument is correctly represented.
- Do not write into `participants.json` or any BIDS sidecar. This skill produces schema files; the
  data dictionary belongs to `bagel-cli` and the doer.
- Do not edit `participants.tsv` — no renamed columns, no recoded values.
- Do not commit. Write the outputs and let the calling planner save them with `datalad save`.
- Do not fetch the ReproSchema library without telling the user you are doing it and from where.
