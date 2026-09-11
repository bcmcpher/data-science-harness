# literature-record Specification

## Purpose

The sources that motivate the harness, recorded so that a claim can be traced back to the work that
prompted it. `docs/references/` holds one BibTeX file as the single citation source of truth, an
index table, and one annotated note per source stating what the source motivates and where it
differs from what is built here. A source that motivates nothing identifiable does not belong in it.
This is distinct from `docs/writing/`, which collects sources on manuscript *craft*; this record is
about the problem.

## Requirements

### Requirement: Motivating sources are recorded in one place

`docs/references/` MUST hold a BibTeX file that is the single citation source of truth, an index
table of sources, and one annotated note per source. It MUST follow the table convention already
established in `docs/writing/index.md`.

#### Scenario: A new source is added

- **WHEN** a paper, preprint, or post motivates a design decision
- **THEN** it is added to the BibTeX file, the index table, and a note, rather than being cited only
  in prose

### Requirement: Every source names what it motivates

Each note MUST state the source's core claim, **what it motivates** by naming at least one
`openspec/specs/` capability or plugin, and **where it differs** from this project's approach.

#### Scenario: A source motivates nothing identifiable

- **WHEN** a note cannot name a capability it bears on
- **THEN** the source does not belong in the record, and is either removed or moved to background
  reading

#### Scenario: A source overlaps with this project

- **WHEN** a source describes a system with overlapping scope
- **THEN** the note states the overlap explicitly rather than describing the work as complementary by
  default

### Requirement: Copyrighted material stays out of the repository

Source PDFs MUST go to the git-ignored `resources/` directory. Notes MUST paraphrase and use only
short quotations, with an attribution statement, matching the practice in `docs/writing/index.md`.

#### Scenario: A source is available only as a PDF

- **WHEN** a paper's PDF is obtained
- **THEN** it is stored in `resources/` and referenced by filename from the index, and is not
  committed

#### Scenario: A source is web-only

- **WHEN** a source is a blog post or web page with no distributable file
- **THEN** the index records the URL and the access date
