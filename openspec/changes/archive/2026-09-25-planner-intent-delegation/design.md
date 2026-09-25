## Context

When this change starts, `native-datalad-planners` has landed:

- DataLad runs in the main thread;
- activity is recorded in `DSH-*` commit lines, including `DSH-Binding`;
- the planners carry DataLad commands directly.

What remains is the boundary between planners and the *peripheral* doers: nipoppy, containers,
annotate, archive, compendium, liab and bids.

Per-skill counts of inline spans and fenced lines that start with a peripheral binary, recounted
on 2026-09-25 after `native-datalad-planners` (the 2026-09-22 draft counted 20):

| Skill | Spans |
|---|---|
| `annotate` | 8 |
| `executable-article` | 5 |
| `run-pipeline` | 3 |
| `liab-deploy` | 3 |
| `raw-to-bids` | 3 |
| `gen-data-dict` | 1 |
| `deidentify` | 1 |

The other 30 planners have none. The doers already take plain-language requests; `nipoppy-doer.md`
says "Give it a plain-language request". The command lines in planners are therefore redundant
rather than load-bearing.

## Goals / Non-Goals

**Goals:**
- Planners say *what* for peripheral tools, and doers decide *how*. The native toolchain stays
  direct.
- The boundary is checkable and currently holds (zero violations).
- The three-layer rationale is written down, including why the environment layer is deferred.

**Non-Goals:**
- Tool *names* in planners. The lint requires naming doers, and names like fMRIPrep are research
  decisions.
- Any registry or capability abstraction. Each capability has one implementation, so there is
  nothing yet to abstract over.
- Changing `env-check`. It runs harness gate scripts, which are allowed. It is the
  compute-environment seam, and that is documented rather than changed.

## Decisions

**D1. Only peripheral tool binaries count.** The closed set is `nipoppy`, `bids-validator`,
`apptainer`, `singularity`, `docker`, `podman`, `heudiconv`, `dcm2bids`, `pydeface`, `bagel`,
`pynidm`, `reproschema`, `myst`, `repo2data`, `pyinfra`, `osf`, `zenodo` and `curl`. A span counts
when it is either of the following:
- an inline code span whose first token is in the set;
- a fenced code-block line whose first token is in the set.

`datalad`, `git`, `git-annex`, `bash`/`python` running harness scripts, and standalone `--flag`
spans are never counted. A flag cannot be attributed to a tool out of context, and most flags in
planners are DataLad's.

*Alternative: a ratchet with a committed baseline.* This was drafted first, when 114 spans
counted DataLad too. Once DataLad was excluded, 24 spans remained. Fixing them is cheaper than
maintaining a baseline file.

**D2. A violation is an error.** The tree is clean after this change, so any new span is drift.

**D3. Safeguards survive as words.** Each rewrite keeps every parameter the old syntax carried:
pipeline, version, step, scope, inputs, outputs and target. It restates flag-borne safeguards as
constraints. For example: "the doer previews with a simulation before any live run", and "always
name the pipeline, version and step, because omitting them fans out across every configured
pipeline".

## Risks / Trade-offs

- [A doer builds a different command from prose than the syntax specified] → D3's rule of keeping
  every parameter. Review each rewrite against the doer's "Parse the request" fields.
- [The binary set misses a tool a future planner adds] → The set sits beside the other closed
  vocabularies. Adding a toolbox plugin should add its binary; tasks note this in the
  contributing steps.
- [A span names a tool in running prose, e.g. `` `myst` `` alone] → Counted. Planners write tool
  names unquoted, and a quoted bare binary looks like a command to an assistant.

## Migration Plan

Additive lint plus rewrites. Rollback means removing the check. The rewritten skills stay correct
either way.

## Open Questions

- `env-check`: when environment providers supply module or cluster context, should it become a
  read-only "environment" doer that providers can replace? This is deferred until a provider
  exists.
