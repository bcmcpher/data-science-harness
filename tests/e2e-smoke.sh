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
# Requirements: git (with user.name/user.email set — DataLad needs an identity and `push`
# fails without one), python3, and a DataLad whose git-annex is >= 10.20230126.
#
# Exit codes: 0 = all assertions passed, 1 = a failure, 2 = cannot run here (missing tool or
# unset git identity). Setup commands go through `step`, which surfaces the failing command
# and its output; anything unwrapped is caught by an ERR trap that reports the line.
# Usage: tests/e2e-smoke.sh [workdir]     (workdir defaults to a fresh mktemp dir)

set -Eeuo pipefail

# ---------------------------------------------------------------------------- helpers
PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
assert()      { if eval "$2"; then ok "$1"; else bad "$1  [check: $2]"; fi; }
assert_grep() { if grep -qE "$2" "$3" 2>/dev/null; then ok "$1"; else bad "$1  [/$2/ not in $3]"; fi; }
# The ledger validator exits 2 when pyyaml/jsonschema are absent. That is a skip, not a failure:
# only the first validation site handled it, so a missing jsonschema (with pyyaml present, which
# passes the `import yaml` gate on the blocks below) produced a wall of spurious FAILs.
skip() { printf '  SKIP: %s\n' "$1"; }
assert_ledger() { if [ "$2" -eq 2 ]; then skip "$1 — ledger validator dependency absent"; else assert "$1" "[ $2 -eq 0 ]"; fi; }

WORKDIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/dsh-e2e.XXXXXX")}"
cleanup() { chmod -R u+w "$WORKDIR" 2>/dev/null || true; rm -rf "$WORKDIR"; }
trap cleanup EXIT
mkdir -p "$WORKDIR"
REPO="$(cd "$(dirname "$0")/.." && pwd)"   # repo root, for schemas/ + examples/
STEP_LOG="$WORKDIR/.step-output"

# `step` wraps a state-building command (as opposed to an assertion). Setup commands used to be
# written `cmd >/dev/null 2>&1`, which meant a failure under `set -e` killed the script with the
# log ending at the last PASS and no diagnostic whatsoever — the failure mode that made a real CI
# failure undiagnosable.
#
# Captures stdout AND stderr, not just stderr: DataLad reports failures as result records on
# stdout, so a failing `datalad push` leaves stderr empty and every useful detail on the stream a
# naive wrapper throws away. Output is shown only when the command fails, so a passing run stays
# as quiet as it was before.
step() {
  local desc="$1"; shift
  local rc=0
  "$@" >"$STEP_LOG" 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '\n  \033[31mABORT\033[0m %s (exit %d)\n' "$desc" "$rc" >&2
    printf '    command: %s\n' "$*" >&2
    if [ -s "$STEP_LOG" ]; then
      printf '    output (last 25 lines):\n' >&2
      tail -n 25 "$STEP_LOG" | sed 's/^/      /' >&2
    else
      printf '    (command produced no output)\n' >&2
    fi
    exit 1
  fi
}

# Backstop for anything not wrapped in `step` — reports where the script died rather than
# stopping mid-stream in silence.
on_err() {
  local rc=$? line="${1:-?}"
  printf '\n  \033[31mABORT\033[0m unhandled failure at %s line %s (exit %d)\n' \
         "$(basename "$0")" "$line" "$rc" >&2
  printf '    Re-run with: bash -x %s\n' "$0" >&2
  exit "$rc"
}
trap 'on_err $LINENO' ERR

# `rc_of CMD...` runs a command whose EXIT CODE is the thing being asserted, and echoes that code
# instead of letting `set -e` abort. `cmd; RC=$?` does NOT work under `set -e`: the shell exits on
# the failing command before the assignment runs, which silently made every exit-2 skip path below
# unreachable.
rc_of() {
  local rc=0
  "$@" >/dev/null 2>&1 || rc=$?
  printf '%s' "$rc"
}

