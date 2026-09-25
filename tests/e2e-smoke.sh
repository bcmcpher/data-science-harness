#!/usr/bin/env bash
#
# e2e-smoke.sh — end-to-end smoke test for the data-science-harness v1 vertical slice.
#
# Exercises the core loop that the planner skills drive, running DataLad natively, and ASSERTS
# the provenance outcomes at each step:
#
#   new-project        -> YODA + text2git dataset, plain BIDS scaffold, project.yaml state
#   propose-comparison -> analysis on its own cmp/* branch, recorded by its commit
#   run-comparison     -> provenanced run (inputs/cmd/outputs recorded, replayable)
#   containers-run     -> provenanced run inside a container, image hash annexed + recorded
#   checkpoint         -> clean, described snapshot
#   distributability   -> push to a sibling, clone it independently, `datalad get` the result
#   activity history   -> every harness commit carries DSH-Op/DSH-Stage lines, read via dsh-log
#
# This runs the raw DataLad commands the planners run (the skills themselves are agent prompts),
# with the single-message `DSH-*` form they use. The containers-run step exercises the extra provenance a plain `datalad run` cannot:
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
# dsh <op> <stage> <subject> [extra DSH line]... — a harness commit message: one string, subject,
# blank line, DSH lines. Passed as a single -m, because DataLad keeps only the last of several.
dsh() { local op=$1 stage=$2 subj=$3; shift 3; printf '%s\n\nDSH-Op: %s\nDSH-Stage: %s' "$subj" "$op" "$stage"; for l in "$@"; do printf '\n%s' "$l"; done; }

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
YAML

step "save scaffold" datalad save -m "$(dsh new-project initialize "scaffold YODA+BIDS project demo-study — start the study")"

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
echo; echo "## propose-comparison (named cmp/* branch, recorded by its commit)"
step "branch cmp/group-diff-y" git checkout -q -b cmp/group-diff-y
printf '# cmp/group-diff-y\n\nH: group B is older than group A (exploratory).\n' > code/cmp-group-diff-y.md
step "save propose-comparison" datalad save -m "$(dsh propose-comparison analyze "propose cmp/group-diff-y — group age difference, exploratory")"
assert "on comparison branch cmp/group-diff-y" '[ "$(git rev-parse --abbrev-ref HEAD)" = "cmp/group-diff-y" ]'

# =========================================================== M3: run-comparison
echo; echo "## run-comparison (provenanced datalad run)"
step "provenanced datalad run" \
  datalad run -m "$(dsh run-comparison analyze "run cmp/group-diff-y — group age difference")" \
  -i participants.tsv \
  -o derivatives/cmp-group-diff-y/result.json \
  "python3 code/stats.py"
RUNSHA=$(git rev-parse --short HEAD)

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
    datalad containers-run -m "$(dsh run-comparison analyze "hello banner — image-capture demo" "DSH-Binding: containers/$(basename "$CR_RUNTIME")@unknown")" \
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
step "save checkpoint" datalad save -m "$(dsh checkpoint analyze "session notes — end of session")"
assert "working tree clean after checkpoint" '[ -z "$(git status --porcelain)" ]'
# ledger stayed schema-valid with no log: key (activity lives in the commits)
FRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
assert_ledger "project.yaml schema-valid with no log: key" "$FRC"
assert "no skill wrote a ledger log" '! grep -q "^log:" project.yaml'

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
  step "save manage-product" datalad save -m "$(dsh manage-product analyze "group cmp/group-diff-y into main-paper — first product" "DSH-Product: main-paper")"
  MRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after grouping a product" "$MRC"
  assert_grep "product 'main-paper' recorded in products[]" "id: main-paper"      "project.yaml"
  assert_grep "product groups the comparison branch"        "cmp/group-diff-y"    "project.yaml"
  assert "product save recorded as a tracked commit" \
         'git log -1 --format=%B | grep -q "^DSH-Op: manage-product$"'
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
  step "save preregister" datalad save -m "$(dsh preregister govern "register cmp/group-diff-y — freeze the confirmatory spec" "DSH-Obligation: prereg-group-diff-y opened")"
  ORC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after adding a pending obligation" "$ORC"
  assert_grep "confirmatory obligation recorded as pending" "status: pending" "project.yaml"
  OBSHA=$(git rev-parse --short HEAD)
  python3 - project.yaml "$OBSHA" <<'PY'
import sys, yaml
path, sha = sys.argv[1], sys.argv[2]
with open(path) as fh:
    doc = yaml.safe_load(fh)
for ob in doc.get("obligations", []):
    if ob.get("id") == "prereg-group-diff-y":
        ob["status"] = "met"        # forward-only resolution; never deleted
        ob["resolved_by"] = sha     # the recorded action that met it, not an assertion
