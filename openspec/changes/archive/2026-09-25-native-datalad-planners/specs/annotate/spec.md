## MODIFIED Requirements

### Requirement: The doer writes metadata but does not commit

The annotate doer MUST write metadata files into the dataset and MUST NOT commit them. The calling
planner MUST save them itself with `datalad save`.

#### Scenario: Annotation completes

- **WHEN** the doer finishes writing `participants.json` and sidecars
- **THEN** the files are on disk uncommitted, and the doer reports what it wrote for the planner to save
