## ADDED Requirements

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
