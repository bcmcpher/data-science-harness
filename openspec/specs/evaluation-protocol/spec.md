# evaluation-protocol Specification

## Purpose

How the harness would be measured, written down before anything is measured. `docs/evaluation.md`
defines four probes — routing, provenance, reproducibility, cost — each with its metrics, its
control condition, and what would invalidate its result; `bench/` holds the tasks and rubrics as
declarative fixtures, checked structurally by `tests/check-bench-fixtures.py`. Specifying the
measurement first is deliberate: an evaluation designed after the fact tends to measure whatever was
convenient to build. This spec covers the protocol and its fixtures. It does not cover results,
because none exist yet — and a requirement here is that the documents say so.

## Requirements

### Requirement: The evaluation is defined before it is run

`docs/evaluation.md` MUST specify how the harness would be evaluated — the probes, their metric
definitions, the control conditions, the judging procedure, and what would invalidate a result —
independently of any executed run.

#### Scenario: Reading the protocol

- **WHEN** someone outside the project reads `docs/evaluation.md`
- **THEN** they have enough detail to implement and run the evaluation themselves

### Requirement: Unrun evaluations are stated as unrun

Any document describing the evaluation MUST state plainly which probes have been executed and which
have not. It MUST NOT present a protocol in language that implies results exist.

#### Scenario: No probe has been run

- **WHEN** the protocol is published before any execution
- **THEN** it says so explicitly, in `docs/evaluation.md` and in the paper's evaluation section

### Requirement: Probes are independent and composable

Each probe MUST be defined by its own fixture file declaring its identifier, metric definitions,
required capabilities, and control condition. Adding or removing a probe MUST NOT require changing
another probe's definition.

#### Scenario: A probe's integration is dropped from the paper's scope

- **WHEN** a probe is excluded
- **THEN** the remaining probes are unaffected and the fixture is simply not selected

#### Scenario: A required capability is absent

- **WHEN** a probe requires a tool the installation does not have
- **THEN** the probe is skipped with a stated reason rather than reported as a failure or a zero

### Requirement: Tasks and rubrics are declarative fixtures

`bench/` MUST hold probes, task suites, and rubrics as data files, not code. A task MUST declare its
identifier, the prompt, and its expected outcome; a rubric MUST declare its scored dimensions and
their anchors.

#### Scenario: Adding a task

- **WHEN** a new task is contributed
- **THEN** it is a new entry in a task-suite file, requiring no change to shared logic

### Requirement: Routing ground truth is derived from the repository

The routing probe's expected outcome for each task MUST be expressed as the planner skill and the
`delegates_to` targets that should be reached, so ground truth is checkable against the repository
rather than hand-maintained.

#### Scenario: A task names an unresolvable delegation

- **WHEN** a task's `expected_delegates_to` names a plugin that provides no agent
- **THEN** the fixture is invalid, by the same rule `tests/lint-plugins.py` applies to skills

#### Scenario: A capability lands and a planner is rewired

- **WHEN** a planner's `delegates_to` grows
- **THEN** the affected task's expected outcome is updated in the fixture, and the change is visible
  in review

### Requirement: Every probe declares a control condition

Each probe MUST state what it is measured against — a harness-off condition, a recorded baseline, or
an absolute criterion. A probe with no stated control MUST NOT be reported.

#### Scenario: A comparative claim

- **WHEN** a probe reports an improvement
- **THEN** the condition it improved over is named in the probe definition

### Requirement: The four probes are routing, provenance, reproducibility, and cost

The protocol MUST define at least these four probes: routing accuracy of planner selection and
delegation; STAMPED and provenance completeness of a produced artifact; end-to-end reproducibility of
a produced compendium; and cost in tokens, wall-clock, and human interventions per lifecycle stage.

#### Scenario: Reporting a subset

- **WHEN** the paper reports fewer than four probes
- **THEN** the omitted probes are named as unmeasured rather than left unmentioned

### Requirement: Existing tooling is reused rather than reimplemented

Where a probe's measurement is already implemented, the protocol MUST name that tool rather than
specifying a new one — `schemas/validate-ledger.py` and `tests/e2e-smoke.sh` for provenance and
reproducibility, and the existing cost-priced transcript analyzer for cost.

#### Scenario: Specifying the cost probe

- **WHEN** the cost probe is defined
- **THEN** it names the existing transcript analyzer as its measurement instrument
