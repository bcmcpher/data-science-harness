## ADDED Requirements

### Requirement: The liab doer owns infrastructure-deployment mechanics

The liab doer MUST own pyinfra and Forgejo invocation. Planner skills MUST NOT call them directly.

#### Scenario: A deployment is requested

- **WHEN** `disseminate/liab-deploy` needs a host configured
- **THEN** it delegates to the liab doer with the declared inventory and target

### Requirement: Planning is the default and applying is explicit

The liab doer MUST default to producing a reviewable plan of intended changes. It MUST NOT apply
changes to a remote host without an explicit instruction to apply.

#### Scenario: A deployment is scaffolded

- **WHEN** a deployment is requested without an explicit apply
- **THEN** the doer produces a plan, contacts no host, and reports what would change

#### Scenario: Apply is requested

- **WHEN** the user asks to apply the plan
- **THEN** the doer restates the target hostnames and confirms before running, so an inventory
  mistake surfaces as a wrong hostname rather than a wrong server

### Requirement: A deployment succeeds only when the sibling resolves

The liab doer MUST verify that the deployed endpoint works as a DataLad sibling — that a clone can
retrieve annexed content from it — before reporting the deployment as complete.

#### Scenario: The server is configured but not serving data

- **WHEN** pyinfra completes but `datalad get` from the new sibling fails
- **THEN** the doer reports the deployment as incomplete and names the failing step

### Requirement: Partial application is reported, not retried silently

When a pyinfra run fails partway, the liab doer MUST report which operations were applied and which
were not, and MUST NOT re-run automatically.

#### Scenario: A run fails midway

- **WHEN** an operation fails against one host in the inventory
- **THEN** the doer reports the applied and unapplied operations per host and stops

### Requirement: The toolbox provides one skill per tool

`plugins/liab-cli/` MUST provide `user-invocable: true` skills for `pyinfra` and `forgejo`, each with
an `argument-hint` and scoped `allowed-tools`.

#### Scenario: A user drives a tool directly

- **WHEN** a user invokes the `pyinfra` skill without a planner
- **THEN** the skill runs standalone and defaults to a plan rather than an apply

### Requirement: Every operation returns a structured result

The liab doer MUST report the operation, the plan or command, `result`, the hosts affected, and the
sibling verification outcome.

#### Scenario: A plan is produced

- **WHEN** planning completes
- **THEN** the report contains the intended changes per host and states that nothing was applied
