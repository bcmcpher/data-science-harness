# Lab-in-a-Box deployment (reference)

Lab-in-a-Box (LiaB) is a **data-sovereign distribution channel**: instead of (or alongside) a
cloud host, the project stands up self-hosted infrastructure that serves the DataLad dataset over
git-annex remotes. It is scaffolded as a `pyinfra` deployment config so the infra itself is
declarative and reproducible.

```
<liab>/
├── deploy.py                 # pyinfra deployment (hosts, operations)
├── inventory.py              # target host(s)
├── config/
│   ├── forgejo/              # self-hosted git host (Forgejo) config
│   └── git-annex/            # special-remote / data-serving config
└── README.md                 # how to run: `pyinfra inventory.py deploy.py`
```

## How it maps to the harness
- **Forgejo** hosts the DataLad dataset's git history on infrastructure the lab controls.
- **git-annex special remote** serves the annexed file content, so a clone can `datalad get` the
  data from the self-hosted store — the same Distributability as a cloud sibling, but data-sovereign.
- Registered as a sibling via the datalad doer (`create-sibling` against the Forgejo/annex store),
  then `disseminate/publish` pushes to it — LiaB is a *destination*, not a replacement for the
  release/provenance flow.
- Record the deployment as a product (often `other`) that relates to the dataset via
  `IsVariantFormOf` (a data-sovereign mirror) through `link-outputs`.

Canonical sources: pyinfra, Forgejo, git-annex special remotes.
