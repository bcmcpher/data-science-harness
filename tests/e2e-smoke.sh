#!/usr/bin/env bash
#
# e2e-smoke.sh — end-to-end smoke test for the data-science-harness v1 vertical slice.
#
# Exercises the core loop that the planner skills + datalad doer drive, and ASSERTS the
# provenance outcomes at each step:
#
#   new-project        -> YODA + text2git dataset, plain BIDS scaffold, project.yaml log
#   propose-comparison -> analysis on its own cmp/* branch + log entry
#   run-comparison     -> provenanced run (inputs/cmd/outputs recorded, replayable)
#   containers-run     -> provenanced run inside a container, image hash annexed + recorded
#   checkpoint         -> clean, described snapshot
#   distributability   -> push to a sibling, clone it independently, `datalad get` the result
#
# This runs the raw DataLad commands the doer would execute (the skills themselves are agent
# prompts). The containers-run step exercises the extra provenance a plain `datalad run` cannot:
# it registers a container and records the container image's annex key (content hash) in the run
# commit, so `datalad rerun` re-fetches the exact image. That block is GATED — it self-skips
# unless the datalad-container extension, an apptainer/singularity runtime, and a .sif are all
# present. Provide an image via DSH_SIF=/path/to.sif; otherwise the block builds hello-world.sif
# from the local Docker `hello-world:latest` image (via `docker save` -> docker-archive://,
# because apptainer 1.1.x speaks too old a Docker API to read the daemon directly).
#
# Requirements: git, python3, and a DataLad whose git-annex is >= 10.20230126.
# Usage: tests/e2e-smoke.sh [workdir]     (workdir defaults to a fresh mktemp dir)

set -euo pipefail

# ---------------------------------------------------------------------------- helpers
PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
assert()      { if eval "$2"; then ok "$1"; else bad "$1  [check: $2]"; fi; }
assert_grep() { if grep -qE "$2" "$3" 2>/dev/null; then ok "$1"; else bad "$1  [/$2/ not in $3]"; fi; }

WORKDIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/dsh-e2e.XXXXXX")}"
cleanup() { chmod -R u+w "$WORKDIR" 2>/dev/null || true; rm -rf "$WORKDIR"; }
trap cleanup EXIT
mkdir -p "$WORKDIR"
REPO="$(cd "$(dirname "$0")/.." && pwd)"   # repo root, for schemas/ + examples/

# ---------------------------------------------------------- preflight: tool availability
command -v datalad >/dev/null || { echo "SKIP: datalad not on PATH"; exit 2; }
command -v python3 >/dev/null || { echo "SKIP: python3 not on PATH"; exit 2; }
GA_VER=$(git-annex version 2>/dev/null | sed -n 's/^git-annex version: 10\.\([0-9]\{8\}\).*/\1/p')
if [ -z "${GA_VER:-}" ] || [ "$GA_VER" -lt 20230126 ]; then
  echo "SKIP: need git-annex >= 10.20230126 for modern DataLad (found: $(git-annex version 2>/dev/null | head -1))"
  exit 2
fi
echo "Using $(datalad --version 2>&1 | head -1) / git-annex 10.${GA_VER}"
echo "Workdir: $WORKDIR"; echo

DS="$WORKDIR/demo-study"

# =========================================================== M2: new-project
echo "## new-project (create YODA+text2git dataset, BIDS scaffold, project.yaml)"
datalad create -c text2git -c yoda --description "e2e demo study" "$DS" >/dev/null
cd "$DS"

cat > dataset_description.json <<'JSON'
{ "Name": "e2e demo study", "BIDSVersion": "1.9.0", "DatasetType": "raw" }
JSON
printf 'participant_id\tgroup\tage\n'                       > participants.tsv
printf 'sub-01\tA\t24\nsub-02\tB\t31\nsub-03\tA\t28\nsub-04\tB\t35\n' >> participants.tsv
printf 'code/\noutputs/\nderivatives/\ncontainers/\n'       > .bidsignore
mkdir -p derivatives && touch derivatives/.gitkeep
mkdir -p containers && printf 'name: demo-env\ndependencies: [python=3.10]\n' > containers/environment.yml

cat > code/stats.py <<'PY'
import csv, json, os, statistics as st
rows = list(csv.DictReader(open("participants.tsv"), delimiter="\t"))
a = [float(r["age"]) for r in rows if r["group"] == "A"]
b = [float(r["age"]) for r in rows if r["group"] == "B"]
res = {"n_A": len(a), "n_B": len(b), "mean_A": st.mean(a),
       "mean_B": st.mean(b), "diff": st.mean(b) - st.mean(a)}
os.makedirs("derivatives/cmp-group-diff-y", exist_ok=True)
json.dump(res, open("derivatives/cmp-group-diff-y/result.json", "w"), indent=2)
print("wrote", res)
PY

cat > project.yaml <<'YAML'
project:
  name: demo-study
  description: "e2e demo study"
  created: 2026-07-10T14:30:00Z
  dataset_root: .
  stack: python
