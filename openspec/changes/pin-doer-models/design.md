## Context

The harness targets several assistants with different model-identifier vocabularies. Claude Code
accepts short aliases; OpenCode expects provider-prefixed strings. The authored content is written
once, so any model reference has to be either translated at install time or absent.

`harness-distribution` already settles which form "written once" means: the source layout is Claude
Code-compatible and is the single authored form, and harness-specific variants are produced at
install time rather than committed. `model:` follows `name:` and `tools:` — authored in the source
vocabulary, adapted on the way out. An invented neutral vocabulary would be a third form to maintain
and would make the Claude Code path translate a value it already accepts.

`bin/install.sh`'s `install_agent_for_opencode` already demonstrates the translation pattern: an awk
pass over the frontmatter that drops fields the target does not use and inserts ones it needs.

## Goals / Non-Goals

**Goals:**
- A typo in `model:` fails the lint.
- An installed agent's `model:` resolves in the target harness, or is absent.
- The field is documented in the two places a contributor would look.
- Read-only doers stop using a frontier model unnecessarily.

**Non-Goals:**
- Choosing models for planner skills. Skills are prompts loaded into whatever session is running;
  the field applies to agents.
- Encoding pricing or capability tiers. The allowed set is a list of identifiers, not a policy.
- Pinning mutating doers. They make irreversible changes and their judgement is worth more than the
  saving.

## Decisions

- **Validate against an allowed set, not a regex.** A regex would accept a well-formed identifier
  that does not exist. The set lives beside `STAMPED_LETTERS` and `PLANES` in
  `tests/lint-plugins.py`, which is where the other closed vocabularies already are.
- **Authored values use the source vocabulary; the installer translates outward.** The allowed set
  holds the bare aliases Claude Code accepts, so the Claude Code path stays a plain copy and only
  targets that differ from the source pay a translation cost. This is what `harness-distribution`
  already requires of every other frontmatter field, and it is why the lint rejects an authored
  provider-prefixed value: a value already in one target's syntax cannot be translated for the rest.
- **When translation is not possible, strip rather than pass through.** An agent with no `model:`
  runs on the harness default, which works. An agent with an unresolvable `model:` fails at load.
  Degrading to the default is the safer failure.
- **Pin only read-only doers.** `bids-doer` and `coordinator` both read and report and neither can
  mutate a dataset, so a smaller model's mistake is a worse summary rather than a damaged tree.
- **Do the plumbing before the pinning.** The tasks are ordered so no agent declares the field until
  the lint and installer handle it.

## Risks / Trade-offs

- **The allowed set will go stale.** Model identifiers change; a list in a lint file needs
  maintenance, and an out-of-date list rejects a valid new model. That is the intended failure
  direction — a loud rejection beats a silent typo.
- **Pinning a smaller model to a read-only doer degrades its reports.** `coordinator`'s job is
  situational judgement about what to do next, which is not obviously a cheap task. This is worth
  revisiting with evidence rather than asserting.
- **`docs/writing/SPEC.md`'s `strong-writing` value is symbolic** and will not validate. It must
  either become a real identifier or be explicitly marked as a placeholder in a spec rather than a
  live file.
