#!/usr/bin/env bash
#
# hooks-selftest.sh — unit tests for the datalad-cli hook scripts and their OpenCode install.
#
# Each hook script is fed a Claude Code-shaped JSON payload in a scratch dataset, and its exit code
# and output are asserted:
#
#   dsh-guard.sh           chained commit blocked, quoted mention allowed, plain repo allowed,
#                          git -C followed, annex and repeated -m warned, DSH_GUARD=0 honoured
#   datalad-checkpoint.sh  reminds once, stays quiet for the same state, honours stop_hook_active,
#                          DATALAD_AUTOSAVE=1 saves, DATALAD_AUTOSAVE=0 does nothing
#   dsh-status.sh          silent outside a dataset and in a plain repo; status (and rules with
#                          --with-rules) inside one; DSH_RULES_IN_CONFIG=1 suppresses the rules
#   bin/install.sh         OpenCode dry-run lists the generated plugin and the instructions entry;
#                          a real install twice keeps opencode.json's keys and lists the rules once
#
# Requirements: git with an identity, python3, and DataLad (use the conda `datalad` env).
# Exit codes: 0 = all passed, 1 = a failure, 2 = cannot run here.
# Usage: tests/hooks-selftest.sh [workdir]

set -u

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT/plugins/datalad-cli/hooks/scripts"

for tool in git python3 datalad; do
  command -v "$tool" >/dev/null 2>&1 || { echo "SKIP: $tool not found" >&2; exit 2; }
done
git config user.email >/dev/null || { echo "SKIP: git identity not set" >&2; exit 2; }

WORK="${1:-$(mktemp -d)}"
mkdir -p "$WORK"
fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

DS="$WORK/ds"
PLAIN="$WORK/plain"
datalad create -c text2git "$DS" >/dev/null 2>&1 || { echo "SKIP: datalad create failed" >&2; exit 2; }
git init -q "$PLAIN"

