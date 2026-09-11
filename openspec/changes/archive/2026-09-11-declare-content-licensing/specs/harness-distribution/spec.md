## ADDED Requirements

### Requirement: Licensing travels with the content and is resolvable

The repository MUST declare licensing separately for code and for content, using SPDX short
identifiers rather than prose descriptions, and the declaration MUST be machine-readable. Content
MUST carry a licence that permits reuse with attribution.

#### Scenario: A reuser takes a single skill

- **WHEN** someone copies one `SKILL.md` out of the repository
- **THEN** the terms covering it are determinable from the repository's declared path mapping,
  without reading prose

#### Scenario: The paper declares its own licence

- **WHEN** `paper/myst.yml` declares a content and code licence for the manuscript
- **THEN** it agrees with the repository-wide declaration rather than contradicting it
