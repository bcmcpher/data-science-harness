## 1. The archive-cli toolbox

- [ ] 1.1 `plugins/archive-cli/skills/osf/SKILL.md` — `datalad create-sibling-osf` + push, reading the
      DOI from the OSF project; cross-reference `datalad-cli/skills/datalad-siblings`.
- [ ] 1.2 `plugins/archive-cli/skills/zenodo/SKILL.md` — create deposition, upload, publish, read `doi`.
- [ ] 1.3 `plugins/archive-cli/skills/datacite/SKILL.md` — MDS/REST minting plus `RelatedIdentifier`
      creation and lookup with `relationType` values.
- [ ] 1.4 `plugins/archive-cli/.claude-plugin/plugin.json` and a `.claude-plugin/marketplace.json` entry.

## 2. Slim the doer

- [ ] 2.1 Replace the inline backend detail in `plugins/archive/agents/archive-doer.md` with a
      toolbox table pointing at the three skills, matching how `datalad-doer` references `datalad-cli`.
- [ ] 2.2 Keep the five-step procedure, the `unminted` contract, and the pre-publish confirmation in
      the doer unchanged.

## 3. Rewire link-outputs

- [ ] 3.1 Move the `RelatedIdentifier` mechanics out of
      `plugins/disseminate/skills/link-outputs/SKILL.md` and into a delegation to the archive doer.
- [ ] 3.2 Confirm frontmatter and prose agree in both directions, as the lint requires.

## 4. Verify

- [ ] 4.1 `python3 tests/lint-plugins.py` — 0 errors.
- [ ] 4.2 `tests/e2e-smoke.sh`: assert a mint attempt with no credentials reports `unminted` and the
      release is recorded without a DOI.
- [ ] 4.3 Gate the credentialed branch behind an environment variable and a sandbox endpoint, so the
      test never creates a permanent public record by default.
