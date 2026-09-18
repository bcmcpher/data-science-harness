## MODIFIED Requirements

### Requirement: Reporting compliance is recorded item by item

`disseminate/reporting-checklist` MUST select the applicable guideline — an EQUATOR checklist such as
CONSORT 2025, STROBE, PRISMA 2020 or ARRIVE 2.0, and COBIDAS alongside it for neuroimaging —
instantiate it against the product, and record compliance per item. Checklist items MUST be copied
from bundled reference text under `plugins/disseminate/references/`, in the guideline's own wording
and order, never from model recall. Each reference file MUST name the authoritative source it derives
from **and the basis on which that source may be redistributed**, with the date that basis was
checked. The skill MUST NOT state that a product is compliant with a guideline.

#### Scenario: Preparing for submission

- **WHEN** a checklist is applied to a manuscript product
- **THEN** a completed checklist artifact is registered as part of that product, with unmet items
  visible, and every item traceable to the bundled guideline text

#### Scenario: A guideline is not bundled

- **WHEN** the applicable guideline has no reference file
- **THEN** the skill reports that it cannot produce a checked list and names the canonical source,
  rather than reconstructing the items — including partially, because a partial checklist is
  submitted as though it were whole

#### Scenario: A guideline's checklist is published under more than one licence

- **WHEN** the same checklist is distributed both from the guideline's own site without a licence and
  in an openly licensed journal article
- **THEN** the bundled text derives from the licensed publication, and the reference file says which
  one and why
