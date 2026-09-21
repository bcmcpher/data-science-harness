## Why

The [Research Software Catalyst Fund](https://researchsoftwarecatalyst.fund/) is a close match for
what this project already argues. It is a one-time catalytic fund supporting "the practices that make
AI-assisted research software trustworthy" — the norms, tools, methods and training a community needs
to use generative AI well. Track 1 closes late October 2026.

The project answers all five risks the fund names. The problem is that it answers them from three
different places — the repository, the training delivered through a help desk, and reference material
maintained outside both — and no document says which evidence comes from where. Written without one,
a two-pager would either overclaim (presenting specified work as built) or underclaim (omitting the
training, which is the strongest evidence for two of the five risks and the only evidence for the
fund's "broader community benefit beyond applicants" criterion).

The repository's own rule is that a claim must be checkable. `openspec/specs/` states what is built
and `openspec/changes/` states what is not, so a fit matrix can be *derived* rather than asserted —
and a row claiming "built" for something that lives in `changes/` is a defect the matrix itself makes
visible. That is worth more than a draft: it survives into a Track 2 proposal, and it is the thing
that stops each drafting pass re-deriving the same evidence.

The framing has to be held deliberately. The fund is about AI-assisted **software engineering**; this
project is about governance of the **research record** produced with AI assistance. Two of the five
risks land squarely in repository territory, two lean on the training work, and one sits across both.
Every draft will want to widen back toward research data governance, because that is where the
project's prose already lives. A matrix that attributes each row to repo, training or reference is
what holds the line.

## What Changes

- `docs/funding/catalyst-fit.md` — two tables. Table A maps the fund's five named risks to evidence
  with file paths, each row attributed to *repo* / *training* / *reference* and carrying a status of
  *built* / *specified* / *gap*. Table B does the same for the published review criteria.
- A recorded limitations section: what the matrix cannot claim, taken unsoftened from
  `paper/sections/05-discussion.md`.
- A deliverables list drawn from the adoption gaps, stated as artifacts rather than intentions.

## Capabilities

- `publication` — a new requirement covering funding documents, which are publications under the same
  honesty rules: no unmeasured number, no unearned complementarity, and no claim of "built" for work
  that lives in `openspec/changes/`.

## Impact

Documentation only. Nothing in `plugins/`, `tests/` or `schemas/` changes.

The two-page proposal itself and the Track 2 re-scope are **not** in this change. The matrix is the
part that has to exist first and the part that outlives any one submission; drafting the two-pager
against an unwritten matrix is how a proposal ends up claiming things the repository does not support.