payload() { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$1" "$2"; }
guard() { payload "$1" "$2" >"$WORK/in"; bash "$SCRIPTS/dsh-guard.sh" <"$WORK/in" >"$WORK/out" 2>"$WORK/err"; echo $?; }

echo "# dsh-guard.sh"
check "chained git commit is blocked"      '[ "$(guard "cd . && git commit -m wip" "$DS")" = 2 ] && grep -q "datalad save" "$WORK/err"'
check "git push is blocked"                '[ "$(guard "git push origin main" "$DS")" = 2 ] && grep -q "datalad push" "$WORK/err"'
check "git -C into a dataset is followed"  '[ "$(guard "git -C $DS commit -m x" "$WORK")" = 2 ]'
check "quoted mention runs"                '[ "$(guard "echo \"never git commit here\"" "$DS")" = 0 ]'
check "plain repo is not guarded"          '[ "$(guard "git push" "$PLAIN")" = 0 ]'
check "git add is allowed"                 '[ "$(guard "git add ." "$DS")" = 0 ] && [ ! -s "$WORK/out" ]'
check "git annex drop warns"               '[ "$(guard "git annex drop f" "$DS")" = 0 ] && grep -q "datalad drop" "$WORK/out"'
check "repeated -m warns"                  '[ "$(guard "datalad save -m a -m b" "$DS")" = 0 ] && grep -q "keeps only the" "$WORK/out"'
check "single -m is silent"                '[ "$(guard "datalad save -m \"a b\"" "$DS")" = 0 ] && [ ! -s "$WORK/out" ]'
check "DSH_GUARD=0 allows everything"      '[ "$(DSH_GUARD=0 guard "git commit -m x" "$DS")" = 0 ]'

echo "# datalad-checkpoint.sh"
stop() { (cd "$DS" && printf '%s' "$1" | bash "$SCRIPTS/datalad-checkpoint.sh"); }
commits() { git -C "$DS" rev-list --count HEAD; }
echo "one" > "$DS/a.txt"
before="$(commits)"
check "dirty tree: one block decision"     'stop "{}" | grep -q "\"decision\": \"block\""'
check "same state: no repeat"              '[ -z "$(stop "{}")" ]'
echo "two" > "$DS/b.txt"
check "stop_hook_active: quiet"            '[ -z "$(stop "{\"stop_hook_active\": true}")" ]'
check "new state: reminds again"           'stop "{\"stop_hook_active\": false}" | grep -q "b.txt"'
check "the reminder never commits"         '[ "$(commits)" = "$before" ]'
check "state file is inside .git"          '[ -f "$DS/.git/dsh-last-reminded" ]'
check "DATALAD_AUTOSAVE=0 does nothing"    '[ -z "$(DATALAD_AUTOSAVE=0 stop "{}")" ] && [ "$(commits)" = "$before" ]'
check "DATALAD_AUTOSAVE=1 saves"           'DATALAD_AUTOSAVE=1 stop "{}" >/dev/null; [ "$(commits)" -gt "$before" ] && git -C "$DS" log -1 --format=%s | grep -q "^Auto-checkpoint"'
check "clean tree: silent"                 '[ -z "$(stop "{}")" ]'

echo "# dsh-status.sh"
check "outside a dataset: silent"          '[ -z "$(bash "$SCRIPTS/dsh-status.sh" "$WORK")" ]'
check "plain repo: silent"                 '[ -z "$(bash "$SCRIPTS/dsh-status.sh" "$PLAIN")" ]'
check "inside: status block"               'bash "$SCRIPTS/dsh-status.sh" "$DS" | grep -q "^- dataset: $DS"'
check "--with-rules: rules first"          'bash "$SCRIPTS/dsh-status.sh" --with-rules "$DS" | head -1 | grep -q "^# DataLad rules"'
check "DSH_RULES_IN_CONFIG=1: no rules"    '! DSH_RULES_IN_CONFIG=1 bash "$SCRIPTS/dsh-status.sh" --with-rules "$DS" | grep -q "DataLad rules"'

echo "# bin/install.sh --harness opencode"
T="$WORK/oc"
mkdir -p "$T"
echo '{"model":"x/y","instructions":["mine.md"]}' > "$T/opencode.json"
dry="$(bash "$ROOT/bin/install.sh" --harness opencode --target "$T" --dry-run datalad-cli 2>&1)"
check "dry-run lists the hook plugin"      'grep -q "generate OpenCode hook plugin .*dsh-datalad-cli.js" <<<"$dry"'
check "dry-run lists the instructions"     'grep -q "register instructions .*rules/datalad.md" <<<"$dry"'
check "dry-run writes nothing"             '[ ! -e "$T/plugins" ] && [ "$(cat "$T/opencode.json")" = "{\"model\":\"x/y\",\"instructions\":[\"mine.md\"]}" ]'
bash "$ROOT/bin/install.sh" --harness opencode --target "$T" datalad-cli >/dev/null 2>&1
bash "$ROOT/bin/install.sh" --harness opencode --target "$T" datalad-cli >/dev/null 2>&1
check "plugin generated"                   '[ -f "$T/plugins/dsh-datalad-cli.js" ]'
check "rules listed once, keys kept"       'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); i=d[\"instructions\"]; sys.exit(not (d[\"model\"]==\"x/y\" and i[0]==\"mine.md\" and sum(p.endswith(\"rules/datalad.md\") for p in i)==1))" "$T/opencode.json"'
check "installed rules path resolved"      'grep -q "$T/dsh/plugins/datalad-cli/hooks/scripts/dsh-status.sh" "$T/dsh/plugins/datalad-cli/rules/datalad.md"'
if command -v node >/dev/null 2>&1; then
  check "generated plugin parses"          'node --check "$T/plugins/dsh-datalad-cli.js" 2>/dev/null || node --input-type=module --check < "$T/plugins/dsh-datalad-cli.js"'
fi

echo
if [ "$fails" -gt 0 ]; then
  echo "$fails failure(s); workdir: $WORK"
  exit 1
fi
echo "all passed"
