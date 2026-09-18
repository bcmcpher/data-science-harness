## ADDED Requirements

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
