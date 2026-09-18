---
name: age-vs-volume
description: >
  Run the study's age-versus-hippocampal-volume comparison over a participants table and return the
  model summary it produced. Trigger on "run the age vs volume analysis", "reproduce the hippocampal
  volume result", "call the study's age model", or /age-vs-volume. Do NOT trigger for a different
  outcome or predictor — this tool runs one comparison, the one the paper reports.
argument-hint: '--participants <participants.tsv> --out <dir>'
plane: capability
stamped: [A, E]
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash
---

# Skill: age-vs-volume

Call `code/cmp-age-vs-volume.py`, the script whose recorded run produced
`derivatives/cmp-age-vs-volume/`.

## When to use

- A caller wants the study's reported age-versus-volume result, recomputed from a participants table
  in the same shape as the one the paper used.
- Do NOT use to fit a different model, add a covariate, or run the comparison on data with a
  different schema. Those are new analyses and belong in the study, not in a wrapper around it.

## Steps

1. **Confirm the input has the columns the script declares** — `participant_id`, `age`,
   `hippocampal_volume`. A missing column stops here; the script would otherwise fail deeper, with a
   message about an index rather than about the data.
2. **Run the script with its own parameters**, unchanged.
   ```bash
   python3 code/cmp-age-vs-volume.py --participants <path> --out <dir>
   ```
3. **Report the output paths and the script's exit status**, and say that whether the numbers match
   the paper's is what `tests/reproduce.py` asserts, not what this call establishes.

## Constraints

- **Never modify the script or its parameters** to accommodate an input. The tool is a wrapper; a
  change to the analysis is a change to the study.
- **Never return a result when the script failed.** Report the failure.
- **Never present this output as the paper's result.** It is the same computation on the data it was
  given, which may not be the data the paper used.
