# publication Specification

## Purpose

How the work is written up for readers outside the repository. `paper/` is a MyST project rather
than a static document, because the paper argues that research products should be re-executable and
drafting it in a frozen format would undercut that argument; `tests/check-paper.sh` builds it and
fails on an unresolved citation, which MyST otherwise reports only as a warning. This spec covers
the draft's form and the honesty rules binding it — no unmeasured result, no unearned
complementarity, the venue's requirements recorded alongside. It does not cover the paper's
argument, which is not a matter for a spec.

## Requirements

### Requirement: The paper is drafted as a re-executable project

`paper/` MUST be a MyST project, so the manuscript arguing for re-executable research products is
itself one. Its bibliography MUST come from `docs/references/references.bib` rather than a separate
copy.

#### Scenario: The paper is built

- **WHEN** the MyST project is built
- **THEN** it renders and its citations resolve from the single BibTeX source

#### Scenario: A source is added to the record

- **WHEN** a new source is added to `docs/references/`
- **THEN** it is citable from the paper without duplicating the entry

### Requirement: The paper states its positioning against overlapping work precisely

The paper MUST state where its scope overlaps prior agentic research harnesses and where it differs,
naming the specific mechanisms on each side. It MUST NOT describe overlapping work as complementary
without saying what the interface between the two actually is.

#### Scenario: Describing related work

- **WHEN** an overlapping system is discussed
- **THEN** the paper names what that system governs, what this harness governs, and the concrete
  point at which they meet

### Requirement: The paper claims no unmeasured result

The paper MUST NOT report a benchmark number that has not been produced, and its evaluation section
MUST present the protocol as planned work while no probe has been run.

#### Scenario: The evaluation section before any run

- **WHEN** the preprint is drafted with no executed probes
- **THEN** the evaluation section describes the protocol and states explicitly that no results exist

#### Scenario: Limitations

- **WHEN** limitations are stated
- **THEN** the absence of executed evaluation is named as the first one

### Requirement: The venue's requirements are recorded with the draft

The paper MUST record its intended venue path — preprint first, then Aperture Neuro — and the
submission constraints that follow from it, so formatting and licensing decisions are made once.

#### Scenario: Preparing a submission

- **WHEN** the draft is prepared for submission
- **THEN** the venue's licensing and open-science requirements are already recorded alongside it

### Requirement: One canonical statement of why the work exists

The repository MUST carry a single document stating why the harness exists, who it is for, what it
claims, and what is not built. Other surfaces that state the work's purpose — the README, the
marketplace manifest, plugin READMEs — MUST NOT state a different problem, a different design
commitment, or a different claim set, and MUST refer to that document rather than restating it at
length.

The manuscript in `paper/` is exempt from referring outward, because a published document must stand
alone for a reader who cannot follow a repository link. It remains bound by the requirement not to
contradict.

#### Scenario: A reader arrives from the marketplace rather than the README

- **WHEN** the work's purpose is read from any surface
- **THEN** the problem it states, the design commitment it names, and the claims it makes are the
  same ones the canonical document states

#### Scenario: The purpose is restated in a second place

- **WHEN** a surface needs to say what the work is for
- **THEN** it states the identity briefly and refers to the canonical document, rather than carrying
  a second full account that can drift

### Requirement: The motivation document states its status where the motivation is read

The canonical document MUST state what is built, what is specified but unbuilt, and what has not been
run, positioned so a reader meets it while forming an impression of the work rather than after. Every
claim in it MUST be built, specified in `openspec/specs/`, or labelled as a gap.

#### Scenario: The capability plane is uneven

- **WHEN** the document describes what the harness can do
- **THEN** it names the capabilities that have no toolbox beneath them, rather than describing the
  plane as uniformly delivered

#### Scenario: A claim is measured by an unrun probe

- **WHEN** the document states what the harness claims
- **THEN** it names the probe that would measure the claim and states that no probe has been run

### Requirement: Work delivered outside the repository is recorded without inflating it

The canonical document MUST record the training and reference work that is delivered outside the
repository, because it is part of the offering and is recoverable from no file. That record MUST NOT
state a date, a headcount, or an institutional reach that was not supplied, and MUST name what
specifics would strengthen it, so the gap is routed rather than filled by assumption.

#### Scenario: No figures have been supplied for delivered training

- **WHEN** the training record is written
- **THEN** it describes the work qualitatively and names the specifics still to collect, rather than
  estimating scale

#### Scenario: The work involves other people's programmes

- **WHEN** training delivered through a third party's programme is described
- **THEN** the role and the work are described without naming individuals

### Requirement: A funding document maps claims to evidence with a closed status vocabulary

A document making a case for funding MUST state, for every claim, the evidence supporting it and one
of three statuses: *built* (on disk and covered by `openspec/specs/`), *specified* (a requirement or
protocol exists, the thing it describes does not), or *gap* (neither). It MUST NOT describe work
tracked in `openspec/changes/` as built, because that directory is the authoritative record of what
is not built.

#### Scenario: A capability is proposed but unbuilt

- **WHEN** a funding document cites a capability whose only record is an entry in
  `openspec/changes/`
- **THEN** it reports that capability as specified or as a gap, never as built

#### Scenario: A reviewer follows a cited path

- **WHEN** any claim in the document is checked against the repository
- **THEN** the cited path exists and supports the status the row assigns it

### Requirement: A funding document distinguishes repository evidence from delivered practice

Where a case rests on training or reference work delivered outside the repository, the document MUST
attribute that evidence to its source rather than presenting it alongside repository evidence
undifferentiated. Work that cannot be checked against a file and work that can are different kinds of
claim, and a reader MUST be able to tell which is which.

#### Scenario: A criterion is answered from outside the repository

- **WHEN** a criterion is met mainly by training delivered outside the repository
- **THEN** the row names that as the source, and any structural support from the repository is stated
  separately rather than merged into it

### Requirement: A funding document states what it cannot claim

The document MUST carry the project's limitations without softening them, including every limitation
already recorded in the manuscript, and MUST NOT report a number produced by a measurement that has
not been run. A figure belonging to overlapping work MUST be attributed to that work.

#### Scenario: The evaluation has not been run

- **WHEN** the document describes what the harness achieves
- **THEN** it states that no probe has been executed and presents the protocol as proposed work

#### Scenario: An overlapping system's published result is relevant

- **WHEN** a result from overlapping work is cited
- **THEN** it is attributed to that work and is not presented as evidence for this project
