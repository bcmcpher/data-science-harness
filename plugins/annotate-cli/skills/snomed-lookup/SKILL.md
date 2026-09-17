---
name: snomed-lookup
description: >
  Auto-invoke when the user wants a SNOMED CT concept identifier for a clinical variable, diagnosis,
  assessment, or finding — the codes Neurobagel's diagnosis and assessment fields expect. Trigger on
  "snomed", "snomed ct", "sctid", "clinical code for", "look up a diagnosis code", "what is the
  concept id for", "standardize these diagnoses", or /snomed-lookup. Do NOT trigger for Neurobagel
  validation or graph building (use bagel-cli), for NIDM terms (use pynidm), for assessment schemas
  (use reproschema), or for ICD/LOINC/RxNorm codes — this skill queries SNOMED CT only.
argument-hint: '[check|search] [--term <text>] [--column <name>] [--max <n>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: snomed-lookup

Return SNOMED CT concept identifiers for clinical terms, each with the source that produced it, so a
diagnosis or assessment column can carry a real code instead of a plausible-looking number.

**Read this before anything else: there is no SNOMED CT tool bundled with this harness, and there
cannot be.** SNOMED CT requires an affiliate licence in most countries, so the content is the user's
to provide. This skill queries *whatever source they configured* and nothing else:

| Source | Configured by | Where the query goes |
|---|---|---|
| A licensed terminology API | `SNOMED_API_KEY`, optionally `SNOMED_API_URL` | over the network, to that endpoint |
| A local SNOMED release | `SNOMED_OWL=/path/to/file` | nowhere — reads the file |

Two consequences shape everything below. First, **this is the only skill in `annotate-cli` that
sends anything off the machine**, so what leaves has to be deliberate: the text of a column name or
a label, never a row of participant data. Second, a SNOMED concept ID is an opaque number of the
right length whatever you do, so **a recalled code is indistinguishable from a looked-up one in the
output.** Reporting "no source configured" is always correct; inventing a code never is.

"Unavailable" and "no match" are also different answers, and the user acts differently on each. No
source configured means the question was never asked. A search that returned zero hits means the
term is not in SNOMED under that wording — which is useful, and often means rephrasing.

## Steps

1. **Check availability** — the toolbox's offline presence check:
   ```bash
   plugins/annotate-cli/scripts/check-backends.sh snomed
   ```
   Exit 1 prints `result: unavailable` and the `enable:` hint. Stop there and report it. This check
   is presence-only and never contacts the network, so a configured-but-invalid key passes here and
   fails at step 4, where the honest result is `failed`, not `no match`.

2. **Establish which source you are using, and say so in the report.** If both are configured,
   prefer the local release: it is offline, it is the version the user actually licensed, and it
   leaves no query trail. Never print the key's value — confirm presence only:
   ```bash
   [ -n "${SNOMED_API_KEY:-}" ] && echo "SNOMED_API_KEY is set" || echo "SNOMED_API_KEY is not set"
   [ -n "${SNOMED_OWL:-}" ] && ls -l "$SNOMED_OWL"
   ```

3. **Build the search terms from metadata only.** Column names, the `Description` text, and the
   `Levels` labels in `participants.json` are what you search. A participant's row is never a search
   term, and neither is a free-text clinical note from the data. Before the first network query,
   state in your output exactly which strings you are about to send.

4. **Query a licensed terminology API** — when that is the configured source. The shape below is the
   UMLS Terminology Services REST interface, which is the default `SNOMED_API_URL` because it is the
   licensed route most users already have; if they set a different endpoint, follow its own
   documentation instead of bending it into this shape. Pass the key with `--data-urlencode` so it
   does not appear in a command you echo:
   ```bash
   curl -sS -G "${SNOMED_API_URL:-https://uts-ws.nlm.nih.gov/rest}/search/current" \
        --data-urlencode "string=<search term>" \
        --data "sabs=SNOMEDCT_US" \
        --data "returnIdType=code" \
        --data-urlencode "apiKey=$SNOMED_API_KEY" \
        -w '\nhttp_status:%{http_code}\n'
   ```
   **Verify the response before trusting it.** A non-200 status, an HTML body, or JSON without the
   result array you expected means the query failed — report `result: failed` with the status code
   and stop. Do not retry with a different endpoint you guessed at, and do not fall back to your own
   knowledge of the code. A 401 means the key is present but not valid or not entitled to SNOMED;
   say that, because it is a licence question the user can act on.

5. **Query a local SNOMED release** — when `SNOMED_OWL` is the source. Use a real parser if one is
   installed (`robot`, `owlready2`, or a triplestore the user names), because a parser matches on
   the label property rather than on text that happens to appear in the file:
   ```bash
   command -v robot; python3 -c 'import owlready2' 2>/dev/null && echo owlready2 available
   ```
   With no parser available, an **exact-string** label match with `grep` is acceptable, and must be
   reported as the crude match it is:
   ```bash
   grep -n -F -i -- "<exact label>" "$SNOMED_OWL" | head -20
   ```
   Do not fuzzy-match, do not match on a substring of a word, and do not infer a concept ID from a
   nearby line. If the exact label is absent, that is `no match`, and rephrasing is the next step.

6. **Return candidates, never a decision.** For each search term report every hit you got, up to the
   `--max` the caller asked for: the concept ID, its preferred term or fully specified name, its
   semantic tag where the source gives one, and the source queried. Where several concepts match,
   say so and present them — choosing between a finding, a disorder, and a procedure with similar
   names is a research judgement that belongs to the planner and the user, and picking one silently
   is how a dataset acquires a subtly wrong code.

7. **Write nothing.** This skill looks up; it does not annotate. Hand the candidates back to the
   annotate doer, which owns the `participants.json` write, and let `bagel-cli` decide the `TermURL`
   form its vocabulary expects. Report per term: the source, the strings sent, the candidates, and
   `no match` where the search came back empty.

## Constraints
- **Never emit a SNOMED concept ID that no query in this session returned.** Not from memory, not
  "for illustration", and not as an example in prose — an example code in a report gets copied. No
  source configured means the answer is that no lookup happened.
- **Never print, echo, log, or write the value of `SNOMED_API_KEY`**, and never include it in a
  command you display. Confirm presence only.
- **Never send participant-level data to a terminology server.** Column names, descriptions, and
  level labels only, named in your output before you send them.
- Do not query the network when the configured source is a local release, and do not query it at all
  if the user asked for an offline run — say what a lookup would have needed instead.
- Do not work around a missing licence: no scraping a public browser UI, no substituting a different
  terminology and calling the result SNOMED, no pulling codes out of an unrelated dataset that
  happens to contain some.
- Report `unavailable`, `no match`, and `failed` as three different outcomes. Collapsing them hides
  a fixable configuration problem behind what looks like a finished search.
- Do not cache or copy out bulk SNOMED content. The identifiers and labels needed for the columns at
  hand are what this skill returns; redistributing the release is the user's licence to manage.
- Do not commit, and do not edit `participants.tsv` or `participants.json`.