with open(path, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  step "save obligation resolution" datalad save -m "$(dsh obligations govern "resolve prereg-group-diff-y — registered run recorded" "DSH-Obligation: prereg-group-diff-y resolved")"
  ORC2=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after resolving obligation to met" "$ORC2"
  assert_grep "obligation resolved forward to met"        "status: met" "project.yaml"
  assert_grep "resolution names the recorded action"      "resolved_by: $OBSHA" "project.yaml"
  # The schema forbids `met` without `resolved_by` — a status flip that records nothing is the
  # failure the obligations registry exists to prevent. Prove the constraint bites instead of
  # trusting it: strip the field in a throwaway copy and require a rejection.
  python3 - project.yaml "$WORKDIR/ledger-met-no-evidence.yaml" <<'PY'
import sys, yaml
src, dst = sys.argv[1], sys.argv[2]
with open(src) as fh:
    doc = yaml.safe_load(fh)
for ob in doc.get("obligations", []):
    ob.pop("resolved_by", None)
with open(dst, "w") as fh:
    yaml.safe_dump(doc, fh, sort_keys=False)
PY
  NORC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" "$WORKDIR/ledger-met-no-evidence.yaml")
  if [ "$NORC" -eq 2 ]; then
    skip "a met obligation with no resolved_by is rejected — ledger validator dependency absent"
  else
    assert "a met obligation with no resolved_by is rejected" "[ $NORC -eq 1 ]"
  fi
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
  step "save contributor credit" datalad save -m "$(dsh people manage "credit Ada Researcher — CRediT roles and ORCID")"
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
    datalad save -m "$(dsh dataset-release disseminate "release main-paper v$REL_VER — first versioned state" "DSH-Product: main-paper")" --version-tag "v$REL_VER"
  RRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after release (status -> released)" "$RRC"
  assert "BIDS CHANGES entry written"                      '[ -s CHANGES ]'
  git tag -l > "$WORKDIR/tags.txt"
  assert_grep "immutable version tag created via datalad save --version-tag" "v0\.1\.0" "$WORKDIR/tags.txt"
  assert_grep "product marked released in ledger"          "status: released"  "project.yaml"
  NDOI=$(python3 -c 'import yaml; print(sum(len(p.get("dois") or []) for p in yaml.safe_load(open("project.yaml")).get("products", []) if p.get("id") == "main-paper"))')
  assert "release recorded without a DOI (unminted, none fabricated)" "[ $NDOI -eq 0 ]"
fi

# =========================================================== archive readiness gate
echo; echo "## archive readiness gate (unminted without credentials)"
# The archive doer is an agent prompt, so this asserts the deterministic step it runs before any
# deposit: the toolbox's presence check. Without credentials it must refuse and name what is
# missing; with a credential present it must pass without echoing the secret.
READY="$REPO/plugins/archive-cli/scripts/check-readiness.sh"
URC=$(rc_of env -u ZENODO_TOKEN bash "$READY" zenodo)
assert "zenodo readiness exits 1 without ZENODO_TOKEN" "[ $URC -eq 1 ]"
env -u ZENODO_TOKEN bash "$READY" zenodo > "$WORKDIR/ready.txt" 2>&1 || true
assert_grep "readiness reports result: unminted"      "^result: unminted$"     "$WORKDIR/ready.txt"
assert_grep "readiness names the missing credential"  "^missing: ZENODO_TOKEN$" "$WORKDIR/ready.txt"
PRC=$(rc_of env ZENODO_TOKEN=dsh-sentinel-secret bash "$READY" zenodo)
assert "zenodo readiness exits 0 with a token present" "[ $PRC -eq 0 ]"
env ZENODO_TOKEN=dsh-sentinel-secret bash "$READY" zenodo > "$WORKDIR/ready-ok.txt" 2>&1 || true
assert "readiness never prints the credential value" '! grep -q dsh-sentinel-secret "$WORKDIR/ready-ok.txt"'
BRC=$(rc_of bash "$READY" figshare)
assert "unknown backend is a usage error (exit 2)" "[ $BRC -eq 2 ]"

# The credentialed branch publishes a real record, so it runs only against the Zenodo sandbox and
# only when DSH_ZENODO_SANDBOX_TOKEN is set. Sandbox DOIs carry the 10.5072 test prefix and resolve
# nowhere public, so the assertion checks the prefix rather than resolution. The token goes through a
# header file so a failing `step` cannot print it in its command echo.
if [ -z "${DSH_ZENODO_SANDBOX_TOKEN:-}" ]; then
  echo "  SKIP: Zenodo sandbox deposit (set DSH_ZENODO_SANDBOX_TOKEN to run it)"
elif ! command -v curl >/dev/null; then
  echo "  SKIP: Zenodo sandbox deposit — curl not on PATH"
else
  ZAPI=https://sandbox.zenodo.org/api
  ZAUTH="$WORKDIR/zenodo-auth.header"
  ( umask 077; printf 'Authorization: Bearer %s\n' "$DSH_ZENODO_SANDBOX_TOKEN" > "$ZAUTH" )
  step "sandbox: create deposition" \
    curl -fsS -X POST -H @"$ZAUTH" -H 'Content-Type: application/json' -d '{}' \
         -o "$WORKDIR/zdep.json" "$ZAPI/deposit/depositions"
  ZID=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$WORKDIR/zdep.json")
  ZBUCKET=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["links"]["bucket"])' "$WORKDIR/zdep.json")
  printf 'data-science-harness e2e sandbox deposit\n' > "$WORKDIR/deposit.txt"
  step "sandbox: upload file to bucket" \
    curl -fsS -X PUT -H @"$ZAUTH" --upload-file "$WORKDIR/deposit.txt" -o /dev/null "$ZBUCKET/deposit.txt"
  python3 - "$WORKDIR/zmeta.json" <<'PY'
