## Why

The repository says why it exists in five places, and they do not agree.

`README.md:9` opens from a tooling-mismatch premise — assistant configurations are built for
software products, research has a different end goal. `paper/main.md:13-16` opens from a
speed-and-governance premise — assistants outrun the record, and "technically portable data are not
necessarily governably reusable data." Neither premise appears in the other document. The Botes
governance argument that is the paper's central motivator is absent from the README entirely.

The same split runs through the slogans. `README.md:20` says administration is "first-class, not an
afterthought"; `paper/myst.yml:16-18` and `paper/sections/05-discussion.md` say governance is a
"by-product" of ordinary work. Those are the same commitment stated two ways that sound opposed, and
"by-product" — the sharper of the two, and the one the design actually implements — appears nowhere
in the README.

`.claude-plugin/marketplace.json:5` is a third story again. It claims reproducibility and STAMPED
alignment and omits all four of the README's distinguishing claims: harness-agnosticism, the living
compendium, administration as first-class, and the two-plane split. It names two workflow planners
where six exist and its own `plugins[]` array lists six. It claims a STAMPED letter — "Metadata" —
that is not in the closed set the lint enforces everywhere else. It describes `disseminate` as one
skill where the plugin has eight, so the living-compendium export the README leads with is invisible
to anyone discovering the harness through the marketplace.

This is the same class of defect `reconcile-docs-with-disk` closed for facts about files. That
change made the documentation agree with the disk. It did not make the documentation agree with
itself, because there was no single statement for the surfaces to agree *with*.

There is also something the repository has never recorded. The harness exists because its author
runs a help desk: guiding a cohort of postdocs working at the intersection of AI and neuroscience,
so they can reach the tooling for their projects without having to find it themselves. That is the
lived form of the argument the paper makes abstractly — a help desk is exactly the case where one
person cannot scale by answering questions, so the knowledge has to be externalized into something
the researcher routes through directly. It is also the harness's own central move, applied to
people instead of to agents. Nothing in the repository says it, and `README.md:3` says only
"community-driven", naming no user at all.

## What Changes

- `docs/motivation.md` — one document stating the problem, who the work is for, what the harness
  claims, how those claims are testable, where it sits against overlapping work, and what is not
  built. Assembled from material already written; composed fresh only where the surfaces disagree
  and a resolution has to be stated.
- A `## Practice` section in that document covering the training and reference work, which is
  delivered outside the repository and recorded nowhere in it.
- `README.md`, `.claude-plugin/marketplace.json` and the two plugin READMEs reconciled to it — the
  README's identity section trimmed to a statement plus a pointer, the marketplace description
  rewritten to carry the same claims, `publish` and `annotate` corrected from plugins to skills.
- Two additions to `check_doc_claims` in `tests/lint-plugins.py`, with matching self-test cases: the
  STAMPED letters named in marketplace prose validate against the closed set, and the workflow-planner
  count there matches the plugins on disk. Both are checks that would have caught a defect this
  change is fixing.

## Capabilities

- `publication` — a new requirement covering the canonical motivation document and the honesty rules
  binding it.
- `structural-lint` — new requirements covering the two marketplace prose checks.

## Impact

No change to any skill, agent, or plugin manifest, and no change to what the harness does. This is
prose, plus two lint checks over prose.

The README edit is the part to watch. `reconcile-docs-with-disk` explicitly ruled "rewriting the
README's argument" and "shrinking the file" out of scope, and that ruling still holds: the
conceptual sections stay. What changes is the identity statement at the top, which becomes a short
statement and a link, and four specific wrong facts further down.
