# Nipoppy Curation Commands: `track-curation` and `reorg`

## `nipoppy track-curation`

Create or update the curation status file (`sourcedata/imaging/curation_status.tsv` in the
0.4.7 default layout; earlier releases used `tabular/`), which
tracks raw data availability, reorg completion, and BIDS conversion status per
participant-session pair.

### Synopsis

```bash
nipoppy track-curation [OPTIONS]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--dataset PATH` | cwd | Path to the nipoppy dataset root. |
| `--empty` | off | Set all statuses to `False` in newly added records without scanning disk. Reduces runtime. |
| `--force` / `--regenerate` / `-f` | off | Regenerate the whole file (default: only append rows for new manifest records). |
| `--layout FILE` | default | Custom layout specification file. |
| `--dry-run` | off | Print commands without executing. |
| `--verbose` / `-v` | off | Show DEBUG messages. |

There is no participant or session filter: `track-curation` always covers the whole manifest.

### Curation status file schema (`curation_status.tsv`)

| Column | Values | Description |
|--------|--------|-------------|
| `participant_id` | string | Subject ID from manifest |
| `visit_id` | string | Visit label from manifest |
| `session_id` | string | Session label from manifest |
| `datatype` | list | Datatypes from manifest |
| `participant_dicom_dir` | path | DICOM directory relative to `pre_reorg/` |
| `in_pre_reorg` | `True`/`False` | Raw DICOMs found in `pre_reorg/` |
| `in_post_reorg` | `True`/`False` | Reorg output present in `post_reorg/` |
| `in_bids` | `True`/`False` | BIDS output present in `bids/` |

Each run also writes a timestamped copy to `sourcedata/imaging/.curation_statuses/`.

### When to run `track-curation`

Run after each of these events to keep status current:
1. After populating `manifest.tsv` (`init` does not create the file; the first `track-curation` does)
2. After dropping new DICOMs into `pre_reorg/`
3. After `nipoppy reorg` completes
4. After `nipoppy bidsify` completes

### Example invocations

```bash
# Update curation status for all participants
nipoppy track-curation --dataset /data/my-study

# Force regenerate from scratch
nipoppy track-curation --dataset /data/my-study --regenerate

# Add new records as all-False without scanning
nipoppy track-curation --dataset /data/my-study --empty
```

---

## `nipoppy reorg`

Reorganize raw DICOM files from the unstructured `sourcedata/imaging/pre_reorg/`
directory into a participant-session layout in `sourcedata/imaging/post_reorg/`.

### Synopsis

```bash
nipoppy reorg [OPTIONS]
```

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `--dataset PATH` | cwd | Path to the nipoppy dataset root. |
| `--copy-files` | off | Copy files to `post_reorg/` instead of moving them. Preserves `pre_reorg/` originals. |
| `--check-dicoms` | off | Validate that files in `pre_reorg/` are valid DICOMs before reorg. Reports corrupt/invalid files. |
| `--dry-run` | off | Print commands without executing. `reorg` has no `--simulate` and no `-n`. |
| `--verbose` / `-v` | off | Show DEBUG messages. |
| `--layout FILE` | default | Custom layout specification file (JSON), not a heuristic script. |

There is no participant or session filter: `reorg` acts on every manifest record not yet in
`post_reorg/`.

### pre_reorg → post_reorg layout

**Input (`pre_reorg/`):** Any structure — flat dump, scanner-native layout, or nested dirs.

**Output (`post_reorg/`):**
```
post_reorg/
└── <participant_id>/
    └── <session>/
        └── <DICOM files or series dirs>
```

### DICOM check warnings

When `--check-dicoms` is used, nipoppy validates each file with pydicom. Files that
fail validation are reported but not moved; the run continues for valid files.

### Non-standard raw layouts

`reorg` takes no heuristic script. It finds each participant-session's raw directory under
`pre_reorg/` from `global_config.json`, using one of two mutually exclusive fields:

- `DICOM_DIR_PARTICIPANT_FIRST` — `true` (default) for `<participant>/<session>/`, `false` for
  `<session>/<participant>/`;
- `DICOM_DIR_MAP_FILE` — a TSV with `participant_id`, `session_id`, `participant_dicom_dir`
  columns for anything else.

Files are copied/moved flat into `post_reorg/<participant>/<session>/`, each name prefixed with a
short hash of its source directory to avoid collisions.

### Example invocations

```bash
# Dry-run to preview what would be reorganized
nipoppy reorg --dataset /data/my-study --dry-run

# Reorg all, copying files (safe — keeps originals)
nipoppy reorg --dataset /data/my-study --copy-files

# Reorg with DICOM validation
nipoppy reorg --dataset /data/my-study --check-dicoms
```

### After reorg

Run `nipoppy track-curation` to update `in_post_reorg` flags in the curation status file.
