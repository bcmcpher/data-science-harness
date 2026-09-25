---
name: deidentify
description: >
  Remove identifying information from a dataset as a recorded, provenanced step — decide what must
  go per category, run each removal under `datalad run`, and record the approach, the inputs,
  what was deliberately kept, and the residual risk. Trigger on "de-identify", "deidentify",
  "anonymize", "remove PHI", "scrub identifiers", "deface", "date-shift", "strip participant
  identifiers", "prepare this for sharing". Do NOT trigger to audit for PHI exposure after the fact
  (that is a governance assessment) or to answer whether data may be shared — this skill records
  what was done, it does not clear a dataset for release.
plane: workflow
stamped: [M, T]
---

# Skill: deidentify

Make de-identification a **Tracked (T)** transformation with a **recorded (M)** rationale, instead
of an untracked fixup that happens before the record starts.

**Read this before anything else: this skill scaffolds the decision and the record. It does not
remove anything by itself, and it cannot tell you whether a dataset is safe to share.** The
researcher runs the tool; the harness makes sure the run is provenanced and the reasoning survives.
That division is deliberate — a defacing algorithm's output needs human inspection, and a skill that
quietly ran one would be claiming a judgment it cannot make.

> 🔧 **Do-it-yourself:** choosing and running the actual tools — defacing (pydeface, mri_deface,
> mideface), DICOM header scrubbing, PHI column detection, date-shifting — and **inspecting the
> output**. No de-identification tooling ships with this harness. These are capability-plane work
> and belong in a later change; what exists today is the record.

## When to use
- Before data moves anywhere: before conversion to BIDS if the raw inputs carry identifiers, before
  a pipeline runs on them, and certainly before any `disseminate/*` step.
- When an ethics or data-management commitment requires de-identification and you need the
  obligation resolved by something checkable rather than by assertion.
- When a category of identifier is being **deliberately kept** and that choice needs recording.
- Do NOT use to *audit* an already-shared dataset for exposure, and do NOT use it to decide whether
  sharing is permitted. Those are governance questions; this owns the action and its record.

## Steps

1. **Establish what identifiers are actually present, per category.** Do not work from a general
   idea of what a dataset like this usually contains. Inspect it:
   - direct identifiers in tabular data — names, MRNs, contact details, free-text notes;
   - indirect identifiers — dates of birth, scan dates, ages above 89, postal codes, rare
     diagnoses, site identifiers;
   - identifiers inside file and directory names, and inside `participants.tsv` id values;
   - DICOM/NIfTI header fields, which survive conversion unless something removes them;
   - **facial anatomy in structural imaging**, which is identifying and is not a metadata field.

   Report the inventory before proposing anything. Ask the user about anything ambiguous rather than
   assuming a column is or is not an identifier.

2. **Decide the approach per category, with the user.** Removal, replacement with a stable
   pseudonym, coarsening (year instead of date, age band instead of age), or deliberate retention.
   Each category gets an explicit decision — including the ones you are leaving alone.

3. **State the plan before running anything.** Name the categories, the approach chosen for each
   (including any deliberately kept), and the reason. This becomes the "why" in each run's commit
   message in step 4, so the intent is on the record even if a run is interrupted.

4. **Run each removal yourself**, one provenanced `datalad run` per transformation:
   ```bash
   datalad run -m "$(printf '<category> deidentify: <approach> — <why>\n\nDSH-Op: deidentify\nDSH-Stage: curate')" -i <inputs> -o <outputs> "<the user's de-identification command>"
   ```
   One run per category rather than one run for everything, so a later reader can see which
   transformation produced which change — and so a single step can be re-run without redoing the
   rest. Never edit files directly to strip an identifier. Note the resulting commit sha; step 6
   needs it.

5. **Verify the removal happened, and say how you verified it.** Re-inspect the affected fields.
   A command that exited 0 is not evidence that a header field is gone. If verification is not
   possible — as with defacing, where the check is visual — say that the check is the researcher's
   and has not been performed here.

6. **Write the de-identification record and save it, resolving the obligation if there is one.**
   Write `docs/deidentification/<YYYY-MM-DD>-<slug>.md` with the approach applied per category,
   the inputs it touched, the run commits from step 4, what was verified and how, what was
   deliberately kept and why, and the **residual-risk statement**. The record is required whether
   or not an obligation exists: it is where the residual risk lives. If an ethics or data-management
   commitment is recorded as an `obligations[]` entry with `kind: ethics`, move it to `status: met`
   **with `resolved_by` naming the run that met it** — the commit sha from step 4. The schema
   requires `resolved_by` when status is `met`, so an obligation cannot be closed here by assertion.
   Save both in one commit:
   ```bash
   datalad save -m "$(printf 'record de-identification of <scope> — <residual risk in one line>\n\nDSH-Op: deidentify\nDSH-Stage: curate\nDSH-Obligation: <id> resolved')" docs/deidentification/ project.yaml
   ```
   Omit the `DSH-Obligation` line and `project.yaml` when no obligation exists, and say so rather
   than creating one retroactively.

7. **Report.**
   ```
   op:            deidentify
   inventory:     <identifier categories found, per source>
   approach:      <category -> removal | pseudonym | coarsening | retained, with the reason>
   runs:          <one datalad run per transformation, with its recorded commit>
   verified:      <what was re-inspected and how; what was not verifiable here>
   retained:      <what was deliberately kept, and why>
   residual_risk: <what remains; never blank>
   obligation:    <id moved to met with resolved_by, or none recorded>
   ```

## Constraints

- **Never state that a dataset is de-identified unless a recorded action in this session produced
  that state.** With no recorded action, report the absence. "No identifiers were found" and
  "identifiers were removed" are different findings, and neither is "this dataset is de-identified".
- **`residual_risk` is required and must never be blank.** An empty residual risk is itself a claim —
  that nothing remains — and that is exactly the assertion this step exists to avoid making. If you
  believe the risk is low, say what makes it low and what would change that.
- **Never present the record as a compliance determination.** Do not write that a dataset is
  HIPAA-compliant, GDPR-compliant, Safe Harbor-compliant, anonymized, or cleared for sharing. Record
  the approach and the residual risk; the sharing decision belongs to the researcher, their ethics
  board, and their data-use agreements.
- **Never answer "can I share this?"** Report what was done and what remains, and name who decides.
- **Never run a de-identification tool you selected yourself**, and never invent a command line for
  one. The tools are the researcher's choice and their flags are consequential — a defacing tool
  invoked with the wrong mask can remove brain tissue, and a date-shift applied inconsistently
  across sessions destroys a longitudinal design while looking like it worked.
- **Never delete the original without the user saying so explicitly.** Removal is irreversible and
  git-annex will not bring back content that was dropped before it was committed. Prefer producing
  de-identified outputs alongside the inputs, and let the user decide what happens to the originals.
- **Never treat deliberate retention as an oversight, or an oversight as retention.** A kept scan
  date is legitimate when it is recorded as a choice, and indistinguishable from a mistake when it
  is not.
- Do not edit dataset files directly to strip an identifier — every removal is a `datalad run` you
  execute yourself, so it appears in the provenance chain like any other transformation.
- Record activity in the commit's `DSH-*` lines; never append to `project.yaml` `log`.