# ---------------------------------------------------------- preflight: tool availability
command -v datalad >/dev/null || { echo "SKIP: datalad not on PATH"; exit 2; }
command -v python3 >/dev/null || { echo "SKIP: python3 not on PATH"; exit 2; }
GA_VER=$(git-annex version 2>/dev/null | sed -n 's/^git-annex version: 10\.\([0-9]\{8\}\).*/\1/p')
if [ -z "${GA_VER:-}" ] || [ "$GA_VER" -lt 20230126 ]; then
  echo "SKIP: need git-annex >= 10.20230126 for modern DataLad (found: $(git-annex version 2>/dev/null | head -1))"
  exit 2
fi
if [ -z "$(git config --get user.email || true)" ] || [ -z "$(git config --get user.name || true)" ]; then
  echo "SKIP: git user.name/user.email are unset. DataLad warns on every invocation without them" >&2
  echo "      and \`datalad push\` fails, with the failure surfacing far from its cause. Set:" >&2
  echo "        git config --global user.name  'Your Name'" >&2
  echo "        git config --global user.email 'you@example.org'" >&2
  exit 2
fi
# stdout only: DataLad writes warnings to stderr, so `2>&1 | head -1` would report a warning as
# the version string — which is exactly what a runner with no git identity produced.
DL_VER="$(datalad --version 2>/dev/null | head -1)"
echo "Using ${DL_VER:-datalad <unknown>} / git-annex 10.${GA_VER}"   # DL_VER already reads "datalad X.Y.Z"
echo "Workdir: $WORKDIR"; echo

DS="$WORKDIR/demo-study"

# =========================================================== M2: new-project
echo "## new-project (create YODA+text2git dataset, BIDS scaffold, project.yaml)"
step "create YODA+text2git dataset" \
  datalad create -c text2git -c yoda --description "e2e demo study" "$DS"
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

step "save scaffold" datalad save -m "scaffold YODA+BIDS project demo-study"

assert "dataset created (.datalad/ present)"          '[ -d .datalad ]'
assert "project.yaml is a real writable git file (not an annex symlink)" \
       '[ -f project.yaml ] && [ -w project.yaml ] && [ ! -L project.yaml ]'
assert "participants.tsv kept in git (text2git, not annexed)" '[ ! -L participants.tsv ]'
git log --oneline > "$WORKDIR/log1.txt"
assert_grep "scaffold commit recorded" "scaffold YODA\+BIDS" "$WORKDIR/log1.txt"

# ledger schema validation (Phase 1) — gated on pyyaml + jsonschema
LRC=0; python3 "$REPO/schemas/validate-ledger.py" project.yaml > "$WORKDIR/ledger.txt" 2>&1 || LRC=$?
if [ "$LRC" -eq 2 ]; then
  echo "  SKIP: ledger schema validation — $(cat "$WORKDIR/ledger.txt")"
else
  assert_ledger "scaffolded project.yaml validates against schemas/project.schema.json" "$LRC"
  ERC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" "$REPO/examples/project.yaml")
  assert_ledger "examples/project.yaml validates against schemas/project.schema.json" "$ERC"
fi

# =========================================================== M3: propose-comparison
echo; echo "## propose-comparison (named cmp/* branch + log entry)"
step "branch cmp/group-diff-y" git checkout -q -b cmp/group-diff-y
printf '  - { ts: 2026-07-10T15:05:00Z, op: propose-comparison, stage: analyze, note: "group diff", branch: cmp/group-diff-y }\n' >> project.yaml
step "save propose-comparison" datalad save -m "propose-comparison: cmp/group-diff-y"
assert "on comparison branch cmp/group-diff-y" '[ "$(git rev-parse --abbrev-ref HEAD)" = "cmp/group-diff-y" ]'

# =========================================================== M3: run-comparison
echo; echo "## run-comparison (provenanced datalad run)"
step "provenanced datalad run" \
  datalad run -m "run cmp/group-diff-y: group age difference" \
  -i participants.tsv \
  -o derivatives/cmp-group-diff-y/result.json \
  "python3 code/stats.py"
