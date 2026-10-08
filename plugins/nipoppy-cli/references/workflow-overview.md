# Nipoppy Workflow Overview

## What is nipoppy?

Nipoppy is a Python CLI tool for managing neuroimaging datasets in a standardized,
reproducible way. It wraps around Boutiques descriptors and Apptainer containers to
provide a consistent interface for DICOM organization, BIDS conversion, pipeline
execution, and phenotype extraction.

**Key dependencies:**
- Python 3.8+, installed via `pip install nipoppy`
- **Linux + Apptainer** (formerly Singularity) for all pipeline commands
- Boutiques (`boutiques`) for pipeline descriptor resolution

---

## Linear Workflow

```
Raw DICOMs arrive
        │
        ▼
[1] nipoppy init          — Create dataset directory structure + config stubs
        │
        ▼
[2] Edit manifest.tsv     — Register all expected participant-session pairs
        │
        ▼
[3] nipoppy track-curation — Build/update curation status file
        │
        ▼
[4] nipoppy reorg          — Move/copy DICOMs → post_reorg layout
        │
        ▼
[5] nipoppy track-curation — Update status after reorg
        │
        ▼
[6] nipoppy bidsify        — Convert DICOMs to BIDS (dcm2bids / HeuDiConv / BIDScoin)
        │
        ▼
[7] nipoppy track-curation — Update status after BIDS conversion
        │
        ▼
[8] nipoppy process        — Execute processing pipeline (fMRIPrep, MRIQC, etc.)
        │
        ▼
[9] nipoppy track-processing — Record per-participant pipeline completion
        │
        ▼
[10] nipoppy extract       — Extract IDPs into analysis-ready tables
        │
        ▼
[11] nipoppy status        — Report overall workflow status at any time
```

`nipoppy status` can be run at any point to see current state.

---

## Key Files and Directories

### Dataset root (created by `nipoppy init`)

Default layout as of nipoppy 0.4.7. Earlier releases used `proc/` and kept status files under
`tabular/`.

```
<dataset>/
├── .nipoppy/                      # Root marker; commands walk up from cwd to find it
├── global_config.json             # Global config: container settings, substitutions, HPC
├── manifest.tsv                   # Participant-session registry (user-maintained)
├── sourcedata/
│   ├── imaging/
│   │   ├── pre_reorg/             # Raw DICOMs drop zone (input to reorg)
│   │   ├── post_reorg/            # Reorg output: <participant>/<session>/ layout
│   │   └── curation_status.tsv    # Per-participant-session curation tracking
│   └── tabular/                   # Raw phenotypic files
├── bids/                          # BIDS-valid output from bidsify
├── derivatives/
│   ├── <pipeline>/<version>/      # Pipeline outputs (fMRIPrep, MRIQC, etc.)
│   └── processing_status.tsv      # Processing pipeline status (track-processing)
├── pipelines/{bidsification,processing,extraction}/<name>-<version>/
│                                  # Installed pipeline configs (config.json + descriptor)
├── containers/                    # Container images the pipeline configs point at
├── logs/<workflow>/               # Per-run log files, e.g. logs/process/<name>-<version>/
├── scratch/                       # Temporary working directories
└── tabular/                       # Phenotypic data (assessments/, demographics, harmonized)
```

### global_config.json structure (abbreviated)

```json
{
  "SUBSTITUTIONS": {"[[NIPOPPY_DPATH_CONTAINERS]]": "[[NIPOPPY_DPATH_CONTAINERS]]"},
  "DICOM_DIR_PARTICIPANT_FIRST": true,
  "CONTAINER_CONFIG": {"COMMAND": "apptainer", "ARGS": ["--cleanenv"]},
  "HPC_PREAMBLE": [],
  "PIPELINE_VARIABLES": {"BIDSIFICATION": {}, "PROCESSING": {}, "EXTRACTION": {}},
  "CUSTOM": {}
}
```

Pipelines are not listed here. Each installed pipeline has its own
`pipelines/<type>/<name>-<version>/config.json` (`NAME`, `VERSION`, `CONTAINER_INFO.FILE`/`URI`,
`STEPS`), and `PIPELINE_VARIABLES` fills the variables those configs leave open.

### manifest.tsv columns

| Column | Description |
|--------|-------------|
| `participant_id` | Subject identifier (e.g., `sub-001`) |
| `visit_id` | Visit label (e.g., `BL`) |
| `session_id` | Imaging session label (e.g., `BL`); empty for non-imaging visits |
| `datatype` | List of imaging datatypes (e.g., `['anat', 'func']`) |

---

## Key Concepts & Glossary

| Term | Definition |
|------|------------|
| **Boutiques** | JSON descriptor standard for containerized tools; nipoppy uses it to resolve pipeline invocations |
| **Apptainer** | Linux container runtime (replaces Singularity); required for pipeline commands |
| **BIDS** | Brain Imaging Data Structure — the target format for `bidsify` output |
| **curation_status.tsv** | Tracks raw data availability, reorg completion, and BIDS conversion per participant-session |
| **processing_status.tsv** | `derivatives/processing_status.tsv`: pipeline completion per participant-session (formerly the "bagel" file) |
| **IDP** | Imaging-Derived Phenotype — quantitative measure extracted from a pipeline output (e.g., cortical thickness, FA values) |
| **pre_reorg** | Raw DICOM drop zone; unstructured |
| **post_reorg** | Structured DICOM layout: one folder per participant per session |
| **pipeline step** | A sub-stage within a pipeline (e.g., `prepare`, `convert` in dcm2bids) |
| **simulate** | `--simulate` on `bidsify`/`process`/`extract`: prints the Boutiques invocation without running the container. It still needs Apptainer, the image file on disk, and participants `in_bids` |

---

## Platform Requirements

| Feature | Requirement |
|---------|-------------|
| CLI installation | Python 3.8+, any OS |
| `init`, `status`, `track-curation` | Any OS |
| `reorg` | Any OS (file operations only) |
| `bidsify`, `process`, `extract` | **Linux + Apptainer** (containers required) |
| HPC execution | SLURM or SGE recommended for large cohorts |

---

## Common Pitfalls

1. **Uninitialized dataset** — Running any command other than `init` without a `global_config.json` (and the `.nipoppy/` marker) will fail.
2. **Missing manifest entries** — Participants not in `manifest.tsv` are invisible to all nipoppy commands.
3. **Pre-reorg files not in expected layout** — `reorg` expects files in `pre_reorg/`; ad-hoc layouts may need custom heuristics.
4. **Apptainer not on PATH** — Pipeline commands fail silently if Apptainer is not available; check with `apptainer --version`.
5. **Container image not pulled** — Pipeline containers must be pulled before `process`; nipoppy does not auto-pull by default.
6. **Pipeline version / image mismatch** — `CONTAINER_INFO.FILE` in `pipelines/<type>/<name>-<version>/config.json` must point at an image file that exists in `containers/`.