products: []
obligations: []
log:
  - { ts: 2026-07-10T14:30:00Z, op: new-project, stage: initialize, note: "scaffold", branch: main }
YAML

datalad save -m "scaffold YODA+BIDS project demo-study" >/dev/null

assert "dataset created (.datalad/ present)"          '[ -d .datalad ]'
assert "project.yaml is a real writable git file (not an annex symlink)" \
       '[ -f project.yaml ] && [ -w project.yaml ] && [ ! -L project.yaml ]'
assert "participants.tsv kept in git (text2git, not annexed)" '[ ! -L participants.tsv ]'
git log --oneline > "$WORKDIR/log1.txt"
assert_grep "scaffold commit recorded" "scaffold YODA\+BIDS" "$WORKDIR/log1.txt"

# ledger schema validation (Phase 1) — gated on pyyaml + jsonschema
python3 "$REPO/schemas/validate-ledger.py" project.yaml > "$WORKDIR/ledger.txt" 2>&1; LRC=$?
if [ "$LRC" -eq 2 ]; then
  echo "  SKIP: ledger schema validation — $(cat "$WORKDIR/ledger.txt")"
else
  assert "scaffolded project.yaml validates against schemas/project.schema.json" "[ $LRC -eq 0 ]"
  python3 "$REPO/schemas/validate-ledger.py" "$REPO/examples/project.yaml" >/dev/null 2>&1; ERC=$?
  assert "examples/project.yaml validates against schemas/project.schema.json" "[ $ERC -eq 0 ]"
fi

# =========================================================== M3: propose-comparison
echo; echo "## propose-comparison (named cmp/* branch + log entry)"
git checkout -q -b cmp/group-diff-y
printf '  - { ts: 2026-07-10T15:05:00Z, op: propose-comparison, stage: analyze, note: "group diff", branch: cmp/group-diff-y }\n' >> project.yaml
datalad save -m "propose-comparison: cmp/group-diff-y" >/dev/null
assert "on comparison branch cmp/group-diff-y" '[ "$(git rev-parse --abbrev-ref HEAD)" = "cmp/group-diff-y" ]'

# =========================================================== M3: run-comparison
echo; echo "## run-comparison (provenanced datalad run)"
datalad run -m "run cmp/group-diff-y: group age difference" \
  -i participants.tsv \
  -o derivatives/cmp-group-diff-y/result.json \
  "python3 code/stats.py" >/dev/null
RUNSHA=$(git rev-parse --short HEAD)
printf '  - { ts: 2026-07-10T15:40:00Z, op: run-comparison, stage: analyze, note: "commit %s", branch: cmp/group-diff-y }\n' "$RUNSHA" >> project.yaml
datalad save -m "run-comparison: log entry for $RUNSHA" >/dev/null

assert "result.json produced"       '[ -f derivatives/cmp-group-diff-y/result.json ]'
assert "computed diff == 7.0"       'grep -q "\"diff\": 7.0" derivatives/cmp-group-diff-y/result.json'
git show -s --format='%B' "$RUNSHA" > "$WORKDIR/runbody.txt"
assert_grep "run recorded as DATALAD RUNCMD" "DATALAD RUNCMD"     "$WORKDIR/runbody.txt"
assert_grep "provenance captured the command" '"cmd": "python3 code/stats.py"' "$WORKDIR/runbody.txt"
assert_grep "provenance captured inputs"      '"inputs"'          "$WORKDIR/runbody.txt"
assert_grep "provenance captured outputs"     '"outputs"'         "$WORKDIR/runbody.txt"

# =========================================================== containers-run (image-capture)
echo; echo "## containers-run (container image-capture provenance) [gated]"
# The command is `datalad containers-run` (plural) from the datalad-container extension. It
# registers a container, annexes the image, and records the image's annex key in the run commit
# — the extra provenance a bare `datalad run` cannot capture.
CR_RUNTIME="$(command -v apptainer || command -v singularity || true)"
SIF=""
if [ -n "${DSH_SIF:-}" ] && [ -f "$DSH_SIF" ]; then
  SIF="$DSH_SIF"
elif [ -n "$CR_RUNTIME" ] && command -v docker >/dev/null && docker image inspect hello-world:latest >/dev/null 2>&1; then
  # apptainer 1.1.x can't read the modern Docker daemon (API too old) -> go via docker-archive (offline)
  docker save hello-world:latest -o "$WORKDIR/hello-world.tar" >/dev/null 2>&1 \
    && "$CR_RUNTIME" build "$WORKDIR/hello-world.sif" "docker-archive://$WORKDIR/hello-world.tar" >/dev/null 2>&1 \
    && SIF="$WORKDIR/hello-world.sif"
fi
if ! datalad containers-add --help >/dev/null 2>&1; then
  echo "  SKIP: datalad-container extension not installed (no containers-add/containers-run)"
elif [ -z "$CR_RUNTIME" ]; then
  echo "  SKIP: no apptainer/singularity runtime on PATH"
elif [ -z "$SIF" ] || [ ! -f "$SIF" ]; then
  echo "  SKIP: no .sif available (set DSH_SIF=/path/to.sif, or make hello-world:latest available to Docker)"
