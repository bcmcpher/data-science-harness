## MODIFIED Requirements

### Requirement: Publishing verifies distributability rather than assuming it

`disseminate/publish` MUST ensure a clean, committed tree, guard against publishing secrets, push
both git history and annexed content to a chosen sibling with `datalad push`, and then verify that a
fresh clone can `datalad get` the results.

#### Scenario: A dataset is published

- **WHEN** a dataset is pushed to a sibling
- **THEN** an independent clone retrieves the annexed content, and that verification is what the
  skill reports rather than a bare push success

#### Scenario: Secrets are present

- **WHEN** credentials or other secrets would be included in the push
- **THEN** the skill stops and reports them before anything leaves the machine

### Requirement: A release fixes an exact, citable state

`disseminate/dataset-release` MUST bump the product version, write a BIDS `CHANGES` entry, save it
with `datalad save`, and tag the exact state on a clean tree, before any deposit is attempted.

#### Scenario: Cutting a release

- **WHEN** a product is released
- **THEN** a version tag names an immutable committed state and the `CHANGES` entry describes it

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
- **THEN** the relation is recorded, and both the recording commit's message and the report mark the
  target as unresolved

#### Scenario: The source product carries a DOI

- **WHEN** a relation is recorded on a product that has a minted DOI
- **THEN** `link-outputs` delegates writing it onto that DOI's record to the archive doer, and a
  `result: ledger-only` answer is reported without undoing the ledger record

### Requirement: The executable article rebuilds its own figures

`disseminate/executable-article` MUST delegate scaffolding and building to the compendium doer, and
MUST declare `delegates_to: [compendium]`. The produced article's figures MUST be wired to the
provenanced data and built in the project's container environment, so the article regenerates its
results rather than embedding static images.

#### Scenario: A reproducible preprint is scaffolded

- **WHEN** an executable article is produced for a released product
- **THEN** each figure names the run that generated it, and the article builds from the pinned
  environment

#### Scenario: The build fails

- **WHEN** the compendium doer reports a build failure
- **THEN** the skill reports it and does not register the article product as buildable

### Requirement: The agent bundle exposes methods as callable tools

`disseminate/agent-bundle` MUST delegate bundle emission to the compendium doer and MUST declare
`delegates_to: [compendium]`. The bundle MUST be emitted in the harness's own skill and manifest
format alongside an MCP configuration, and MUST include tests that reproduce the product's recorded
results.

#### Scenario: Methods are made agent-callable

- **WHEN** an agent bundle is produced
- **THEN** it is loadable by an assistant as tools, and its reproduction tests check the results
  against what the provenance chain recorded

#### Scenario: A tool's result cannot be reproduced

- **WHEN** a reproduction test fails
- **THEN** the failing tool is reported and the bundle records which tools are verified

### Requirement: Lab-in-a-Box deployment is planned before it touches a host

`disseminate/liab-deploy` MUST delegate deployment to the liab doer and MUST declare
`delegates_to: [liab]`. It MUST produce a reviewable deployment plan by default, and MUST register
the resulting endpoint as a DataLad sibling itself, running DataLad directly. It MUST record what was deployed and MUST NOT assert that the deployment
satisfies any jurisdiction's data-residency requirements.

#### Scenario: Planning a self-hosted deployment

- **WHEN** a deployment is scaffolded
- **THEN** the plan is produced and reviewable, and no remote host is contacted

#### Scenario: A deployment is applied and verified

- **WHEN** the plan is applied and the sibling is registered
- **THEN** the skill reports the deployment complete only after a clone can retrieve annexed content
  from the self-hosted remote

#### Scenario: Recording the deployment

- **WHEN** the deployment is recorded in the ledger
- **THEN** the recording commit's message states which hosts serve which data, without a compliance
  claim

### Requirement: Every product and release is recorded in the ledger

Each skill in this plugin MUST register its output as or against a product in `project.yaml` and
save with `datalad save` in a commit carrying `DSH-Op`, `DSH-Stage` and `DSH-Product` lines.

#### Scenario: Any dissemination step completes

- **WHEN** an article, bundle, checklist, release, or deployment is produced
- **THEN** the ledger names it, and the commit that records it carries `DSH-Op`, `DSH-Stage` and a
  `DSH-Product` line naming the product
