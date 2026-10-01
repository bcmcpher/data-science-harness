# Live tool fixtures

Small inputs for the live tool sections of `tests/e2e-smoke.sh`, which run only when the
matching `tests/envs/<tool>/` env is synced (`bin/test-envs sync`).

| Path | Used by | Source |
|---|---|---|
| `nipoppy/manifest.tsv` | nipoppy `track-curation`, `status` | Written here: one row in the column layout of the template manifest `nipoppy init` writes (nipoppy 0.4.7). |
| `bids/` | pynidm `bidsmri2nidm` | Written here: one subject, one T1w. `participants.json` annotates every `participants.tsv` column, without which `bidsmri2nidm` prompts on stdin for each one. |
| `write-nifti.py` | the e2e, before pynidm runs | Written here: writes `sub-01_T1w.nii.gz`, a one-voxel NIfTI-1, with the standard library only. No binary is committed. |
| `reproschema/` | reproschema `validate` | Copied from the reproschema-py 1.1.0 test data (`reproschema/tests/{contexts,data}`, Apache-2.0, https://github.com/ReproNim/reproschema-py). `activity1.jsonld` is trimmed to one item: `item2` and the `compute` total that sums both are removed. |
| `bagel/` | bagel `pheno` | Copied unchanged from neurobagel/neurobagel_examples at commit `25009a1e6edcf50f66df5db68f29f35c9683f7e4` (MIT, licence in `bagel/LICENSE`): `data-upload/example_synthetic.{tsv,json}` → `participants.{tsv,json}`, `data-upload/synthetic_dataset_description.json` → `dataset_description.json`. |

The Neurobagel annotations are copied, not written: hand-writing term identifiers would be the
recall the annotate spec forbids, even in a fixture.