else
  echo "  using runtime $(basename "$CR_RUNTIME"), image $SIF"
  datalad containers-add demo-env --url "$SIF" \
    --call-fmt "$(basename "$CR_RUNTIME") exec {img} {cmd}" >/dev/null 2>&1
  # hello-world has no shell/python; the outer shell redirects the banner to a tracked output file
  datalad containers-run -m "containers-run: hello banner (image-capture demo)" \
    --container-name demo-env -o container-hello.txt \
    "/hello > container-hello.txt" >/dev/null 2>&1
  datalad containers-list > "$WORKDIR/containers.txt" 2>/dev/null || true
  git show -s --format='%B' HEAD > "$WORKDIR/crbody.txt"

  assert_grep "container 'demo-env' registered"          "demo-env"        "$WORKDIR/containers.txt"
  assert "container image annexed (content hash captured, not a plain file)" \
         '[ -L .datalad/environments/demo-env/image ]'
  assert_grep "run recorded as DATALAD RUNCMD"           "DATALAD RUNCMD"  "$WORKDIR/crbody.txt"
  assert_grep "provenance captured the container image"  "\.datalad/environments/demo-env/image" "$WORKDIR/crbody.txt"
  assert_grep "image recorded as a run input (extra_inputs)" '"extra_inputs"' "$WORKDIR/crbody.txt"
  assert "container ran (banner output produced)" '[ -f container-hello.txt ]'
  assert_grep "container output is the hello-world banner" "Hello from Docker" "container-hello.txt"
fi

# =========================================================== M4: checkpoint
echo; echo "## checkpoint (clean described snapshot)"
echo "session notes" > code/NOTES.md
datalad save -m "checkpoint: session notes" >/dev/null
assert "working tree clean after checkpoint" '[ -z "$(git status --porcelain)" ]'
# ledger stayed schema-valid through all appended log entries (Phase 1)
python3 "$REPO/schemas/validate-ledger.py" project.yaml >/dev/null 2>&1; FRC=$?
[ "$FRC" -eq 2 ] || assert "project.yaml still schema-valid after log appends" "[ $FRC -eq 0 ]"

# =========================================================== manage-product (Phase 2: products[])
echo; echo "## manage-product (group a comparison into a product) [gated on pyyaml]"
# Simulates what analyze/manage-product records: upsert a product into the ledger's products[]
# registry grouping the cmp/group-diff-y comparison, then re-validate against the schema.
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  SKIP: pyyaml not available"
else
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
doc.setdefault("products", []).append({
    "id": "main-paper", "kind": "paper", "title": "X reduces Y",
    "status": "in-progress", "comparisons": ["cmp/group-diff-y"],
    "outputs": ["derivatives/cmp-group-diff-y/result.json"],
    "dois": [], "relations": [],
})
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  datalad save -m "manage-product: main-paper groups cmp/group-diff-y" >/dev/null
  python3 "$REPO/schemas/validate-ledger.py" project.yaml >/dev/null 2>&1; MRC=$?
  assert "ledger valid after grouping a product" "[ $MRC -eq 0 ]"
  assert_grep "product 'main-paper' recorded in products[]" "id: main-paper"      "project.yaml"
  assert_grep "product groups the comparison branch"        "cmp/group-diff-y"    "project.yaml"
  assert "product save recorded as a tracked commit" \
         'git log --oneline -1 | grep -q "manage-product"'
fi

# =========================================================== Distributability (D)
echo; echo "## distributability (push to sibling -> clone -> datalad get)"
SIB="$WORKDIR/sibling"; CLONE="$WORKDIR/clone"
datalad create-sibling -s localsib "$SIB" >/dev/null 2>&1
datalad push --to localsib >/dev/null 2>&1
# NB: dump to a file and grep the file — piping into `grep -q` makes grep exit on first match,
# which SIGPIPEs the producer and, under `set -o pipefail`, falsely fails the assertion.
datalad siblings > "$WORKDIR/sibs.txt" 2>/dev/null || true
assert_grep "sibling 'localsib' registered" "localsib" "$WORKDIR/sibs.txt"
datalad clone "$SIB" "$CLONE" >/dev/null 2>&1
# the run commit lives on cmp/group-diff-y; check all distributed refs, not just default HEAD
git -C "$CLONE" log --oneline --all > "$WORKDIR/clonelog.txt"
assert_grep "independent clone has the run history (across all pushed branches)" \
            "DATALAD RUNCMD" "$WORKDIR/clonelog.txt"
git -C "$CLONE" checkout -q cmp/group-diff-y
datalad -C "$CLONE" get derivatives/cmp-group-diff-y/result.json >/dev/null 2>&1
assert "annexed result retrievable from sibling (datalad get)" \
       'grep -q "\"diff\": 7.0" "$CLONE/derivatives/cmp-group-diff-y/result.json"'

# =========================================================== summary
echo; echo "==================================================="
echo "e2e-smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
echo "OK — STAMPED S/T/A/M/D loop verified (P/E via datalad run + containers-run image-capture when gated deps present)"
