## Why

Lab-in-a-Box is the fourth arm of the living compendium — the self-hostable deployment that makes a
dataset distributable on infrastructure the lab controls rather than only through a third-party
archive. `disseminate/liab-deploy` describes it in detail: pyinfra config, self-hosted Forgejo,
git-annex data serving, a sibling registered as a data-sovereign distribution channel. It declares
`delegates_to: [datalad]`, so what it can actually do is register a sibling and commit.

`pyinfra` is named 6 times across planner bodies and `forgejo` 5 times, with nothing beneath either.

Data sovereignty is also the arm with the clearest external motivation: cross-border storage and
processing of brain data faces conflicting legal frameworks, and self-hosting is one of the few
mitigations a lab can apply directly.

## What Changes

- A new `liab` capability with a doer owning infrastructure-deployment mechanics.
- A `liab-cli` toolbox for `pyinfra` and `forgejo`.
- `disseminate/liab-deploy` rewired to delegate.
- An e2e assertion: a dry-run deploy plan is produced without touching a real host.

## Capabilities

### New Capabilities
- `liab`: infrastructure deployment — pyinfra operations against declared hosts, Forgejo setup, and
  git-annex special-remote serving for data-sovereign distribution.

### Modified Capabilities
- `disseminate`: `liab-deploy` gains a real delegation target.

## Impact

- New: `plugins/liab/`, `plugins/liab-cli/`
- Modified: `plugins/disseminate/skills/liab-deploy/SKILL.md`, `.claude-plugin/marketplace.json`,
  `tests/e2e-smoke.sh`
- Independent of the other capability changes.
- This is the only capability that acts on machines outside the user's workstation, which drives the
  design below.
