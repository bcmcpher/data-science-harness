## MODIFIED Requirements

### Requirement: Lab-in-a-Box deployment is planned before it touches a host

`disseminate/liab-deploy` MUST delegate deployment to the liab doer and MUST declare
`delegates_to: [liab, datalad]`. It MUST produce a reviewable deployment plan by default, and MUST
register the resulting endpoint as a DataLad sibling through the datalad doer. It MUST record what
was deployed and MUST NOT assert that the deployment satisfies any jurisdiction's data-residency
requirements.

#### Scenario: Planning a self-hosted deployment

- **WHEN** a deployment is scaffolded
- **THEN** the plan is produced and reviewable, and no remote host is contacted

#### Scenario: A deployment is applied and verified

- **WHEN** the plan is applied and the sibling is registered
- **THEN** the skill reports the deployment complete only after a clone can retrieve annexed content
  from the self-hosted remote

#### Scenario: Recording the deployment

- **WHEN** the deployment is recorded in the ledger
- **THEN** the entry states which hosts serve which data, without a compliance claim
