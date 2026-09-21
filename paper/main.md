---
title: A lifecycle harness for governable, re-executable research products
short_title: data-science-harness
exports:
  - format: pdf
    template: arxiv_two_column
---

+++ {"part": "abstract"}

<!-- DRAFT. All four moves are now written (~200 words). Revisit after the evaluation section
settles: this is the paragraph most likely to overclaim, and the Status move is the one that
goes stale first. -->

**Problem.** Assistants can now execute analyses faster than the surrounding record can be
maintained by hand, so provenance, administrative context, and the terms under which data may be
reused fall behind the science they describe. Technically portable data are not necessarily
governably reusable data [@botes2026lawinsidemachine].

**Approach.** We describe `data-science-harness`, a harness-agnostic set of assistant configurations
that separates *research process* from *tool mechanics* across two planes, and routes every
computation and every administrative change through a single DataLad provenance chain. A versioned
project ledger carries products, obligations, and credit alongside the data. The default export is a
living compendium: a provenanced dataset, a re-executable article, an agent-callable method bundle,
and a self-hostable deployment, cross-linked by persistent identifier.

**Status.** Both planes are built: 22 plugins, 77 skills, and 8 capability doers each paired with a
command-level toolbox, specified by 22 OpenSpec records and held to a structural lint. What is not
built is evidence. Most capability paths are gated, the gates are tested, and the tools behind them
have not been run here; two capabilities have no test of any kind. The evaluation protocol in this
paper is specified and **unrun**, and no number reported anywhere in this work comes from a
measurement of the harness's effect.

**Contribution.** An architecture in which governance is a by-product of ordinary work rather than a
compliance step applied afterwards, together with an evaluation protocol — specified before any
capability was measured — for determining whether that claim holds.

+++

<!--
WRITING NOTES FOR THIS FILE

The abstract is the last thing to write. Until the evaluation section is settled, any abstract
written here will overclaim.

Two things this abstract must NOT do:
  - report a benchmark number (none exist)
  - describe Brain Researcher as complementary without saying where the interface is

The Status move must be regenerated from disk, never edited from memory. As of this draft:
22 plugins, 77 registered skills (37 planner / 40 toolbox), 8 doers paired 1:1 with 8 `*-cli`
toolboxes, 9 agents, 22 specs. `nipoppy` and `process` are the two capabilities with no test of
any kind; check `tests/e2e-smoke.sh` before repeating that claim.

Structure to follow (Schwabe 2016 funnel; see docs/writing/article-anatomy.md):
problem → why existing approaches fall short → what we built → what we found → what it means.
With no results, the fourth move becomes "what we specified" and must be labelled as such.
-->
