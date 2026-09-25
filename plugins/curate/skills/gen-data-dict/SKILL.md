---
name: gen-data-dict
description: >
  Generate a participants.json data dictionary for a tabular file — one entry per column, with
  Description, Units and Levels — from the data and the user, never from a guessed meaning. Trigger
  on "generate a data dictionary", "data dictionary", "describe these columns", "participants.json",
  "document the variables", "what do these columns mean". Do NOT trigger to merge tables
  (curate/merge-data) or for the full metadata pass including sidecars (curate/annotate).
plane: workflow
stamped: [M, A]
delegates_to: [annotate]
---

# Skill: gen-data-dict

Produce the data dictionary that makes a table's columns interpretable, with every description
sourced rather than inferred.

**Read this before anything else: the structure of a data dictionary is derivable from the data; the
meaning of a column is not.** You can read column names, detect types, and enumerate the distinct
values of a categorical — that gets you the skeleton and it is genuinely useful. What you cannot do
is decide that `sex` is coded `1 = male`, that `score` is a raw total rather than a scaled one, or
what instrument produced a column. Those come from the user or a codebook, and a plausible guess in
a data dictionary is worse than a blank, because downstream analysis will trust it.

> This is the narrow, always-available core of `curate/annotate`. Use `annotate` for the full
> metadata pass — `dataset_description.json`, BIDS sidecars, controlled terms. Use this when the job
> is the data dictionary itself. Controlled-term annotation is delegated to the **annotate** doer,
> which reports a term it could not look up as `unannotated` rather than recalling one.

## When to use
- A `.tsv` has columns with no `participants.json` entry, or a merged table has new columns.
- Do NOT use for the full metadata pass (`curate/annotate`), to merge sources
  (`curate/merge-data`), or to validate BIDS structure (`govern/qc-review`, or the bids-cli toolbox).

## Steps

1. **Read the table and build the skeleton from evidence.** Per column: name, inferred type, count
   of non-empty values, and for a low-cardinality column the distinct values.
   ```bash
   head -1 <table.tsv> | tr '\t' '\n' | nl
   awk -F'\t' 'NR>1 {print $<n>}' <table.tsv> | sort | uniq -c | sort -rn | head -20
   ```
   A column whose distinct values are `0` and `1` is binary; that is a fact. What the `1` *means* is
   not.

2. **Read any existing `participants.json` and keep what is there.** Never overwrite a description
   someone wrote. Report which columns already have entries and leave them alone unless asked.

3. **Present the skeleton and ask for the meanings.** For each undescribed column, ask for the
   `Description`, the `Units` where it is a measurement, and the `Levels` mapping for a categorical —
   showing the distinct values you actually found, so the user maps real codes rather than remembered
   ones.

4. **Ask for a codebook rather than guessing.** If the user has one, read it. A supplied codebook is
   the difference between a dictionary that is documentation and one that is a hypothesis.

5. **Write only the entries you can source.** A column whose meaning nobody supplied gets **no
   entry**, and appears in the report as undescribed. Do not write `"Description": "sex"` for a
   column called `sex` — restating the column name adds nothing and makes the gap invisible.

6. **Controlled terms, optionally, via the annotate doer** — when the user wants standard
   vocabularies on top of the descriptions:
   > "check Neurobagel annotation coverage for `<table>` and report which columns carry a term, which
   > do not, and which backends are unavailable."

   An unavailable backend is not zero matches. Keep the free-text `Description` and report the gap.

7. **Validate the JSON, then save and record in one step:**
   ```bash
   python3 -c "import json,sys;json.load(open('participants.json'));print('valid JSON')"
   datalad save -m "$(printf 'gen-data-dict: describe <n> columns in <table>\n\nDSH-Op: gen-data-dict\nDSH-Stage: curate')" participants.json
   ```

8. **Report** the columns described, the columns **left undescribed and why**, and any `Levels`
   mapping the user supplied that does not cover every value found in the data — a code present in
   the column but absent from the mapping is a data-quality finding.

## Constraints

- **Never invent a column's meaning, units, or level coding.** Not from the column name, not from
  what a variable like this usually means, not from the values' distribution. `1 = male` and
  `1 = female` are both common and a guess is a coin flip written into documentation.
- **Never describe a column by restating its name.** It adds no information and hides the gap, which
  is worse than leaving the entry out.
- **Never overwrite an existing description.** Someone wrote it, possibly from a codebook you do not
  have.
- **Never assume a unit.** Age in years and age in months both appear in phenotypic exports; a
  wrong unit silently rescales an analysis.
- **Never emit a controlled-term identifier the annotate doer did not return.** This skill inherits
  that refusal: a code that was not looked up does not go in the file, and the free-text description
  stays instead.
- **Never report a dictionary as complete when columns are undescribed.** The undescribed list is a
  required part of the report.
- **Never silently drop a level found in the data.** If the user's mapping misses a value that
  occurs, report it rather than omitting it from `Levels`.
- Do not edit the table itself — this describes columns, it does not change them.
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`.
