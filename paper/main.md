---
title: A lifecycle harness for governable, re-executable research products
short_title: data-science-harness
exports:
  - format: pdf
    template: arxiv_two_column
---

+++ {"part": "abstract"}

<!-- DRAFT SKELETON. Not written prose. ~200 words when drafted. -->

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

**Status.** <!-- State plainly: the workflow plane is complete, the capability plane is uneven, and
the evaluation protocol is specified but unrun. Give the real numbers — plugins, planner skills,
capability doers — from openspec/specs/, not from memory. -->

**Contribution.** <!-- One sentence. Candidate: an architecture in which governance is a by-product
of ordinary work rather than a compliance step, plus a specified evaluation protocol for measuring
whether that holds. -->

+++

<!--
WRITING NOTES FOR THIS FILE

The abstract is the last thing to write. Until the evaluation section is settled, any abstract
written here will overclaim.

Two things this abstract must NOT do:
  - report a benchmark number (none exist)
  - describe Brain Researcher as complementary without saying where the interface is

Structure to follow (Schwabe 2016 funnel; see docs/writing/article-anatomy.md):
problem → why existing approaches fall short → what we built → what we found → what it means.
With no results, the fourth move becomes "what we specified" and must be labelled as such.
-->
