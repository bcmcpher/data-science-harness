## MODIFIED Requirements

### Requirement: Reporting compliance is recorded item by item

`disseminate/reporting-checklist` MUST select the applicable guideline — an EQUATOR checklist such as
CONSORT, STROBE, PRISMA, or ARRIVE, or COBIDAS for neuroimaging — instantiate it against the product,
and record compliance per item. Checklist items MUST come from bundled reference text under
`plugins/disseminate/references/`, not from model recall, and each reference file MUST name the
authoritative source it derives from.

#### Scenario: Preparing for submission

- **WHEN** a checklist is applied to a manuscript product
- **THEN** a completed checklist artifact is registered as part of that product, with unmet items
  visible, and every item traceable to the bundled guideline text

#### Scenario: A guideline is not bundled

- **WHEN** the applicable guideline has no reference file
- **THEN** the skill reports that it cannot produce a checked list and names the canonical source,
  rather than reconstructing the items
