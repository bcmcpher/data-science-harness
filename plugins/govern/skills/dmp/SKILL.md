---
name: dmp
description: >
  Author or update a Data Management Plan against a funder template or the RDA DMP Common Standard,
  and record the commitments it makes as ledger obligations so they are tracked rather than filed
  and forgotten. Trigger on "data management plan", "DMP", "maDMP", "funder data plan", "update our
  DMP", "what did we promise in the data plan", "RDA DMP". Do NOT trigger for ethics or IRB records
  (govern/ethics-track) or to score a dataset against STAMPED (govern/stamped-assess).
plane: workflow
stamped: [M, T]
delegates_to: [datalad]
---

# Skill: dmp

Turn a Data Management Plan from a document that was submitted once into a set of **tracked
commitments**, so what the project promised is visible next to what it is doing.

**Read this before anything else: never state a funder's requirement from memory.** Funder DMP
requirements differ between agencies, change between calls, and are the thing a recalled answer gets
confidently wrong. Work from a template or a policy text the user supplies, or from what the user
tells you their funder requires. If neither is available, write the plan around what the project
actually does and mark every funder-specific section as needing the user's input — an unfilled section
is a visible gap; an invented one is not.

## When to use
- A DMP must be written for a proposal, or an existing one updated because the project changed.
- The user wants to know what the DMP committed them to, or to record those commitments as
  obligations.
- Do NOT use to record IRB/IACUC approvals (`govern/ethics-track`), to assess the dataset against
  STAMPED (`govern/stamped-assess`), or to de-identify anything (`curate/deidentify`).

## Steps

1. **Establish the template.** Ask which funder and which call, and ask for the template or the
   policy text. If the user offers neither, say plainly that you will write a structure based on the
   RDA DMP Common Standard's topic areas and that every funder-specific requirement will be marked
   for them to fill.

2. **Describe what the project actually does**, reading the dataset and the ledger rather than
   asking the user to restate it: what data exists, in what formats, roughly how much, where it
   lives, how it is version-controlled and backed up, and what the container recipe pins. This is
   the part the harness can answer from evidence, and it is usually the bulk of a DMP.

3. **Mark what you cannot answer from the project.** Funder-specific retention periods, repository
   mandates, cost lines, embargo rules, and anything about consent scope or data-use agreements.
   Each gets a visible placeholder naming what is needed and who would know.

4. **Write the plan** to a path the user chooses (commonly `docs/dmp.md`). It is a dataset file, so
   it is provenanced like any other.

5. **Extract the commitments into obligations.** Every sentence in a DMP that says the project *will*
   do something is a commitment. Append one `obligations[]` entry per commitment with
   `kind: dmp`, a `description` quoting or closely paraphrasing the promise, a `due` date where the
   plan states one, and `ref` pointing at the plan section or the funder's award. This is the step
   that makes the DMP operative rather than archival.

6. **Log it** — `{ ts, op: dmp, stage: govern, note: "...", branch }` naming what was written or
   updated and how many obligations were recorded.

7. **Validate and save.**
   ```bash
   python3 schemas/validate-ledger.py project.yaml
   ```
   Then delegate: "save: `datalad save -m 'dmp: <action>'`."

8. **Report** the plan path, the obligations created with their ids and due dates, and — separately
   and explicitly — **the list of sections the user still has to fill.** That list is the useful
   output; a DMP that looks finished and is not is the failure mode here.

## Constraints

- **Never assert a funder's requirement, deadline, retention period or repository mandate that was
  not read from a supplied template or stated by the user.** A recalled funder policy is plausible,
  specific, and wrong often enough to matter — and a DMP is a document someone signs.
- **Never fill a section you cannot source.** Mark it. An unfilled section is a visible gap the user
  closes; an invented one is submitted.
- **Never claim the plan satisfies a funder's requirements**, and never describe a DMP as approved,
  compliant or accepted. It is a document the project wrote.
- **Never record an obligation the plan does not state.** Each `kind: dmp` obligation quotes or
  closely paraphrases an actual commitment; do not add the ones a plan like this usually has.
- **Never invent a consent scope, a data-use restriction, or a participant agreement term.** The
  ledger schema does not model consent scope at all today, and writing a guess into prose is worse
  than the schema's silence.
- Do not resolve a `kind: dmp` obligation here. `govern/obligations` resolves it, and the schema
  requires `resolved_by` naming the action that met it.
- Keep `log:` append-only and the ledger schema-valid; delegate the save to the datalad doer.
