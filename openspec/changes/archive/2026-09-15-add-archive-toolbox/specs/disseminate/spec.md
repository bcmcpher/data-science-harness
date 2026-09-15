## MODIFIED Requirements

### Requirement: Products are cross-linked with DataCite relations in both directions

`disseminate/link-outputs` MUST validate both ends of a relation before recording it, and MUST record
the inverse relation as well for a target inside the ledger, so the compendium is navigable from any
of its products. The ledger's `relations[]` MUST remain the canonical record. Writing a relation onto
an archive record MUST be delegated to the archive doer rather than described in the skill's body.

#### Scenario: Linking a dataset to the paper built from it

- **WHEN** a released dataset is related to a manuscript product
- **THEN** both the relation and its inverse are recorded with DataCite relation types

#### Scenario: One end does not exist

- **WHEN** a relation names a product id that is not in `products[]`
- **THEN** the relation is not recorded and the missing end is reported

#### Scenario: An external identifier cannot be resolved

- **WHEN** the target is an external DOI that does not resolve, or whose resolution cannot be checked
- **THEN** the relation is recorded, and both the log entry's note and the report mark the target
  as unresolved

#### Scenario: The source product carries a DOI

- **WHEN** a relation is recorded on a product that has a minted DOI
- **THEN** `link-outputs` delegates writing it onto that DOI's record to the archive doer, and a
  `result: ledger-only` answer is reported without undoing the ledger record