RUNSHA=$(git rev-parse --short HEAD)
printf '  - { ts: 2026-07-10T15:40:00Z, op: run-comparison, stage: analyze, note: "commit %s", branch: cmp/group-diff-y }\n' "$RUNSHA" >> project.yaml
step "save run-comparison log entry" datalad save -m "run-comparison: log entry for $RUNSHA"

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
  step "containers-add demo-env" \
    datalad containers-add demo-env --url "$SIF" \
    --call-fmt "$(basename "$CR_RUNTIME") exec {img} {cmd}"
  # hello-world has no shell/python; the outer shell redirects the banner to a tracked output file
  step "containers-run demo-env" \
    datalad containers-run -m "containers-run: hello banner (image-capture demo)" \
    --container-name demo-env -o container-hello.txt \
    "/hello > container-hello.txt"
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
step "save checkpoint" datalad save -m "checkpoint: session notes"
assert "working tree clean after checkpoint" '[ -z "$(git status --porcelain)" ]'
# ledger stayed schema-valid through all appended log entries (Phase 1)
FRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
assert_ledger "project.yaml still schema-valid after log appends" "$FRC"

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
  step "save manage-product" datalad save -m "manage-product: main-paper groups cmp/group-diff-y"
  MRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after grouping a product" "$MRC"
  assert_grep "product 'main-paper' recorded in products[]" "id: main-paper"      "project.yaml"
  assert_grep "product groups the comparison branch"        "cmp/group-diff-y"    "project.yaml"
  assert "product save recorded as a tracked commit" \
         'git log --oneline -1 | grep -q "manage-product"'
fi

# =========================================================== govern/obligations (Phase 3)
echo; echo "## govern (preregister -> obligations[], then resolve) [gated on pyyaml]"
# Simulates govern/preregister recording a pending confirmatory obligation, then govern/obligations
# resolving it forward to met — exercising the ledger obligations[] registry (add + status change).
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  SKIP: pyyaml not available"
else
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
doc.setdefault("obligations", []).append({
    "id": "prereg-group-diff-y", "kind": "preregistration",
    "description": "H1 group difference in Y; frozen for cmp/group-diff-y",
    "due": "2026-09-01", "status": "pending", "ref": "https://osf.io/xxxxx"})
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  step "save preregister" datalad save -m "preregister cmp/group-diff-y: pending obligation"
  ORC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after adding a pending obligation" "$ORC"
  assert_grep "confirmatory obligation recorded as pending" "status: pending" "project.yaml"
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
for ob in doc.get("obligations", []):
    if ob.get("id") == "prereg-group-diff-y":
        ob["status"] = "met"          # forward-only resolution; never deleted
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  step "save obligation resolution" datalad save -m "obligations: met prereg-group-diff-y"
  ORC2=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after resolving obligation to met" "$ORC2"
  assert_grep "obligation resolved forward to met"        "status: met" "project.yaml"
fi

# =========================================================== project/people (Phase 5: contributors[])
echo; echo "## project/people (credit a contributor w/ CRediT roles) [gated on pyyaml]"
# Simulates project/people upserting a contributor into the ledger contributors[] registry.
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  SKIP: pyyaml not available"
else
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
doc.setdefault("contributors", []).append({
    "name": "Ada Researcher",
    "orcid": "https://orcid.org/0000-0002-1825-0097",
    "roles": ["Conceptualization", "Formal analysis", "Writing – original draft"]})
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False, allow_unicode=True)
PY
  step "save contributor credit" datalad save -m "people: credit Ada Researcher"
  PRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after crediting a contributor" "$PRC"
  assert_grep "contributor recorded with an ORCID" "orcid:" "project.yaml"
fi

# =========================================================== dataset-release (Phase 2: tag+status)
echo; echo "## dataset-release (version + BIDS CHANGES + datalad version tag) [gated on pyyaml]"
# Simulates disseminate/dataset-release: write a CHANGES entry, tag the state via datalad, and
# flip the product to released. DOI minting is the gated archive-doer add-on (no creds here).
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  SKIP: pyyaml not available"
else
  REL_VER=0.1.0
  printf '%s %s\n  - Initial release of main-paper outputs\n' "$REL_VER" "$(date +%F)" > CHANGES
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
for prod in doc.get("products", []):
    if prod.get("id") == "main-paper":
        prod["status"] = "released"      # DOI stays unminted (no archive credentials)
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  step "save release + version tag" \
    datalad save -m "release main-paper v$REL_VER" --version-tag "v$REL_VER"
  RRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after release (status -> released)" "$RRC"
  assert "BIDS CHANGES entry written"                      '[ -s CHANGES ]'
  git tag -l > "$WORKDIR/tags.txt"
  assert_grep "immutable version tag created via datalad save --version-tag" "v0\.1\.0" "$WORKDIR/tags.txt"
  assert_grep "product marked released in ledger"          "status: released"  "project.yaml"