import json, sys
json.dump({"metadata": {
    "upload_type": "dataset",
    "title": "data-science-harness e2e sandbox deposit",
    "creators": [{"name": "Harness, Test"}],
    "description": "Created by tests/e2e-smoke.sh against the Zenodo sandbox.",
    "access_right": "open",
    "license": "cc-by-4.0",
}}, open(sys.argv[1], "w"))
PY
  step "sandbox: set metadata" \
    curl -fsS -X PUT -H @"$ZAUTH" -H 'Content-Type: application/json' --data @"$WORKDIR/zmeta.json" \
         -o /dev/null "$ZAPI/deposit/depositions/$ZID"
  step "sandbox: publish" \
    curl -fsS -X POST -H @"$ZAUTH" -o "$WORKDIR/zpub.json" "$ZAPI/deposit/depositions/$ZID/actions/publish"
  ZDOI=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("doi", ""))' "$WORKDIR/zpub.json")
  assert "sandbox publish returned a test-prefix DOI (10.5072)" '[[ "$ZDOI" == 10.5072/* ]]'
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
  step "save link-outputs" datalad save -m "$(dsh link-outputs disseminate "link main-paper and data-release — DataCite relations both ways" "DSH-Product: main-paper" "DSH-Product: data-release")"
  KRC=$(rc_of python3 "$REPO/schemas/validate-ledger.py" project.yaml)
  assert_ledger "ledger valid after cross-linking products" "$KRC"
  NPROD=$(python3 -c 'import yaml; print(len(yaml.safe_load(open("project.yaml")).get("products",[])))')
  assert "ledger holds multiple products (>=2)"            "[ $NPROD -ge 2 ]"
  assert_grep "forward DataCite relation recorded (IsSupplementedBy)" "IsSupplementedBy" "project.yaml"
  assert_grep "inverse DataCite relation recorded (IsSupplementTo)"   "IsSupplementTo"   "project.yaml"
fi

# =========================================================== activity history (dsh-log)
echo; echo "## activity history (DSH-* commit lines read back with dsh-log)"
# Activity is recorded in the commit that makes each change, not in a ledger log. dsh-log reads
# the lines from the raw body — including from run commits, where DataLad's appended record hides
# them from git's own trailer parser.
DSHLOG="$REPO/plugins/datalad-cli/scripts/dsh-log.sh"
step "read the activity history" bash -c 'sh "$1" > "$2"' _ "$DSHLOG" "$WORKDIR/dshlog.jsonl"
hist() { python3 - "$WORKDIR/dshlog.jsonl" "$1" <<'PY'
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
sys.exit(0 if eval(sys.argv[2], {"rows": rows, "ops": [r["op"] for r in rows]}) else 1)
PY
}
for op_stage in new-project:initialize propose-comparison:analyze run-comparison:analyze checkpoint:analyze; do
  assert "dsh-log: ${op_stage%%:*} recorded with DSH-Stage ${op_stage#*:}" \
         "hist 'any(r[\"op\"] == \"${op_stage%%:*}\" and r[\"stage\"] == \"${op_stage#*:}\" for r in rows)'"
done
assert "dsh-log: the run commit is read past its run record (run: true)" \
       "hist 'any(r[\"op\"] == \"run-comparison\" and r[\"run\"] and r[\"sha\"].startswith(\"$(git rev-parse "$RUNSHA")\"[:7]) for r in rows)'"
assert "git's trailer parser misses the run commit's DSH lines (why dsh-log parses bodies)" \
       '[ -z "$(git log -1 --format="%(trailers:key=DSH-Op)" "$RUNSHA")" ]'
assert "dsh-log: every harness commit has exactly one op" "hist 'all(r[\"op\"] for r in rows)'"
if python3 -c 'import yaml' 2>/dev/null; then
  assert "dsh-log: product and obligation lines recorded" \
         "hist '\"main-paper\" in sum((r[\"product\"] for r in rows), []) and \"prereg-group-diff-y resolved\" in sum((r[\"obligation\"] for r in rows), [])'"
  assert "dsh-log: the release is recorded" "hist '\"dataset-release\" in ops'"
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

