---
name: pynidm
description: >
  Auto-invoke when the user wants NIDM (Neuroimaging Data Model) representation of a dataset —
  convert a BIDS tree or a phenotypic table into NIDM, reuse an existing NIDM term mapping, or query
  an existing NIDM document. Trigger on "nidm", "pynidm", "csv2nidm", "bidsmri2nidm", "NIDM terms",
  "InterLex", "NIDM-Terms", "query my NIDM file", "convert BIDS to NIDM", or /pynidm. Do NOT trigger
  for Neurobagel annotation (use bagel-cli), for assessment/questionnaire schemas (use reproschema),
  for SNOMED codes (use snomed-lookup), or for BIDS validation (use bids-validator).
argument-hint: '[check|convert|annotate|query] [--csv <tsv>] [--json-map <json>] [--bids <dir>] [--nidm <ttl>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: pynidm

Produce and query NIDM documents — an RDF representation of a neuroimaging experiment, its
phenotypic variables, and their provenance — so variables carry resolvable term identifiers rather
than only column names.

**Read this before anything else: this is the one backend in `annotate-cli` that can actually
*resolve a new term*, and it can only do so interactively.** `csv2nidm`'s annotation mode searches
NIDM-Terms and InterLex and prompts a human to choose among the hits; that prompt reads from stdin.
`bagel-cli` validates terms you already have and `reproschema` validates schemas you already have,
but neither looks anything up. So the division of labour is:

| Mode | Needs | Runs unattended |
|---|---|---|
| Convert with an existing `-json_map` | `pynidm` installed | yes |
| Query an existing NIDM document | `pynidm` installed | yes |
| Resolve new terms interactively | an InterLex/SciCrunch API key **and a human at the prompt** | **no** |

If the request needs new terms resolved, you hand the user the command to run — you do not answer
from your own knowledge of what an ILX or NIDM-Terms identifier looks like. The failure this guards
against is specific: these identifiers are short, structured, and completely unverifiable by eye.

## Steps

1. **Check availability** — the toolbox's offline presence check, then the command you actually
   need. The check tests that the `nidm` package imports; the console scripts are a separate
   question, because a package installed into an environment that is not on `PATH` will pass the
   first and fail the second:
   ```bash
   plugins/annotate-cli/scripts/check-backends.sh pynidm
   command -v pynidm csv2nidm bidsmri2nidm
   ```
   Exit 1 from the check prints `result: unavailable` and the missing item. Stop there and report it
   with the `enable:` hint. Do not hand-write turtle that a converter would have produced.

2. **Confirm the command surface before using it** — the flags below are the expected shape, not a
   promise about the installed version. PyNIDM's converters use single-dash long options, which is
   unusual enough to be worth checking rather than assuming. Record the version for the report:
   ```bash
   pynidm --version
   pynidm --help
   csv2nidm --help
   bidsmri2nidm --help
   ```
   If a flag named here is absent, follow `--help` and say in your report that the invocation
   differed from this skill's, so the skill gets corrected rather than worked around.

3. **Determine the operation** — from `$ARGUMENTS` or context:
   - **check** (default): steps 1-2 only.
   - **convert**: steps 4-5 — a phenotypic table or a BIDS tree into a NIDM document.
   - **annotate**: step 6 — resolve terms for columns that have none. Interactive; hands off.
   - **query**: step 7 — read an existing NIDM document.

4. **Convert a phenotypic table** — with an existing term mapping. `-json_map` is what makes this
   unattended: it supplies the column-to-term mapping so nothing has to be looked up:
   ```bash
   csv2nidm -csv participants.tsv -json_map <mapping.json> -out <out.ttl>
   ```
   Without `-json_map` the command drops into the interactive annotation of step 6. **Never run it
   that way from here** — a tool waiting on stdin in a non-interactive shell hangs until it is
   killed, and a killed converter leaves a partial document. If no mapping exists, go to step 6.

5. **Convert a BIDS tree** — the imaging half: acquisitions, sessions, and participants as NIDM
   provenance:
   ```bash
   bidsmri2nidm -d <bids dir> -o <out.ttl>
   ```
   Check `--help` for whether the installed version wants `-jsonld`, a `-json_map`, or a
   `-bidsignore` flag for your tree, and report the exact invocation you ran.

6. **Resolve new terms — hand this to the user.** Interactive annotation needs both an InterLex
   API key (`INTERLEX_API_KEY`, or the `-ilxkey` flag) and a person to choose among the search hits.
   Confirm the key is *present* without printing it, then stop and return the command:
   ```bash
   [ -n "${INTERLEX_API_KEY:-}" ] && echo "INTERLEX_API_KEY is set" || echo "INTERLEX_API_KEY is not set"
   ```
   Report the columns that need a term, whether the key is set, and the command for the user to run
   in their own terminal. Then ask them for the resulting mapping file, and resume at step 4 with it
   as `-json_map`. A term that arrives this way came from the user and from a queried source, which
   is the only way a term is allowed into a report.

7. **Query an existing NIDM document** — read-only, and the honest way to report what a NIDM file
   already says rather than guessing:
   ```bash
   pynidm query --help
   pynidm query -nl <nidm.ttl> -u <query or uri>
   ```
   Follow `--help` for this one especially: the query subcommand's options vary more across versions
   than the converters'. If you cannot construct a query the installed version accepts, say so
   rather than reporting an empty result — an empty result reads as "the dataset says nothing".

8. **Report** — the version you ran, the exact invocation, the files written (uncommitted), and
   per-column state split into: mapped (term identifier plus the mapping file it came from),
   unmapped (and why), and — if the key or the human was missing — the annotation step handed back
   rather than performed. Hand the save back to the caller.

## Constraints
- **Never write an ILX, NIDM-Terms, or other term URI you did not read out of a mapping file, a
  tool's output, or the user's message in this session.** These identifiers are opaque; a fabricated
  one is indistinguishable from a real one in the output and survives into the RDF.
- Never launch interactive annotation from a non-interactive shell. It blocks on stdin, and killing
  it can leave a half-written document that looks like a successful conversion.
- Keep NIDM and Neurobagel metadata separate. A NIDM mapping file and a BIDS-style `Annotations`
  block in `participants.json` are different schemas for different consumers — do not copy
  identifiers between them, and do not add NIDM keys to `participants.json`.
- Never hand-write the turtle or JSON-LD a converter would emit. If the tool is unavailable, the
  answer is that the NIDM document was not produced.
- Do not commit. Write the outputs and let the caller delegate the save to the datalad doer.
- Do not edit `participants.tsv` or the BIDS tree — no renamed columns, no recoded values. This
  skill describes existing data.
- Report a conversion or validation failure as a failure, with the tool's own error text.