fi

# =========================================================== link-outputs (Phase 2 capstone)
echo; echo "## link-outputs (cross-link multiple products via DataCite relations) [gated on pyyaml]"
# The multi-product endgame: a second product (as a prior manage-product would create), then
# DataCite RelatedIdentifier links (with inverses) tying the two into one linked compendium.
if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "  SKIP: pyyaml not available"
else
  python3 - project.yaml <<'PY'
import sys, yaml
path = sys.argv[1]
with open(path) as fh:
    doc = yaml.safe_load(fh)
prods = doc.setdefault("products", [])
by_id = {p["id"]: p for p in prods}
if "data-release" not in by_id:
    dr = {"id": "data-release", "kind": "dataset", "title": "Cohort BIDS dataset",
          "status": "planned", "comparisons": [], "outputs": ["."], "dois": [], "relations": []}
    prods.append(dr); by_id["data-release"] = dr
# DataCite RelatedIdentifier links + their inverses (internal product-to-product)
by_id["main-paper"].setdefault("relations", []).append({"relation": "IsSupplementedBy", "target": "data-release"})
by_id["data-release"].setdefault("relations", []).append({"relation": "IsSupplementTo", "target": "main-paper"})
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  step "save link-outputs" datalad save -m "link-outputs: main-paper <-> data-release (DataCite relations)"
  KRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after cross-linking products" "$KRC"
  NPROD=$(python3 -c 'import yaml; print(len(yaml.safe_load(open("project.yaml")).get("products",[])))')
  assert "ledger holds multiple products (>=2)"            "[ $NPROD -ge 2 ]"
  assert_grep "forward DataCite relation recorded (IsSupplementedBy)" "IsSupplementedBy" "project.yaml"
  assert_grep "inverse DataCite relation recorded (IsSupplementTo)"   "IsSupplementTo"   "project.yaml"
fi

# =========================================================== Distributability (D)
echo; echo "## distributability (push to sibling -> clone -> datalad get)"
SIB="$WORKDIR/sibling"; CLONE="$WORKDIR/clone"
step "create sibling 'localsib'" datalad create-sibling -s localsib "$SIB"
step "push to sibling" datalad push --to localsib
# NB: dump to a file and grep the file — piping into `grep -q` makes grep exit on first match,
# which SIGPIPEs the producer and, under `set -o pipefail`, falsely fails the assertion.
datalad siblings > "$WORKDIR/sibs.txt" 2>/dev/null || true
assert_grep "sibling 'localsib' registered" "localsib" "$WORKDIR/sibs.txt"
step "clone the sibling independently" datalad clone "$SIB" "$CLONE"
# the run commit lives on cmp/group-diff-y; check all distributed refs, not just default HEAD
step "read the clone's history" \
  bash -c 'git -C "$1" log --oneline --all > "$2"' _ "$CLONE" "$WORKDIR/clonelog.txt"
assert_grep "independent clone has the run history (across all pushed branches)" \
            "DATALAD RUNCMD" "$WORKDIR/clonelog.txt"
step "check out cmp/group-diff-y in the clone" git -C "$CLONE" checkout -q cmp/group-diff-y
step "datalad get the annexed result" \
  datalad -C "$CLONE" get derivatives/cmp-group-diff-y/result.json
assert "annexed result retrievable from sibling (datalad get)" \
       'grep -q "\"diff\": 7.0" "$CLONE/derivatives/cmp-group-diff-y/result.json"'

# =========================================================== summary
echo; echo "==================================================="
echo "e2e-smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
echo "OK — STAMPED S/T/A/M/D loop verified (P/E via datalad run + containers-run image-capture when gated deps present)"
