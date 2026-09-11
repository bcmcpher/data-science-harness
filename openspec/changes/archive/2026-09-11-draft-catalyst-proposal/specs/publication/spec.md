## ADDED Requirements

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
