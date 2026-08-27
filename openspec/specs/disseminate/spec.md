# disseminate

## Purpose

The workflow-plane plugin for Stages 6-8, and the largest one: eight planner skills that turn a
grouped product into a citable release and then into a living research compendium. The compendium is
the project's thesis made concrete — a provenanced dataset, a re-executable article, an
agent-callable method bundle, and a self-hostable deployment, all built from one DataLad chain and
cross-linked by DOI. Most of these planners currently describe outputs whose capability plane is not
yet built, which is the known shape of the work ahead.

## Requirements

### Requirement: Publishing verifies distributability rather than assuming it

`disseminate/publish` MUST ensure a clean, committed tree, guard against publishing secrets, push
both git history and annexed content to a chosen sibling through the datalad doer, and then verify
that a fresh clone can `datalad get` the results.

#### Scenario: A dataset is published

- **WHEN** a dataset is pushed to a sibling
- **THEN** an independent clone retrieves the annexed content, and that verification is what the
  skill reports rather than a bare push success

#### Scenario: Secrets are present

- **WHEN** credentials or other secrets would be included in the push
- **THEN** the skill stops and reports them before anything leaves the machine

### Requirement: A release fixes an exact, citable state

`disseminate/dataset-release` MUST bump the product version, write a BIDS `CHANGES` entry, and tag
the exact state through the datalad doer on a clean tree, before any deposit is attempted.

#### Scenario: Cutting a release

- **WHEN** a product is released
- **THEN** a version tag names an immutable committed state and the `CHANGES` entry describes it

### Requirement: DOI minting is gated and its absence is visible

`disseminate/dataset-release` MUST delegate minting to the archive doer, and MUST record the release
without a DOI when the doer reports `result: unminted`.

#### Scenario: No archive credentials are configured

- **WHEN** a release is cut without credentials
- **THEN** the release and its tag still exist, the product carries no DOI, and the report says the
  DOI was not minted and how to enable it

#### Scenario: A DOI is returned

- **WHEN** the archive doer returns a resolvable identifier
- **THEN** it is appended to the product's `dois` and the product status becomes released

### Requirement: Products are cross-linked with DataCite relations in both directions

`disseminate/link-outputs` MUST validate both ends of a relation before recording it, and MUST record
the inverse relation as well, so the compendium is navigable from any of its products.

#### Scenario: Linking a dataset to the paper built from it

- **WHEN** a released dataset is related to a manuscript product
- **THEN** both the relation and its inverse are recorded with DataCite relation types

#### Scenario: One end does not exist

- **WHEN** a relation names a product id or identifier that cannot be resolved
- **THEN** the relation is not recorded and the unresolved end is reported

### Requirement: Manuscript drafting fills only what provenance supports

`disseminate/draft-manuscript` MUST scaffold an IMRaD structure for a product and fill the Methods,
data-availability, and provenance sections from the DataLad history and the ledger. It MUST NOT
invent results, statistics, or citations; missing evidence MUST be flagged instead.

#### Scenario: Methods are generated

- **WHEN** a manuscript is scaffolded for a product
- **THEN** the Methods and data-availability text traces to recorded runs and ledger fields, and the
  scientific argument is left for the author

#### Scenario: Evidence is missing

- **WHEN** a section would require a number that provenance does not supply
- **THEN** the gap is flagged in the draft rather than filled with a plausible value

### Requirement: Reporting compliance is recorded item by item

`disseminate/reporting-checklist` MUST select the applicable guideline — an EQUATOR checklist such as
CONSORT, STROBE, PRISMA, or ARRIVE, or COBIDAS for neuroimaging — instantiate it against the product,
and record compliance per item.

#### Scenario: Preparing for submission

- **WHEN** a checklist is applied to a manuscript product
- **THEN** a completed checklist artifact is registered as part of that product, with unmet items
  visible

### Requirement: The executable article rebuilds its own figures

`disseminate/executable-article` MUST scaffold a MyST or Jupyter Book article for a product whose
figures are wired to the provenanced data and the project's container environment, so the article
regenerates its results rather than embedding static images.

#### Scenario: A reproducible preprint is scaffolded

- **WHEN** an executable article is produced for a released product
- **THEN** each figure traces to the run that generated it and the article builds from the pinned
  environment

### Requirement: The agent bundle exposes methods as callable tools

`disseminate/agent-bundle` MUST extract candidate tools from the product's scripts and data
dictionary, emit them in the harness's own skill and manifest format alongside an MCP configuration,
and include tests that reproduce the product's recorded results.

#### Scenario: Methods are made agent-callable

- **WHEN** an agent bundle is produced
- **THEN** it is loadable by an assistant as tools, and its reproduction tests check the results
  against what the provenance chain recorded

### Requirement: Lab-in-a-Box deployment is planned before it touches a host

`disseminate/liab-deploy` MUST scaffold a deployment configuration for self-hosted Forgejo and
git-annex data serving and register the resulting sibling through the datalad doer. It MUST be able
to produce a deployment plan without contacting a real host.

#### Scenario: Planning a self-hosted deployment

- **WHEN** a deployment is scaffolded in dry-run form
- **THEN** the plan is produced and reviewable, and no remote host is modified

### Requirement: Every product and release is recorded in the ledger

Each skill in this plugin MUST register its output as or against a product in `project.yaml`, append
a log entry, and save through the datalad doer.

#### Scenario: Any dissemination step completes

- **WHEN** an article, bundle, checklist, release, or deployment is produced
- **THEN** the ledger names it, the log records it, and the state is committed
