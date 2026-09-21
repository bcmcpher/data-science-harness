---
name: pyinfra
description: >
  Auto-invoke when the user wants to see or run a declarative infrastructure deployment for
  self-hosted research infrastructure — a Lab-in-a-Box host, a Forgejo git host, a git-annex serving
  box. Trigger on "pyinfra", "deploy the infrastructure", "show me the deployment plan", "what would
  this deploy change", "lab in a box deploy", "self-host this", or /pyinfra. Do NOT trigger for
  pushing data to an already-running sibling (that is a datalad operation) or for deciding what
  infrastructure the project should have.
argument-hint: '[check|plan|apply] [--inventory <inventory.py>] [--deploy <deploy.py>] [--limit <host>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: pyinfra

Produce a deployment **plan** for a declarative infrastructure config, and — only on an explicit,
target-naming instruction — apply it.

**Read this before anything else: the default is a plan, and the blast radius here is a machine
rather than a working tree.** Every other toolbox in this harness can be wrong and leave a dirty
working tree that `git checkout` fixes. This one can be wrong and leave a server changed. That is why
plan-by-default is a constraint rather than a preference, and why applying needs the operator to say
the hostname back.

pyinfra's own flag for this is `--dry`. A run without it **is** an apply.

## Steps

1. **Check the tool before reading an inventory.**
   ```bash
   bash plugins/liab-cli/scripts/check-tools.sh pyinfra
   ```
   Exit 0 means pyinfra is installed and starts. Exit 1 means it is not usable; report the `enable:`
   hint and stop. **The check cannot tell you whether the target hosts are reachable or whether SSH
   keys are loaded** — it deliberately touches no network. Do not read a passing check as readiness
   to deploy.

2. **Confirm the surface.** pyinfra's CLI has changed across major versions, including how `--dry`
   and `--limit` behave.
   ```bash
   pyinfra --version && pyinfra --help
   ```
   Report a divergence rather than translating a flag from a version you remember.

3. **Read the inventory and say out loud what it targets.** Before planning anything, state every
   host the inventory names.
   ```bash
   sed -n '1,60p' inventory.py
   ```
   An inventory that resolves to `@local` and one that resolves to a production hostname are the same
   command with very different consequences. If the inventory names hosts you cannot account for,
   stop and ask.

4. **Plan. Always plan first.**
   ```bash
   pyinfra inventory.py deploy.py --dry
   ```
   Report the operations it would perform, per host, and the count of changes. A plan showing zero
   changes is a meaningful result — either the deployment is already applied or the inventory does
   not match what you expected.

5. **Apply only on an explicit instruction that names the target.** Not "yes", not "go ahead" —
   the operator names the host.
   ```bash
   pyinfra inventory.py deploy.py            # no --dry: this changes the hosts
   ```
   Echo the hostnames back and get them confirmed before running. An inventory mistake should surface
   as a wrong hostname in that confirmation, not as a wrong server changed.

6. **Report a partial application as partial.** pyinfra can complete some operations and fail others,
   leaving a host in a state that is neither the old one nor the intended one. Name which operations
   succeeded, which failed, and on which host.

7. **Never retry a failed apply automatically.** A half-applied deployment re-run without a human
   reading the failure is how a recoverable problem becomes an unrecoverable one. Report and stop.

8. **Report.**
   ```
   op:        pyinfra-<check|plan|apply>
   version:   <as reported by the tool>
   inventory: <path, and every host it resolves to>
   mode:      plan (--dry) | apply
   confirmed: <the hostnames the operator named back, for an apply>
   result:    planned | applied | partial | failed | unavailable
   changes:   <per host: operations that would run, or did>
   failed:    <per host: operations that failed — empty is a claim, state it>
   notes:     <what this did not verify: host reachability, whether the service actually serves>
   ```

## Constraints

- **Never apply without `--dry` first, and never apply without an explicit instruction that names
  the target host.** A generic approval is not sufficient. This is the whole reason the skill exists
  as a separate step rather than as a line in the doer's procedure.
- **Never run an apply from a non-interactive session**, and never assume an earlier approval covers
  a later run against a different inventory.
- **Never report `applied` for a partial application.** Name the host and the operation that failed.
  A partially deployed host reported as deployed is worse than a clean failure, because the next step
  will be to push data to it.
- **Never retry automatically after a failure.** Report and stop; a human reads the failure.
- **Never claim a deployment works because pyinfra exited 0.** A green run means the operations
  applied, not that the service serves. Whether the dataset is actually retrievable from the new
  remote is a `datalad get` question, and it belongs to the liab doer and `disseminate/publish`.
- **Never edit `inventory.py` or `deploy.py` to make a run succeed**, and never add a host to an
  inventory. The infrastructure the project targets is the operator's decision.
- **Never print the contents of a secret** — SSH keys, host passwords, tokens in a config. Report
  that a required secret is present or absent, never its value.
- Do not commit. The datalad doer owns `datalad save`.
- Do not claim the deployment is compliant with any policy, institutional or otherwise. It records
  what was deployed.