# =========================================================== liab (deployment plan, never an apply)
echo; echo "## liab (tool gate; a deploy plan touches no network) [gated on pyinfra]"
# The liab doer is an agent prompt, so this asserts the deterministic parts: the tool gate, that the
# skill behind it exists, that an unbuilt tool is a usage error, and — the important one — that the
# plan path produces a plan and performs NO network operation. The apply path is deliberately not
# tested: it needs a disposable host, and the doer states that verification gap rather than implying
# coverage.
LIABCHK="$REPO/plugins/liab-cli/scripts/check-tools.sh"
assert "liab-cli provides a pyinfra skill to invoke" \
       "[ -f '$REPO/plugins/liab-cli/skills/pyinfra/SKILL.md' ]"
PRC=$(rc_of bash "$LIABCHK" pyinfra)
assert "pyinfra gate answers available (0) or unavailable (1)" "[ $PRC -eq 0 ] || [ $PRC -eq 1 ]"
assert "liab-cli provides a forgejo skill to invoke" \
       "[ -f '$REPO/plugins/liab-cli/skills/forgejo/SKILL.md' ]"
# forgejo is credential-gated rather than binary-gated. With nothing exported it must refuse and name
# both what is missing and how to supply it; a self-hosted instance has no default hostname, so
# FORGEJO_URL is a hard requirement rather than something to infer.
FJRC=$(rc_of env -u FORGEJO_URL -u FORGEJO_TOKEN bash "$LIABCHK" forgejo)
assert "forgejo gate refuses (exit 1) with no instance or token exported" "[ $FJRC -eq 1 ]"
env -u FORGEJO_URL -u FORGEJO_TOKEN bash "$LIABCHK" forgejo > "$WORKDIR/forgejo-gate.txt" 2>&1 || true
assert_grep "the forgejo gate names the missing instance URL" \
            "FORGEJO_URL" "$WORKDIR/forgejo-gate.txt"
