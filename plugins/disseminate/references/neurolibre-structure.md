# NeuroLibre executable article (reference)

A NeuroLibre-style reproducible preprint is a MyST/Jupyter Book that **rebuilds its figures from the
provenanced data + environment** rather than embedding static images. The scaffold:

```
<article>/
├── myst.yml                 # MyST project config (title, authors, TOC, exports)
├── paper.md                 # the narrative (MyST markdown), figures as executable outputs
├── content/                 # notebooks / markdown that compute the figures
│   └── figures.ipynb
├── binder/                  # environment pinned to the DataLad container digest
│   ├── environment.yml      # or requirements.txt / apt.txt, matching containers/
│   └── data_requirement.json   # repo2data: points at the OSF/DataLad-published dataset
└── _build/                  # generated (not committed)
```

## How it maps to the harness
- **`binder/`** environment is derived from the project's `containers/` recipe / container digest —
  the same environment analyses ran in (Portability/Ephemerality).
- **`data_requirement.json`** (repo2data) resolves the dataset from its published location — the
  `dataset-release` DOI or the DataLad sibling — so the build fetches exactly the released data.
- **Figures** are computed by `content/` notebooks that call the project's provenanced outputs
  (`derivatives/cmp-<slug>/`), so the article is re-executable end to end (Actionable).
- Build/preview locally with `myst build` / `jupyter book build`; NeuroLibre runs the same build in
  a BinderHub to verify reproducibility.

Canonical sources: NeuroLibre docs, MyST Markdown (`mystmd`), repo2data, Jupyter Book.
