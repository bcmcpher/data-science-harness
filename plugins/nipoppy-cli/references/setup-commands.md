# Nipoppy Setup Commands: `init` and `status`

## `nipoppy init`

Initialize a new nipoppy dataset directory with template configuration files and the
expected directory structure.

### Synopsis

```bash
nipoppy init --dataset <dataset-path> [OPTIONS]
```

The dataset path is an option, not a positional argument: `nipoppy init <path>` is a usage
error in 0.4.7.

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--bids-source PATH` | — | Seed the `bids/` directory from an existing BIDS dataset (copy/move/symlink). |
| `--mode {copy,move,symlink}` | `symlink` | How to import files when `--bids-source` is set. |
| `--force` / `-f` | off | Create the dataset even if files are already present (may overwrite existing files). |
| `--dataset PATH` | cwd | Path to the new dataset root. Created if it does not exist. |
| `--default-config` | off | Ignore the user-level `~/.nipoppy/config.json` and use the built-in default `global_config.json`. |
| `--layout FILE` | default | Path to a custom layout specification file. |
| `--verbose` / `-v` | off | Show DEBUG messages. |
| `--dry-run` | off | Print commands without executing. |

### Directory structure created

```
<dataset>/
├── .nipoppy/                   # Marker: commands find the dataset root by walking up to it
├── global_config.json          # Stub — must be edited before other commands
├── manifest.tsv                # Stub — must be populated with participant rows
├── sourcedata/
│   ├── imaging/
│   │   ├── downloads/
│   │   ├── pre_reorg/          # Drop raw DICOMs here
│   │   └── post_reorg/         # Reorg output lands here
│   └── tabular/                # Raw phenotypic files
├── bids/                       # BIDS output target
├── derivatives/                # Pipeline output target
├── pipelines/
│   ├── bidsification/          # Installed pipeline configs, one <name>-<version>/ each
│   ├── processing/
│   └── extraction/
├── containers/                 # Container images (.sif) the pipeline configs point at
├── code/hpc/                   # HPC job template and cluster configs
├── logs/                       # Log files, logs/<workflow>/…
├── scratch/                    # Temporary working dirs (work/, pybids_db/)
└── tabular/                    # Phenotypic data (assessments/); not status files
```

Layout as of nipoppy 0.4.7 (`nipoppy init`, default layout). Earlier releases used `proc/` and
put status files under `tabular/`; a custom `--layout` file can move any of these.

### Post-init checklist

After `init`, always:
1. Edit `global_config.json` — container settings (`CONTAINER_CONFIG`), `SUBSTITUTIONS`,
   `PIPELINE_VARIABLES`, `HPC_PREAMBLE`. Pipelines are not configured here: each one is installed
   under `pipelines/<type>/<name>-<version>/` (`nipoppy pipeline install`).
2. Populate `manifest.tsv` — add one row per expected participant-session pair.
3. Copy or move raw DICOMs into `sourcedata/imaging/pre_reorg/`.

### Example invocations

```bash
# Initialize a new empty dataset
nipoppy init --dataset /data/my-study

# Initialize seeding bids/ from an existing BIDS directory
nipoppy init --dataset /data/my-study --bids-source /data/existing-bids --mode symlink
```

---

## `nipoppy status`

Report the current workflow status across all participants and sessions. Reads the
manifest, the curation status file (`sourcedata/imaging/curation_status.tsv`) and the
processing status file (`derivatives/processing_status.tsv`) to produce a summary table.

### Synopsis

```bash
nipoppy status [OPTIONS]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--dataset PATH` | cwd | Path to the nipoppy dataset root. |
| `--verbose` / `-v` | off | Show DEBUG log messages. Does not add per-participant detail; the table is always aggregate counts. |

### Output

Status prints a summary of:
- Participant and visit/session counts from the manifest
- A table of participant counts per session at each checkpoint: `in_manifest`, `in_pre_reorg`,
  `in_post_reorg`, `in_bids`
- Per-pipeline completion counts, when a processing status file exists

### Example invocations

```bash
# Status for current directory dataset
nipoppy status

# Status for a specific dataset
nipoppy status --dataset /data/my-study
```

### Notes

- `status` is read-only and safe to run at any time.
- An empty or missing `curation_status.tsv` reports zeros — run `track-curation` first.
- If `derivatives/processing_status.tsv` is missing, status warns and omits pipeline counts —
  run `track-processing` first.
