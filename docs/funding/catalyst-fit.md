# Catalyst Fund fit matrix

Working document mapping this project against the
[Research Software Catalyst Fund](https://researchsoftwarecatalyst.fund/). It exists so a two-page
proposal can be compressed from evidence rather than from memory, and so the same mapping is
available if the work is re-scoped for Track 2.

> **The fund's text below is transcribed from notes, not fetched.** Applications were not open when
> this was written. Re-verify every quoted risk and criterion against the published call before
> anything is submitted; a matrix built on a misremembered criterion is worse than no matrix.

**Status vocabulary — three values, closed.**

| Status | Means |
|---|---|
| **built** | On disk, and covered by a requirement in [`openspec/specs/`](../../openspec/specs), which describes the present |
| **specified** | A requirement or protocol exists; the thing it describes has not been built or run |
| **gap** | Neither |

Work tracked in an **active** change under [`openspec/changes/`](../../openspec/changes) is
*specified* at best — those are the authoritative record of what is **not** built. Changes under
`changes/archive/` are the opposite: they shipped, and their task records are evidence of what was
done and verified. A status may carry a parenthetical qualifier (*built (qualitative)*) or split
across a row (*built for two, gap for four*), but the status word itself is always one of the three.
There is no fourth value.

**Source — three values, closed.** *repo* (checkable against a file), *training* (delivered through
the help desk and the sessions described in [motivation.md](../motivation.md#practice)), *reference*
(material maintained outside this repository). Repository evidence and delivered practice are
different kinds of claim and are never merged into one row.

**Where the claim stays narrow.** The fund is about AI-assisted *software engineering*. This project
is about governance of the *research record* produced with AI assistance. Risks 2 and 5 land squarely
in repository territory; 1 and 4 lean on the training work; 3 sits across both. Every drafting pass
will want to widen back toward research data governance, because that is where this project's prose
already lives. This table is what holds the line.

---

## Table A — the five named risks

### 2. "Circular validation when both code and tests are generated"

**Lead with this one.** It is the risk the repository has already solved at its own scale, and the
pattern generalizes — which is what a catalytic fund is buying.

| Evidence | Source | Status |
|---|---|---|
| [`tests/lint-plugins-selftest.py`](../../tests/lint-plugins-selftest.py) injects one kind of drift per case into a throwaway copy of the repository to prove the lint still reacts — a test of the test. The suite runs 24 cases, one of which is a pristine-repo control that must stay clean | repo | **built** |
| CI was verified **red as well as green**: a throwaway branch carrying one fault per job (a requirement stripped of its SHALL, a stale routing fixture, an unresolvable citation key) failed all three, each for the right reason — recorded at `openspec/changes/archive/2026-09-11-add-research-communication/tasks.md` task 6.4 | repo | **built** |
| Every probe in [`bench/probes/`](../../bench/probes) declares a `control` and an `invalidators` block naming what would falsify its result. [`docs/evaluation.md`](../evaluation.md): *a probe that cannot state its control measures nothing* | repo | **specified** |
| Routing ground truth is **machine-derived** from each skill's `delegates_to` field — not hand-labelled, not model-generated. Anti-circularity at the fixture level | repo | **specified** |
| The exit-2 skip contract: a probe whose required capability is absent is skipped with a stated reason, never reported as a zero. Same contract [`tests/lint-plugins.py`](../../tests/lint-plugins.py) uses when PyYAML is missing | repo | **built** |
| [`bench/probes/routing.yaml`](../../bench/probes/routing.yaml) sets `per_model: required` and `aggregate_only: forbidden`, so a mean over models cannot hide one model carrying the result | repo | **specified** |

### 5. "Reasoning behind generated code is inadequately documented, complicating reproduction"

| Evidence | Source | Status |
|---|---|---|
| Agent invocations are wrapped in `datalad run`, capturing **model, prompt and resulting changes** — [`docs/stamped.md`](../stamped.md), AI-era tracking §3.12.5 | repo | **built** |
| The append-only ledger `log:` records *why*, with corrections as new entries rather than edits; `project/log-decision` exists so that log feeds an eventual Methods section. Schema-validated by [`schemas/project.schema.json`](../../schemas/project.schema.json) | repo | **built** |
| [`tests/e2e-smoke.sh`](../../tests/e2e-smoke.sh) asserts this rather than assuming it — provenance is recorded, replayable, and survives push → independent clone → `datalad get` | repo | **built** |
| The `reproducibility` probe measures the gap directly: clean machine, resolve identifier, clone, rebuild, re-execute, diff, with **number of manual interventions** as a metric — *a rebuild that "worked" after four undocumented fixes did not work* | repo | **specified** |

### 1. "AI-assisted coding can bypass two checks research software has long relied on: the engineering judgment a person acquires through training or experience, and the understanding they build by writing the code themselves"

The repository's answer is structural; the help desk's answer is direct. Both are needed, and they
are different kinds of evidence.

| Evidence | Source | Status |
|---|---|---|
| **The help desk builds the judgment directly.** Guiding a cohort of postdocs at the AI/neuroscience intersection is the check the fund says gets bypassed, performed by a person — see [motivation.md](../motivation.md#practice) | training | **built** (qualitative; no figures collected) |
| A planner skill MUST carry `## When to use`, `## Steps`, `## Constraints` — human-authored research-process judgment, enforced by [`tests/lint-plugins.py`](../../tests/lint-plugins.py). Tool mechanics are quarantined below: *doers are the only things that run tools* | repo | **built** |
| [`docs/end-to-end-workflow.md`](../end-to-end-workflow.md) marks 🔧 **Do-it-yourself** sections — the scientific and engineering work the harness does not do for you (model selection, scripting, plotting, interpretation). *The skills scaffold around this work; they don't replace it.* An explicit, documented refusal to let the tool substitute for judgment | repo | **built** |
| ⚠️ **Scaffolding gap** callouts name where the harness leaves the researcher unaided, with a ranked list. The highest-ranked one now has an owning change | repo | **built** (the callouts); the fixes are **specified** |
| Manuscript-craft reference material — [`docs/writing/`](../writing/index.md), six files distilled from ten sources | reference | **built** |

### 4. "Uneven training and tool access across institutions"

**Weakest in the repository, strongest outside it.** A help desk exists *because* access is uneven;
the harness is how one person serves a cohort without becoming the bottleneck.

| Evidence | Source | Status |
|---|---|---|
| Help-desk delivery to a postdoc cohort, plus conference workshops and tutorials, institutional and lab sessions, and written material researchers work through alone | training | **built** (qualitative) |
| An early-stage institutional initiative building a shared resource for guidance on this class of tool — early adopters pooling effort rather than each solving it alone | training | **built** (qualitative) |
| Contributors write **only Markdown**; no Python is required to extend the harness (Design Rule 6) | repo | **built** |
| Content is harness-neutral: authored once, installed to Claude Code and OpenCode, designed for Cursor, Copilot, Windsurf and Gemini CLI | repo | **built** for two, **gap** for four |
| [`bin/install.sh`](../../bin/install.sh) is *deliberately a small file copier and translator so a user in a locked-down environment can reproduce it by hand* — `openspec/specs/harness-distribution/spec.md`. Built for institutions without tool access, not merely compatible with them | repo | **built** |
| MIT code / CC BY content, with SPDX and REUSE identifiers. No licence cost and no institutional affiliation required to use it | repo | **built** |

### 3. "Teams and institutions are making adoption decisions with few shared frameworks to draw on"

| Evidence | Source | Status |
|---|---|---|
| [`docs/stamped.md`](../stamped.md) distils STAMPED into RFC 2119 requirements (S.1 … D.3) that are **mechanically enforced** — the lint validates every skill's `stamped:` letters against the closed set, and now validates the marketplace description's prose too | repo | **built** |
| The **two-plane split** is a nameable, transferable adoption pattern: research vocabulary above, tool mechanics below, joined by a contract that fails a check rather than decaying into convention | repo | **built** |
| [`openspec/specs/`](../../openspec/specs) is 20 validated specs — a shared, machine-checkable statement of what an assistant configuration must do, and a worked example of OpenSpec itself as an adoption framework | repo | **built** |
| [`docs/end-to-end-workflow.md`](../end-to-end-workflow.md) "When each decision must be finalized" — 16 rows of decision → stage → ledger location → why it locks there. An adoption-decision framework in its own right | repo | **built** |
| Transfer of these frameworks to other groups is demonstrated through training, not measured | training | **gap** |

---

## Table B — the review criteria

| Criterion | Evidence | Status |
|---|---|---|
| **Feasibility within six months** | [`docs/evaluation.md`](../evaluation.md) (protocol written), [`bench/probes/`](../../bench/probes) + `bench/tasks/routing-lifecycle.yaml` (fixtures exist, 4 probes / 1 suite / 27 tasks), [`tests/check-bench-fixtures.py`](../../tests/check-bench-fixtures.py) (CI-validated), ground truth machine-derived. Only the runner is missing — `bench/README.md` defers it "until the probe set is settled" | **specified**; the remaining work is one runner |
| **Concrete shareable outputs under open licenses** | MIT for code, CC BY 4.0 for content, with `REUSE.toml` and SPDX identifiers. The deliverable is mostly Markdown, and the split exists because the content licence is the one that matters | **built** |
| **Relevance to trustworthy AI-assisted research software** | Table A. Risks 2 and 5 answered from the repository; 1 and 4 from the training work; 3 across both | **built** / **specified**, per row |
| **Broader community benefit beyond the applicants** | Probes are declarative fixtures — *adding or dropping an integration is editing fixtures, not code* — so the instruments are usable by teams that do not adopt this harness. Routing metrics deliberately mirror Chen et al. for comparability. Content is harness-neutral Markdown and the install is reproducible by hand. **Training is already delivered**, with invitations to present and inbound requests as the reach that can be pointed at | **built** for the design; the reach is **built** qualitatively and unmeasured |
| **Budget proportionality** | Four probes, model API spend for the executed runs, one runner. Sizing depends on the runner's shape, which is not settled | **to write** |

### Deliverables — artifacts, not intentions

Drawn from the adoption gaps above. Each is a thing that exists at the end, not a thing attempted.

1. A probe runner executing the four probes specified in [`docs/evaluation.md`](../evaluation.md).
2. Executed results for routing, provenance, reproducibility and cost, reported **per-model** and
   **per-dimension** — `per_model: required`, `aggregate_only: forbidden`, and provenance not
   collapsed into a composite, on STAMPED-spectrum grounds.
3. Fixtures, rubrics and harness-off controls published as **reusable instruments**, usable by teams
   who do not adopt this harness.
4. **The adoption package**: a real install path, a worked example another group can run end to end
   on their own data, and portability tested beyond the two assistants currently exercised.
5. A short practice write-up on what the measurements say about whether a structural contract changes
   agent behaviour — paired with the training material, so the output is a practice rather than a
   result.

---

## What this matrix cannot claim

Taken from [`paper/sections/05-discussion.md`](../../paper/sections/05-discussion.md), which lists
these in order and instructs *"Do not soften this."*

1. **Nothing has been evaluated.** The protocol is specified and unrun. Every claim about the
   harness's effect on work quality is a design argument, not a measurement. This is the limitation a
   reader should take away, and it goes first.
2. **The capability plane is uneven.** Several planners can express a step and cannot perform it —
   they describe the output and commit it. `datalad` has a 19-skill toolbox, `annotate` a 4-skill
   one, `archive` a 3-skill one, and `bids`, `compendium` and `liab` a 1-skill one each;
   `containers` has none. Two paths have been exercised against their real tools:
   `tests/e2e-smoke.sh` builds a scaffolded MyST project, and it produces a `pyinfra --dry` plan
   and asserts the host was unchanged. The archive deposit paths, the annotate backends and the
   BIDS validators have not been run live, because none of those tools is installed here; most of
   the annotate toolbox validates terms rather than finding them; and the `liab` **apply** path is
   exercised by hand rather than by the suite, which the doer states rather than implies.
3. **Single-project experience.** The design comes from one context; generality is asserted, not
   demonstrated.
4. **Governance scope is project-level.** Botes (2026) asks for agent-level access control and
   machine-decidable consent across federated repositories; a project-level tool cannot deliver that,
   and the ledger schema does not yet carry consent scope or use restrictions at all.
5. **No claim adjudication.** This project records what was done; it does not judge whether a claim is
   supported. Brain Researcher does, and does it better than could be bolted on here.
6. **Harness dependence.** The content is Markdown and portable in principle, but it is exercised on
   two assistants. Portability to the other four named targets is designed, not tested.

Two further constraints on this document specifically:

- **No number here comes from a measurement of this project.** Published figures in this space —
  tool-selection accuracy, verifiable grounding — belong to
  [Brain Researcher](https://arxiv.org/abs/2608.19902) and are attributed to it wherever mentioned.
- **The training rows carry no dates, headcounts or institutional reach**, because none were
  supplied. They are qualitatively strong and quantitatively empty, and inventing a figure would make
  the whole table suspect. Collecting those specifics is the highest-value thing that would strengthen
  a submission.

## The framing to hold

The ask is **adoption readiness, not construction**. The prototype works and is in use; the proposal
is *"this runs; here is what it takes for another group to run it."* Without that framing a reviewer
supplies the less generous reading of "minimally working" themselves — and the executed probes are
the evidence that carries it, which is the argument for piloting the routing probe before submitting.
