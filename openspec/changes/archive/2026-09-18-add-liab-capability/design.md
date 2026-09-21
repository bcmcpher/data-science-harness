## Context

Every other capability in the harness operates on a local dataset or a hosted archive with a
well-defined API. This one configures servers. A mistaken `datalad save` is recoverable; a mistaken
pyinfra run against the wrong inventory is not, in the same way.

## Goals / Non-Goals

**Goals:**
- Produce a reviewable deployment plan before anything is applied.
- Register the resulting Forgejo/git-annex endpoint as a DataLad sibling so the deployment actually
  becomes a distribution channel rather than a parked server.
- An e2e assertion that exercises planning without a host.

**Non-Goals:**
- Provisioning hardware or cloud instances. The capability configures hosts it is given.
- Managing secrets. Credentials come from the user's existing pyinfra and Forgejo configuration.
- Backup, monitoring, or ongoing operations. This is deployment, not administration.

## Decisions

- **Plan and apply are separate operations, and plan is the default.** The doer produces a diff of
  intended changes that a human reads before anything runs. This is stricter than the other doers'
  "show the command before executing" rule because the blast radius is a machine rather than a
  working tree.
- **Applying to a remote host requires explicit confirmation naming the target**, so an inventory
  mistake surfaces as a wrong hostname in the confirmation rather than as a wrong server changed.
- **The deployment is not done until the sibling resolves.** The capability's success criterion is a
  `datalad get` from the self-hosted remote, not a green pyinfra run — the same standard
  `disseminate/publish` already applies to distributability.
- **The e2e assertion covers the plan path only.** Testing apply would need a disposable host; the
  gated block asserts that a plan is produced and that no network operation occurred.

## Risks / Trade-offs

- **Irreversibility.** Server configuration is harder to undo than anything else the harness does,
  and pyinfra's failure modes are partial-application. Plan-by-default and explicit target
  confirmation are the mitigations; neither eliminates the risk.
- **Data sovereignty is a legal claim, not a technical one.** Self-hosting changes where data sits;
  it does not by itself satisfy any jurisdiction's requirements. The planner should record what was
  deployed, not assert compliance.
- **This is the least-exercised path in the harness.** It is worth accepting that the capability
  ships less verified than the others, and saying so, rather than over-claiming from a dry run.