FJRC2=$(rc_of env FORGEJO_URL=https://git.invalid FORGEJO_TOKEN=not-a-real-token bash "$LIABCHK" forgejo)
assert "forgejo gate is satisfied by presence alone (0), or reports a missing client (1)" \
       "[ $FJRC2 -eq 0 ] || [ $FJRC2 -eq 1 ]"
env FORGEJO_URL=https://git.invalid FORGEJO_TOKEN=not-a-real-token bash "$LIABCHK" forgejo \
    > "$WORKDIR/forgejo-gate-ok.txt" 2>&1 || true
# The point of the note: a token that is present and revoked passes this check and fails at the
# instance, and the gate has to say so on the path where it is most likely to be misread.
assert_grep "the forgejo gate states a present token is not a valid one" \
            "not a valid one" "$WORKDIR/forgejo-gate-ok.txt"
LUNKRC=$(rc_of bash "$LIABCHK" bogus)
assert "unknown liab tool is a usage error (exit 2)" "[ $LUNKRC -eq 2 ]"
# The gate must say what it did not check, on BOTH paths. An `available` answer is exactly when a
# green check is most likely to be mistaken for deployment readiness.
bash "$LIABCHK" pyinfra > "$WORKDIR/pyinfra-gate.txt" 2>&1 || true
assert_grep "the pyinfra gate states it cannot verify host reachability" \
            "does not and cannot verify" "$WORKDIR/pyinfra-gate.txt"
if [ "$PRC" -ne 0 ]; then
  skip "pyinfra unusable — $(grep -h '^missing: ' "$WORKDIR/pyinfra-gate.txt" | sed 's/^missing: //')"
  echo "    $(grep -h '^enable: ' "$WORKDIR/pyinfra-gate.txt" | sed 's/^enable: //')"
else
  LIABDIR="$WORKDIR/liab"
  mkdir -p "$LIABDIR"
  # An @local inventory is the only target a test may name. A plan against a real hostname would be
  # a network operation, which is the thing this block exists to rule out.
  cat > "$LIABDIR/inventory.py" <<'INVEOF'
hosts = ["@local"]
INVEOF
  cat > "$LIABDIR/deploy.py" <<'DEPEOF'
from pyinfra.operations import files

files.directory(
    name="Create the git-annex serving root",
    path="/tmp/dsh-liab-e2e-annex",
    present=True,
)
DEPEOF
  PLANRC=$(rc_of bash -c "cd '$LIABDIR' && pyinfra inventory.py deploy.py --dry > '$WORKDIR/liab-plan.log' 2>&1")
  if [ "$PLANRC" -ne 0 ]; then
    echo "  note: pyinfra --dry exited $PLANRC; last lines of $WORKDIR/liab-plan.log:"
    tail -5 "$WORKDIR/liab-plan.log" | sed 's/^/    /'
  fi
  assert "a --dry plan is produced against an @local inventory" "[ $PLANRC -eq 0 ]"
  assert "the plan names the operation it would perform" \
         "grep -qi 'git-annex serving root\|files.directory' '$WORKDIR/liab-plan.log'"
  # The whole point of plan-only: the directory the deploy would create must not exist afterwards.
  assert "a plan changed nothing on the host" "[ ! -d /tmp/dsh-liab-e2e-annex ]"
fi

# =========================================================== compendium (MyST article build)
echo; echo "## compendium (tool gate; a scaffolded MyST project builds) [gated on mystmd]"
# The compendium doer is an agent prompt, so this asserts the deterministic parts: the tool gate,
# that the skill behind it exists, that a request for an unbuilt tool is a usage error rather than
# an `unavailable` answer, and that a minimal MyST project actually builds. What it deliberately
# does NOT assert is reproducibility — a MyST project whose figures are committed images builds
# perfectly and reproduces nothing, which is why figure provenance is the doer's check and not a
# property of a green build.
COMPCHK="$REPO/plugins/compendium-cli/scripts/check-tools.sh"
assert "compendium-cli provides a myst skill to invoke" \
       "[ -f '$REPO/plugins/compendium-cli/skills/myst/SKILL.md' ]"
# --project names where a package.json-declared mystmd lives; without it the gate would answer from
# the e2e's scaffolded dataset, which has no node_modules, and report a tool the repo does have as
# unavailable.
MRC=$(rc_of bash "$COMPCHK" myst --project "$REPO")
assert "myst gate answers available (0) or unavailable (1)" "[ $MRC -eq 0 ] || [ $MRC -eq 1 ]"
# jupyter-book, repo2data and mcp-scaffold now have skills behind them, so the gate must answer
# available/unavailable rather than the usage error it returned while they were unbuilt.
for BUILT in jupyter-book repo2data mcp-scaffold; do
  assert "compendium-cli provides a $BUILT skill to invoke" \
         "[ -f '$REPO/plugins/compendium-cli/skills/$BUILT/SKILL.md' ]"
  BRC=$(rc_of bash "$COMPCHK" "$BUILT")
  assert "$BUILT gate answers available (0) or unavailable (1)" "[ $BRC -eq 0 ] || [ $BRC -eq 1 ]"
done
# mcp-scaffold wraps no external tool: what it needs is the structural checker the emitted bundle
# must satisfy. The bundle format claim is only worth something if something checks it, so the
# reference bundle -- the shape mcp-scaffold emits -- is linted here with the harness's own lint.
BUNDLE="$REPO/plugins/compendium-cli/references/example-agent-bundle"
assert "a reference agent bundle exists to emit against" "[ -f '$BUNDLE/.claude-plugin/marketplace.json' ]"
BLRC=$(rc_of python3 "$REPO/tests/lint-plugins.py" "$BUNDLE")
assert "the reference agent bundle passes the harness's structural lint (0 errors)" "[ $BLRC -eq 0 ]"
python3 "$REPO/tests/lint-plugins.py" "$BUNDLE" > "$WORKDIR/bundle-lint.txt" 2>&1 || true
assert_grep "the bundle lint reports zero errors explicitly" "0 error\\(s\\)" "$WORKDIR/bundle-lint.txt"
# Not asserted, deliberately: that the bundle's MCP server starts, or that its reproduction test
# passes. The test raises NotImplementedError on purpose -- a reproduction test that passed without
# comparing anything against a recorded result is the thing mcp-scaffold refuses to emit.
UNKRC=$(rc_of bash "$COMPCHK" bogus)
assert "unknown compendium tool is a usage error (exit 2)" "[ $UNKRC -eq 2 ]"
if [ "$MRC" -ne 0 ]; then
  # Quote the gate's own reason rather than assuming "not installed": present-but-unrunnable and
  # absent are different problems with different fixes, and the gate already distinguishes them.
  bash "$COMPCHK" myst --project "$REPO" > "$WORKDIR/myst-gate.txt" 2>&1 || true
  skip "myst unusable — $(grep -h '^missing: ' "$WORKDIR/myst-gate.txt" | sed 's/^missing: //')"
  echo "    $(grep -h '^enable: ' "$WORKDIR/myst-gate.txt" | sed 's/^enable: //')"
else
  MYSTPROJ="$WORKDIR/article"
  mkdir -p "$MYSTPROJ"
  cat > "$MYSTPROJ/myst.yml" <<'MYSTEOF'
version: 1
project:
  id: e2e-smoke-article
  title: An article scaffolded by the e2e smoke test
  toc:
    - file: paper.md
site:
  template: book-theme
MYSTEOF
  cat > "$MYSTPROJ/paper.md" <<'MDEOF'
# Results

The comparison produced a difference of 7.0.
MDEOF
  # Resolve myst the way the gate script does: a global install, else the project-local one a
  # package.json declaration provides after `npm ci`. CI has only the second, and it needs an
  # absolute path because the build runs from the scaffolded project directory.
  if command -v myst >/dev/null 2>&1; then
    MYSTBIN=$(command -v myst)
  else
    MYSTBIN="$REPO/node_modules/.bin/myst"
  fi
  # Not `step`: a build failure is the thing under test, and aborting the whole suite on it would
  # hide every later assertion. Capture the result and assert on it.
  BUILDRC=$(rc_of bash -c "cd '$MYSTPROJ' && '$MYSTBIN' build --html > '$WORKDIR/myst-build.log' 2>&1")
  if [ "$BUILDRC" -ne 0 ]; then
    echo "  note: myst build exited $BUILDRC; last lines of $WORKDIR/myst-build.log:"
    tail -5 "$WORKDIR/myst-build.log" | sed 's/^/    /'
  fi
  assert "a scaffolded MyST project builds successfully" "[ $BUILDRC -eq 0 ]"
  assert "the build produced output" "[ -d '$MYSTPROJ/_build' ]"
fi

# =========================================================== containers-cli (runtime gates)
echo; echo "## containers-cli (runtime gates; the pins the toolbox will not waive) [gated on runtimes]"
# Deliberately NOT asserted here: that a Dockerfile builds, that an image converts, or that a .sif
# runs on a cluster. The containers-run block above already does a real docker->apptainer conversion
# when the runtimes are present; what this block checks is that each gate answers correctly and that
# the two pinning rules are actually written down where a skill will read them.
CONCHK="$REPO/plugins/containers-cli/scripts/check-runtimes.sh"
assert "containers-cli ships the runtime gate" "[ -x '$CONCHK' ]"
for CSKILL in dockerfile oci-build apptainer; do
  assert "containers-cli provides a $CSKILL skill to invoke" \
         "[ -f '$REPO/plugins/containers-cli/skills/$CSKILL/SKILL.md' ]"
done
for RT in docker podman apptainer oci digest; do
  RTRC=$(rc_of bash "$CONCHK" "$RT")
  assert "runtime gate answers available (0) or unavailable (1) for $RT" \
         "[ $RTRC -eq 0 ] || [ $RTRC -eq 1 ]"
done
UNKRT=$(rc_of bash "$CONCHK" bogus)
assert "unknown container runtime is a usage error (exit 2)" "[ $UNKRT -eq 2 ]"

# Rootless vs rootful is the one question this gate answers that a presence check cannot. A rootful
# docker is `available` and still unusable to someone outside the docker group, so the gate must say
# so rather than reporting it as plainly available.
bash "$CONCHK" docker > "$WORKDIR/docker-gate.txt" 2>&1 || true
if grep -q '^result: available' "$WORKDIR/docker-gate.txt"; then
  assert_grep "docker gate states rootless or rootful rather than bare availability" \
              "rootless|rootful" "$WORKDIR/docker-gate.txt"
  if grep -q rootful "$WORKDIR/docker-gate.txt"; then
    assert_grep "a rootful docker carries an explicit caveat" "^caveat: " "$WORKDIR/docker-gate.txt"
  fi
else
  skip "docker unusable - $(grep -h '^missing: ' "$WORKDIR/docker-gate.txt" | sed 's/^missing: //')"
fi

OCIRC=$(rc_of bash "$CONCHK" oci)
if [ "$OCIRC" -ne 0 ]; then
  bash "$CONCHK" oci > "$WORKDIR/oci-gate.txt" 2>&1 || true
  skip "no OCI builder - $(grep -h '^missing: ' "$WORKDIR/oci-gate.txt" | sed 's/^missing: //')"
  echo "    $(grep -h '^enable: ' "$WORKDIR/oci-gate.txt" | sed 's/^enable: //')"
else
  assert_grep "the OCI gate names which builder it selected and why" \
              "selected:" <(bash "$CONCHK" oci)
fi

# The apptainer<->Docker archive path is the most easily-lost fact in this capability: apptainer
# 1.1.x cannot read a modern Docker daemon, and the failure reads as a broken image rather than an
# API mismatch. Assert it is written in the skill, not only remembered by an agent.
APPSKILL="$REPO/plugins/containers-cli/skills/apptainer/SKILL.md"
assert_grep "the apptainer skill carries the docker-archive path"  "docker-archive://" "$APPSKILL"
assert_grep "the apptainer skill warns against docker-daemon"      "docker-daemon://"  "$APPSKILL"
assert "the apptainer skill forbids rather than recommends docker-daemon" \
       "grep -q 'Never use .docker-daemon' '$APPSKILL'"

# The two pins the capability exists to hold. Both produce containers that run and do not rebuild,
# so both have to be refusals in the skill text rather than advice.
DFSKILL="$REPO/plugins/containers-cli/skills/dockerfile/SKILL.md"
assert_grep "the dockerfile skill refuses a mutable tag as a pin"  "tag is not a pin"  "$DFSKILL"
assert_grep "the dockerfile skill distinguishes unpinned from over-pinned" "over-pinned" "$DFSKILL"
assert_grep "the dockerfile skill names the three environment kinds" "derived" "$DFSKILL"

# =========================================================== bids validation (bids-cli toolbox)
echo; echo "## bids (validator presence check; validation gated on an installed validator)"
# The bids doer is an agent prompt, so this asserts the deterministic part: the toolbox's offline
# presence check, and that the skill the check implies actually exists. "unverified" must stay
# distinguishable from "valid" — with no validator installed the question was never asked, and
# reporting that as a pass is the one thing the doer's read-only contract must never do.
VALCHK="$REPO/plugins/bids-cli/scripts/check-validator.sh"
assert "bids-cli provides a bids-validator skill to invoke" \
       "[ -f '$REPO/plugins/bids-cli/skills/bids-validator/SKILL.md' ]"
VRC=$(rc_of bash "$VALCHK")
assert "validator check answers available (0) or unavailable (1)" "[ $VRC -eq 0 ] || [ $VRC -eq 1 ]"
bash "$VALCHK" > "$WORKDIR/bids-validator-check.txt" 2>&1 || true
assert_grep "validator check names the tool it checked" "^tool: bids-validator\$" \
            "$WORKDIR/bids-validator-check.txt"
BVBRC=$(rc_of bash "$VALCHK" --bogus)
assert "an unknown flag is a usage error (exit 2)" "[ $BVBRC -eq 2 ]"
if [ "$VRC" -eq 1 ]; then
  assert_grep "unavailable validator says how to enable one" "^enable: " \
              "$WORKDIR/bids-validator-check.txt"
  # The Python bids_validator package is a filename matcher with no console script. If it is
  # importable and the check still says unavailable, the check is refusing to count it — which is
  # the point: reporting `available` for a capability that cannot validate a dataset would
  # green-light a validation path that does not exist.
  if python3 -c 'import bids_validator' 2>/dev/null; then
    assert_grep "the Python package is not counted as a validator" \
                "not a substitute" "$WORKDIR/bids-validator-check.txt"
  else
    skip "the Python bids_validator package is not installed, so its exclusion is untested here"
  fi
  skip "no BIDS validator installed (deno run -A jsr:@bids/validator, or npm install -g bids-validator, to validate the scaffolded dataset)"
else
  assert_grep "available validator names the distribution found" "^found: " \
              "$WORKDIR/bids-validator-check.txt"
  # The scaffolded dataset is a YODA/BIDS skeleton, so it is not expected to pass — what is asserted
  # is that the validator ran and produced a verdict, not which verdict.
  if command -v bids-validator >/dev/null 2>&1; then
    bids-validator . > "$WORKDIR/bids-validate.txt" 2>&1 || true
  else
    deno run -A jsr:@bids/validator . > "$WORKDIR/bids-validate.txt" 2>&1 || true
  fi
  assert "the validator produced output for the scaffolded dataset" \
         "[ -s '$WORKDIR/bids-validate.txt' ]"
fi

# =========================================================== annotate (data dictionary + backends)
echo; echo "## annotate (data dictionary written uncommitted; backends degrade per tool)"
# The annotate doer is an agent prompt, so this asserts the two deterministic things around it: the
# toolbox's per-backend presence check it runs first, and its write-but-never-commit contract.
# "unavailable" must stay distinguishable from "no term matched" — an uninstalled backend means the
# question was never asked, and reporting that as zero matches is a false negative the user cannot
# see.
BACKENDS="$REPO/plugins/annotate-cli/scripts/check-backends.sh"
ARC=$(rc_of env -u SNOMED_API_KEY -u SNOMED_OWL bash "$BACKENDS" snomed)
assert "snomed backend exits 1 with no terminology source" "[ $ARC -eq 1 ]"
env -u SNOMED_API_KEY -u SNOMED_OWL bash "$BACKENDS" snomed > "$WORKDIR/backend.txt" 2>&1 || true
assert_grep "backend check reports result: unavailable" "^result: unavailable$"      "$WORKDIR/backend.txt"
assert_grep "backend check names what is missing"       "^missing: SNOMED CT source$" "$WORKDIR/backend.txt"
assert_grep "backend check says how to enable it"       "^enable: "                   "$WORKDIR/backend.txt"
SRC=$(rc_of env SNOMED_API_KEY=dsh-sentinel-secret bash "$BACKENDS" snomed)
assert "snomed backend exits 0 with a source configured" "[ $SRC -eq 0 ]"
env SNOMED_API_KEY=dsh-sentinel-secret bash "$BACKENDS" snomed > "$WORKDIR/backend-ok.txt" 2>&1 || true
assert "backend check never prints the credential value" '! grep -q dsh-sentinel-secret "$WORKDIR/backend-ok.txt"'
ABRC=$(rc_of bash "$BACKENDS" figshare)
assert "unknown annotate backend is a usage error (exit 2)" "[ $ABRC -eq 2 ]"

# Every backend the check knows must have a skill behind it. A check reporting `available` for a
# backend with no SKILL.md would hand the doer a green light and no invocation path — the exact
# half-built state the repo treats as worse than an absent capability. Install state is not asserted
# (none of these tools is in environment.yml), the per-backend contract is: it names itself, answers
# 0 or 1 and never crashes, and when unavailable it says how to enable it.
for pair in bagel:bagel-cli pynidm:pynidm reproschema:reproschema snomed:snomed-lookup; do
  BK="${pair%%:*}"; SK="${pair##*:}"
  assert "backend $BK has an annotate-cli skill to invoke" "[ -f '$REPO/plugins/annotate-cli/skills/$SK/SKILL.md' ]"
  PRC=$(rc_of bash "$BACKENDS" "$BK")
  assert "backend $BK answers available (0) or unavailable (1)" "[ $PRC -eq 0 ] || [ $PRC -eq 1 ]"
  bash "$BACKENDS" "$BK" > "$WORKDIR/backend-$BK.txt" 2>&1 || true
  assert_grep "backend $BK names itself in its report" "^backend: $BK\$" "$WORKDIR/backend-$BK.txt"
  if [ "$PRC" -eq 1 ]; then
    assert_grep "unavailable $BK says how to enable it" "^enable: " "$WORKDIR/backend-$BK.txt"
  fi
done

# The data dictionary is the always-available half of annotation — no backend, no credential — so it
# is asserted unconditionally. Free-text Description only: a controlled term here would have to come
# from a backend, none is installed, and writing one anyway is exactly the fabrication the doer
# refuses.
python3 - <<'PY'
import csv, json
cols = next(csv.reader(open("participants.tsv"), delimiter="\t"))
spec = {
    "participant_id": {"Description": "Unique participant identifier."},
    "group": {"Description": "Study group assignment.", "Levels": {"A": "Group A", "B": "Group B"}},
    "age": {"Description": "Age at enrolment.", "Units": "years"},
}
json.dump({c: spec[c] for c in cols}, open("participants.json", "w"), indent=2)
PY
cat > "$WORKDIR/check-dict.py" <<'PY'
import csv, json, sys
cols = next(csv.reader(open("participants.tsv"), delimiter="\t"))
d = json.load(open("participants.json"))
if set(cols) != set(d):
    sys.exit(f"dictionary keys {sorted(d)} do not match columns {cols}")
if not all(d[c].get("Description") for c in cols):
    sys.exit("a column has no Description")
if any("Annotations" in d[c] for c in cols):
    sys.exit("an Annotations block appeared with no annotation backend installed")
PY
DRC=$(rc_of python3 "$WORKDIR/check-dict.py")
assert "participants.json describes every column, with no fabricated Annotations block" "[ $DRC -eq 0 ]"
datalad status > "$WORKDIR/annstatus.txt" 2>&1 || true
assert_grep "annotate writes but does not commit (dictionary left untracked)" \
            "untracked.*participants\.json" "$WORKDIR/annstatus.txt"

# A real Neurobagel conversion needs bagel-cli, which is deliberately not in environment.yml —
# Neurobagel annotation is an optional add-on, not part of the harness's own toolchain. When it is
# present, the assertion is that it REFUSES an unannotated dictionary: bagel validates controlled
# terms, so a graph file built from a dictionary carrying none would mean the validation did nothing.
if ! command -v bagel >/dev/null 2>&1; then
  echo "  SKIP: bagel-cli not installed (pip install bagel-cli to exercise Neurobagel conversion)"
else
  bagel --version > "$WORKDIR/bagel-version.txt" 2>&1 || true
  assert "bagel reports a version" '[ -s "$WORKDIR/bagel-version.txt" ]'
  BPRC=$(rc_of bagel pheno --pheno participants.tsv --dictionary participants.json \
                           --name "e2e demo study" --output "$WORKDIR/pheno.jsonld")
  assert "bagel pheno rejects a dictionary with no Annotations" "[ $BPRC -ne 0 ]"
  assert "no graph file produced from an unannotated dictionary" '[ ! -e "$WORKDIR/pheno.jsonld" ]'
fi

rm -f participants.json   # leave the tree as the earlier blocks left it

# =========================================================== summary
echo; echo "==================================================="
echo "e2e-smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
echo "OK — STAMPED S/T/A/M/D loop verified (P/E via datalad run + containers-run image-capture when gated deps present)"
