# Design

## The resolutions, and why each went the way it did

Consolidation only means something if the disagreements are settled rather than averaged. Five had
to be decided before a word could be written.

**One problem statement — the paper's.** Assistants outrun the record; technically portable data are
not necessarily governably reusable data. It is the tighter claim, it is already grounded in a
citation (`botes2026lawinsidemachine`), and it generalizes: the README's tooling-mismatch premise is
a *consequence* of it, not a rival to it. So the README premise becomes the second paragraph —
why existing assistant configurations do not solve the problem — rather than being dropped. The
help-desk premise becomes the third: what the problem looks like when it lands on a person.

**One slogan — "governance as a by-product".** It states a mechanism; "first-class, not an
afterthought" states a priority. A mechanism can be checked and a priority cannot, and the whole
design rests on the mechanism: anything requiring a separate act of discipline gets skipped under
deadline. "First-class" survives as a description of what the by-product claim delivers.

**Routing is a claim.** `docs/evaluation.md:14-17` asserts that the harness routes work to the right
tool more often, and a probe with machine-derived ground truth measures it. It appears in no purpose
statement anywhere. Promote it rather than delete it — it is the most falsifiable thing the project
says about itself.

**The status caveat belongs in the motivation, not under it.** `docs/evaluation.md`,
`bench/README.md`, `paper/README.md` and the walkthrough each open with an explicit "nothing has been
run" banner. `README.md` carries none until line 174 and the marketplace carries none at all, while
describing the capability plane as if uniformly delivered — which `README.md:207-210` denies in the
same file. A document arguing that governance should be a by-product of the work cannot bury its own
status.

**Neuroimaging is scope, not a defect.** Every concrete surface — BIDS, Nipoppy, fMRIPrep, COBIDAS,
Neurobagel, OHBM — is neuroimaging, while the stated scope is "academic data science". Say it once,
plainly, as the domain the work is grounded in and the one its evidence comes from.

## Why canonical, and what canonical does not mean

An additive document would have left the duplication in place and added a sixth copy. Making
`docs/motivation.md` canonical means the other surfaces are reconciled to it and point at it.

It does not mean collapsing them. `paper/sections/01-intro.md` keeps its own prose, because a
manuscript has to stand alone and a reader of the PDF cannot follow a repository link. The
requirement on the paper is only that it does not contradict `motivation.md` — and in practice
`motivation.md` is the first written prose of an argument the paper still holds as a comment
skeleton, so the paper gains a source rather than losing autonomy.

## Why two lint checks, and why these two

The repository's rule is to ground a requirement in a check that exists, and the marketplace is
where the drift concentrated: it is the one prose surface no check reads. Two of the defects found
are mechanically checkable in the shape `check_doc_claims` already uses:

- A STAMPED letter named in marketplace prose must be in the closed set. The identical check already
  runs over every skill's `stamped:` frontmatter, which is why "Metadata" survived — it was written
  in a place the check did not look.
- The workflow-planner count in the marketplace description must match the plugins on disk. Same
  shape as the existing `**N plugins**` check on the README, applied to the other manifest.

The rest — whether a description tells the same story as the README, whether a claim is
overstated — is not mechanically checkable, and the change does not pretend otherwise. Those stay
in the verification section as things a person reads for.

## Out of scope

- **Rewriting the README's argument or shrinking the file.** Ruled out by `reconcile-docs-with-disk`
  and still ruled out. The identity section and four wrong facts; nothing else.
- **The ⚠️ Scaffolding gap and 🔧 Do-it-yourself callouts.** Task 4.4 of that change left them
  deliberately, as "already honest, and load-bearing". They stay untouched.
- **Settling the project's name.** There are four (`data-science-harness`, `ds-harness`,
  `data-science-harness-tooling`, and the paper's placeholder title). Two are package identifiers with
  real constraints and one is flagged as a placeholder in `paper/myst.yml:14`. Renaming is a change
  with actual blast radius, not a documentation pass.
- **Inventorying the reference material.** It is distributed across many sources and formats and will
  not be usefully consolidated here. The `## Practice` section characterises it and says why it stays
  distributed.

## Risks

**Naming a third party.** The `## Practice` section describes a programme and an institutional
initiative that belong to other people. Describe the role and the work; name no individuals, and
leave the internal initiative unnamed until there is permission to name it.

**No numbers exist for the practice record.** No dates, headcounts, or institution list beyond the
programme itself were supplied. Under the repository's own *no unmeasured number* rule the section is
written qualitatively, and names in one line which specifics would strengthen it — so a later pass
collects them rather than a drafting pass inventing them.

**Canonical documents drift too.** `motivation.md` becomes the thing the other surfaces defer to,
which makes it the most expensive place to be wrong. The two lint checks cover the marketplace; the
rest is held by the rule that every claim in it is built, specified in `openspec/specs/`, or labelled
a gap, with no fourth category.
