## Context

The harness's position on de-identification is currently split across three places that do not meet:
`govern/ethics-track` and `govern/dmp` create the obligation, `govern/stamped-assess` audits for PHI
exposure after the fact, and `docs/end-to-end-workflow.md` tells the researcher they are on their
own in between. Nothing records what was actually done.

## Goals / Non-Goals

**Goals:**
- The de-identification approach is a recorded decision, not a remembered one.
- Every removal is a `datalad run`, so it appears in the provenance chain like any other transform.
- An ethics obligation can be resolved by pointing at a recorded action.
- The skill states what it did *not* remove, because that is the part a reviewer needs.

**Non-Goals:**
- **Implementing de-identification tooling.** No defacing, no PHI classifier, no date-shifting
  implementation. Those are capability-plane work and belong in a later change.
- **Claiming compliance.** The skill records an approach and its residual risk. It does not assert
  that a dataset is safe to share, and it must not be readable as doing so.
- **Auditing.** `govern/stamped-assess` already owns the check. This owns the action.

## Decisions

- **Planner-only, over `datalad`.** The minimal working version is the one that makes the step
  recorded and provenanced. That is achievable now with the doer that exists, and it is the half
  that is missing — a researcher already has defacing tools, and has nowhere to record their use.
- **The skill refuses to imply safety.** In the shape the archive doer uses for `unminted`: no
  statement that data is de-identified appears unless a recorded action produced it, and the
  residual-risk field is required rather than optional. An empty residual risk is a claim, and
  claiming nothing remains is exactly the failure this step exists to prevent.
- **It is a curate skill, not a govern skill.** It transforms data, and curate is where data
  transformations live. The obligation it resolves lives in govern; the two are linked through the
  ledger, not by merging the skills.
- **Deliberate retention is recorded, not just removal.** Keeping scan dates for a longitudinal
  design is a legitimate choice; an unrecorded one is indistinguishable from an oversight.

## Risks / Trade-offs

- **A skill that records without removing can read as theatre.** It has to be plain that it
  scaffolds the decision and the record, and that the researcher runs the tool. The 🔧
  Do-it-yourself convention in `docs/end-to-end-workflow.md` is the existing way of saying that.
- **Recording an approach can look like certifying it.** Mitigated by the required residual-risk
  field and by refusing compliance language, but this is the risk to watch in review.
- **Scope pressure toward the tooling.** Defacing and PHI detection are the interesting part and
  will pull at this change. They are a separate change; the value here is that the step stops being
  invisible.
