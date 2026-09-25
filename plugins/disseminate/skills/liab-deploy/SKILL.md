---
name: liab-deploy
description: >
  Scaffold a Lab-in-a-Box deployment — a pyinfra config that stands up self-hosted Forgejo +
  git-annex data serving and publishes the DataLad dataset over git-annex remotes as a data-sovereign
  distribution channel. Trigger on "lab in a box", "self-host the data", "data sovereign", "Forgejo",
  "pyinfra deploy", "self-hosted git-annex", "own our infrastructure". Produces a deployment product
  alongside the cloud-hosted outputs.
plane: workflow
stamped: [D]
delegates_to: [liab]
---

# Skill: liab-deploy

Give the project a **data-sovereign** distribution channel: self-hosted infrastructure that serves
the DataLad dataset over git-annex remotes, so the lab controls where its data lives while keeping
the same Distributability a cloud sibling provides. The infra is declarative (pyinfra), so the
deployment itself is reproducible. You register the sibling, verify retrieval, and save yourself, in
the main thread; you delegate planning and applying the deployment to the **liab doer**.

Load `plugins/disseminate/references/liab-deployments.md` for the deployment layout and mapping
before generating.

> Scope note: you decide *that* the project should self-host and what the deployment should contain.
> The liab doer owns the mechanics, and it is the one capability in this harness whose mistakes are
> not confined to a working tree — so it **plans by default** and applies only on an explicit
> instruction that names the target host. Delegate rather than running pyinfra yourself.
>
> Two of its answers you must pass on rather than smooth over. A **partial application** is not a
> deployment: it names the host and the operation that failed, and the next thing anyone would do is
> push data to a half-configured box. And **`applied` is not `working`** — a green pyinfra run
> means the operations applied, not that the service serves. Only a successful `datalad get` of
> annexed content from the self-hosted remote earns the word `working`, which is the same standard
> `disseminate/publish` already applies to a cloud sibling.
>
> Instance setup and repository creation are different requests and reach different skills. Standing
> Forgejo up belongs in the pyinfra deployment, where it can be planned and rebuilt; creating the
> repository on a running instance is the `forgejo` skill, and it will refuse to guess the
> repository's visibility. Neither is improvised from here.

## When to use
- The project wants to self-host its dataset (data sovereignty, institutional policy), alongside or
  instead of a cloud archive.
- Do NOT use to push to an existing sibling (`disseminate/publish`) or to mint a DOI
  (`dataset-release`) — this scaffolds the *destination infrastructure*.

## Steps
1. **Gather targets** — the host(s) that will run the deployment and whether Forgejo (git host) +
   git-annex serving are both wanted. Confirm the operator has access to the target hosts.
2. **Scaffold the deployment** (per the reference) at `liab/`: `inventory.py` (hosts), `deploy.py`
   (pyinfra operations for Forgejo + git-annex special remote), and `config/`. Do not run the
   deployment for the user.
3. **Get a plan from the liab doer, and stop there.**
   > "plan the deployment at `liab/` — state every host the inventory resolves to and the operations
   > that would run per host. Do not apply."

   Report the plan to the user. An apply is a separate, later instruction that names the target host;
   do not request one on the user's behalf, and do not treat their approval of the plan as approval
   to apply.
4. **Create the repository (liab doer), then register the sibling yourself.** Once the instance is
   up, the liab doer creates the repository through its `forgejo` skill. It will ask whether the
   repository is private, and so should you: a dataset repository created public when it should have
   been private is a disclosure, and there is no safe default to assume. Then register the sibling
   directly:
   ```bash
   datalad siblings add -s <sibling-name> --publish-depends <storage-remote> --url <url>
   ```
   so annexed content is actually served, not just history.
5. **Verify retrieval yourself.** Clone the dataset to a scratch dir and `datalad get` an annexed
   file from the sibling; confirm the content arrived, then discard the clone. Only a successful get
   earns `working` — a clean sibling registration alone is `applied`.
6. **Register + save** — record the deployment path (and, once live, the sibling name) under a
   product (kind `other`) `outputs[]`; save:
   ```bash
   datalad save -m "$(printf 'liab-deploy: sibling <name> <applied|working>\n\nDSH-Op: liab-deploy\nDSH-Stage: disseminate\nDSH-Product: <id>\nDSH-Binding: liab/pyinfra@<version>')"
   ```
   Copy the version into `DSH-Binding` from the liab doer's report.
7. **Report** — the deployment path, the liab doer's plan/apply result, whether the sibling was
   registered and whether your own `datalad get` confirmed retrieval (`applied` and `working` are
   different answers), the registered sibling name, and the next step: `disseminate/publish` to push
   to the self-hosted store, then `link-outputs` to relate the mirror to the dataset
   (`IsVariantFormOf`).

## Constraints
- **Scaffold and plan; do not deploy.** Never run pyinfra yourself and never provision a remote
  host on the user's behalf. A **plan** is delegable to the liab doer and is safe by construction
  (a dry run that changes nothing); an **apply** is not yours to request. Present it and let the operator run it
  against their own infrastructure, naming the target host.
- **Record what was deployed; do not claim compliance.** The deployment record says which hosts were
  configured with what, and whether retrieval was verified. It does not assert that the arrangement
  satisfies an institutional policy, a data-residency requirement, or a data-use agreement — those
  are governance judgments made against the obligations in the ledger, by a person. Self-hosting is
  not by itself a compliance outcome, and a record that reads as though it were is worse than no
  record.
- **Never report a deployment as working because a plan or an apply succeeded.** Only your own
  `datalad get` retrieving annexed content from the self-hosted remote earns `working`. Report
  `planned`, `applied`, `working`, `partial` (named host and operation), or `failed`. Collapsing
  these is how a half-configured box becomes the place the data gets pushed.
- The self-hosted store is a *destination* — it reuses the standard sibling/publish/provenance flow
  (register and verify yourself, push via `publish`), it does not bypass it.
- Ensure annexed content is actually served (a storage `--publish-depends`) so a clone can
  `datalad get` from the self-hosted store — otherwise it distributes history without data.
- Record under a product's `outputs[]`; keep the ledger schema-valid. Run the sibling registration
  and retrieval check yourself; delegate deployment planning and applying to the liab doer.
