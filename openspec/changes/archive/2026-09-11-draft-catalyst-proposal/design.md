# Design

## Why a matrix and not a draft

A two-page proposal is a compression of evidence. Compressing evidence that has not been assembled
produces confident prose with nothing behind it, and the failure mode is specific: a reviewer clicks a
claim and finds a change proposal rather than a shipped capability.

The matrix inverts the order. Each row starts from something on disk — a file path, a spec
requirement, a test — and states what it demonstrates. Rows that cannot name a path are attributed to
training or reference work, which is a different kind of evidence and must be labelled as such rather
than blurred into the repository's. Rows with neither are gaps, and a gap named in the matrix is a
deliverable candidate; a gap discovered while drafting is a crisis.

It also outlives the submission. Applications are not open yet, the deadline is real, and a Track 2
re-scope would need the same mapping. A draft is single-use; the matrix is not.

## Status vocabulary, and why it is closed

Three values only:

- **built** — exists on disk and is covered by `openspec/specs/`, which describes the present.
- **specified** — a requirement or protocol exists; the thing it describes has not been run or built.
- **gap** — neither.

`openspec/changes/` is the authoritative list of what is not built, so a row citing a change
directory is *specified* at best. This is mechanically checkable by reading, and task 3.2 is exactly
that read. The vocabulary is closed because a fourth value — "in progress", "partially built" — is
where overclaiming enters.

Source attribution is likewise closed to *repo* / *training* / *reference*, because the fund's
criteria distinguish what the applicant has built from what they have delivered to a community, and
merging them is the single most likely way this document misleads.

## Where each risk actually lands

Worked out in advance, because the temptation is to claim all five equally.

| Risk | Lands in | Why |
|---|---|---|
| 1. Bypassed engineering judgment | training, with repo support | The repo externalizes judgment structurally; the help desk builds it in people |
| 2. Circular validation | **repo** | The strongest row. A test of the test, CI verified red, controls and invalidators per probe, machine-derived ground truth |
| 3. No shared adoption frameworks | across both | STAMPED-as-requirements and the two-plane pattern are transferable; the training is where transfer is demonstrated |
| 4. Uneven training and tool access | **training** | Weakest in the repository, strongest outside it. A help desk exists because access is uneven |
| 5. Undocumented reasoning | **repo** | `datalad run` capturing model and prompt, the append-only ledger, the reproducibility probe |

Lead with 2. It is the one the repository has already solved at its own scale, and the pattern
generalizes — which is what a catalytic fund is buying.

## What the matrix must refuse to do

- **Report a number that was not measured.** No probe has been run. The routing and grounding figures
  that exist in this space belong to Brain Researcher, not to this project, and must be attributed if
  mentioned at all.
- **Claim complementarity without naming the interface.** The `publication` spec already requires
  this of the paper; a funding document is under the same rule and the same overlapping system is
  involved.
- **Inflate the training record.** No dates, headcounts or institutional reach were supplied. The
  qualitative record is strong; an invented figure would make the whole table suspect.
- **Soften the limitations.** `paper/sections/05-discussion.md` lists six and says so explicitly.

## Out of scope

- **The two-page proposal** (`docs/funding/catalyst-exploratory.md`) and the Track 2 `## Scaling to
  Impact` section. Both are downstream of this and are separate work.
- **A budget.** It depends on the probe runner's shape, which is not settled.
- **Running a probe.** Piloting the routing probe before submission would materially strengthen the
  proposal, and it is a different change with real engineering in it.

## Risks

**The fund's own text is transcribed, not fetched.** The five risks and the review criteria in this
change come from notes taken when the fund page was read, not from a live copy, and applications are
not open yet. Record them as transcribed and re-verify against the published call before anything is
submitted. A matrix built on a misremembered criterion is worse than no matrix.

**"Minimally working" reads as "unfinished".** The honest status — workflow plane built, capability
plane uneven, evaluation unrun — invites a reviewer to supply the less generous reading. The matrix's
job is to make the ask legible as *adoption readiness* rather than construction: this runs, and here
is what it takes for another group to run it.
