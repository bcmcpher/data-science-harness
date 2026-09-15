## ADDED Requirements

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
