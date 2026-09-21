## Context

Four `analyze` planners have been documented and unbuilt since the retrofit, and
`docs/end-to-end-workflow.md` marks the space between them as the harness's largest scaffolding gap.
This change builds all four. They are planner skills over the `datalad` doer, which exists, so the
work is operating procedure and — mostly — refusals.

What makes `analyze` different from the plugins built before it: these skills stand next to the data
and are asked questions whose wrong answers are not obviously wrong. A recalled p-value, a stub that
returns a constant, an illustrative figure and a filled-in table cell all look exactly like the real
thing. Elsewhere in the harness a fabrication produces a claim someone can check against a document;
here it produces a number, and numbers are quoted downstream without being rechecked.

## Goals / Non-Goals

**Goals:**
- Nothing in `analyze` is marked *(planned)* any more except `literature-search`.
- The scaffolding gap between "choose a test" and "report results" is closed by skills, not by prose
  admitting it is open.
- No number reaches the user that was not read from a file that a recorded run produced.
- The researcher's half of the work is named explicitly, with 🔧, in the two skills that abut it.

**Non-Goals:**
- **Checking statistical assumptions.** `plan-analysis` lists what its recommendation requires and
  marks the list 🔧. Testing normality, inspecting residuals or judging whether a design is adequate
  are analyses in their own right and run through `propose-comparison` / `run-comparison` like any
  other. `docs/end-to-end-workflow.md:125` stays open for this reason.
- **Writing analysis logic.** Not as a default, not "to get started". `scaffold-analysis` raises.
- **Interpreting results.** `gen-report` reports what was produced and what is missing; whether a
  finding is real, robust or publishable is the researcher's.
- **A plotting library or a project theme.** `plot` writes a figure script in whatever the project
  already uses, and proposes one place to keep styling if there is none. No dependency is added.
- **Power analysis and multiple-comparison correction as automated steps.** Both are named as
  situations the user must resolve, because both are choices with defensible alternatives.
- **Statistical correctness review.** Nothing here checks that the recommended test is the best one;
  that is what `plan-analysis` shows its work for.

## Decisions

- **`plan-analysis` records a recommendation, not a commitment.** A plan that is frozen is a
  pre-registration, and `govern/preregister` owns that. The skill logs its recommendation and routes
  to `preregister` for confirmatory work rather than growing a second freezing path.
- **`scaffold-analysis` fails loudly by construction.** The placeholder is
  `raise NotImplementedError` / `stop()` / `exit 1`, and the result-writing code sits *after* it — so
  the stub states the output shape without ever being able to produce one. A stub that ran to
  completion would write a file that looks like a result, and that file would be plotted and
  reported. This is the same reasoning as `archive`'s `unminted` and `annotate`'s `unannotated`: the
  failure must be visible at the point it happens.
- **`plot` does not execute anything itself.** It writes a figure script and routes to
  `analyze/run-comparison`, so a figure gets the same provenance as an analysis rather than a
  parallel, weaker path. This is also why it declares only `[datalad]`: the containers doer is
  reached through `run-comparison`, not from here.
- **`gen-report` has a mandatory gaps section.** The report's most useful content is what is absent —
  assumptions never checked, runs that failed, outputs produced by hand. A report that lists only
  what exists reads as a pass, which is the same failure `stamped-assess` avoids with `unassessed`.
- **`gen-report` is the internal report, not the manuscript.** `disseminate/draft-manuscript` writes
  the paper. The difference is audience and obligation: a report may say "unclear" and "not run".
- **Every output path is dataset-relative and lands under `derivatives/cmp-<slug>/`.** The contract
  is stated once, in `scaffold-analysis`, and the other three read it rather than re-deciding it.
