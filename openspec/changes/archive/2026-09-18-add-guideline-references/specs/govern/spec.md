## ADDED Requirements

### Requirement: Dataset-level neuroimaging reporting items are read, not recalled

`govern/qc-review` MUST read the COBIDAS data-sharing and reproducibility items from bundled
reference text when assessing an MRI dataset, and MUST report which mandatory items the project can
evidence from the ledger and the dataset. Where the reference is not installed, it MUST report the
check as skipped with that reason. It MUST NOT state that a project is COBIDAS-compliant.

#### Scenario: An MRI dataset is reviewed

- **WHEN** the STAMPED pass runs against a dataset with imaging data
- **THEN** the sharing and reproducibility items the project can evidence today are named from the
  bundled text, and the ones it cannot are reported as gaps

#### Scenario: The reference is not installed

- **WHEN** `govern` is installed without `disseminate`, so the bundled COBIDAS text is absent
- **THEN** the check is reported as skipped with that reason, and no item is supplied from recall

#### Scenario: Compliance is asked about

- **WHEN** the review is read as a compliance statement
- **THEN** it says that two of seven tables were read, and that assessment against the whole
  guideline happens at submission through `disseminate/reporting-checklist`
