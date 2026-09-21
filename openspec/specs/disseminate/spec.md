# disseminate

## Purpose

The workflow-plane plugin for Stages 6-8, and the largest one: nine planner skills that turn a
grouped product into a citable release and then into a living research compendium. The compendium is
the project's thesis made concrete — a provenanced dataset, a re-executable article, an
agent-callable method bundle, and a self-hostable deployment, all built from one DataLad chain and
cross-linked by DOI. `reporting-checklist` is the one planner here whose correctness is a property of
its inputs rather than its procedure: its items are copied from checklist text bundled under
`plugins/disseminate/references/`, each file naming the openly licensed publication it derives from,
because a checklist assembled from recall looks complete and omits exactly the items the guideline
was written for.
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

### Requirement: The executable article rebuilds its own figures

`disseminate/executable-article` MUST delegate scaffolding and building to the compendium doer, and
MUST declare `delegates_to: [compendium, datalad]`. The produced article's figures MUST be wired to
the provenanced data and built in the project's container environment, so the article regenerates its
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
`delegates_to: [compendium, datalad]`. The bundle MUST be emitted in the harness's own skill and
manifest format alongside an MCP configuration, and MUST include tests that reproduce the product's
recorded results.

#### Scenario: Methods are made agent-callable

- **WHEN** an agent bundle is produced
- **THEN** it is loadable by an assistant as tools, and its reproduction tests check the results
  against what the provenance chain recorded

#### Scenario: A tool's result cannot be reproduced

- **WHEN** a reproduction test fails
- **THEN** the failing tool is reported and the bundle records which tools are verified

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

### Requirement: Every product and release is recorded in the ledger

Each skill in this plugin MUST register its output as or against a product in `project.yaml`, append
a log entry, and save through the datalad doer.

#### Scenario: Any dissemination step completes

- **WHEN** an article, bundle, checklist, release, or deployment is produced
- **THEN** the ledger names it, the log records it, and the state is committed

### Requirement: A submission history is appended to, never overwritten

`disseminate/submission-track` MUST record each submission of a product as an entry in an
append-only `submissions[]` history carrying venue, date, status and, once it exists, the decision.
A resubmission MUST append rather than replace, and `product.status` MUST remain `in-progress`
throughout the submission cycle. The skill MUST NOT record a status, decision or date it was not
given, and MUST NOT record an outcome that has not happened.

#### Scenario: A paper is submitted somewhere new after a rejection

- **WHEN** a product that was rejected is submitted to a second venue
- **THEN** a new entry is appended and the first venue's decision remains readable, because where a
  paper was rejected is part of its history

#### Scenario: A decision arrives

- **WHEN** a venue returns a decision
- **THEN** it is recorded as given, without being paraphrased into something more favourable, since
  the field's value is that it can be quoted

#### Scenario: Nothing has been heard

- **WHEN** time has passed with no word from the venue
- **THEN** no status change is inferred, because elapsed time is not evidence a paper is under review

#### Scenario: An outcome is anticipated

- **WHEN** acceptance seems likely but no letter has arrived
- **THEN** nothing is recorded, because the ledger is the file a funder report is generated from

#### Scenario: A submission is tracked while the product is unreleased

- **WHEN** a product is under review
- **THEN** its `status` is `in-progress`, and only an actual release makes it `released`

