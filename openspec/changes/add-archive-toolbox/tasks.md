## 0. Staging

The change lands in three commits, then is archived once:

1. **Zenodo core** — 1.2, 1.4, 1.5, 2.1-2.2, 4.1-4.3. Zenodo is the shortest path to a real DOI on a
   real product, and the doer slimming is the pattern the other two backends then follow rather
   than invent.
2. **OSF, DataCite, and the link-outputs rewire** — 1.1, 1.3, 1.6, 3.1-3.2. The rewire depends on the
   relation write paths existing.
3. **Documentation** — 5.1-5.2.

Decisions settled on 2026-09-15 before implementation: stage as above; an unresolvable external
target is recorded and flagged rather than refused; relations are written to the archive that owns
the source DOI, not only to DataCite; the credential gate is tested through a readiness script,
because `tests/e2e-smoke.sh` runs commands and cannot observe an agent.

## 1. The archive-cli toolbox

- [x] 1.1 `plugins/archive-cli/skills/osf/SKILL.md` — `datalad create-sibling-osf` + push, reading the
      DOI from the OSF project; cross-reference `datalad-cli/skills/datalad-siblings`.
- [x] 1.2 `plugins/archive-cli/skills/zenodo/SKILL.md` — create deposition, upload, publish, read `doi`.
- [x] 1.3 `plugins/archive-cli/skills/datacite/SKILL.md` — REST minting under a registered prefix,
      `RelatedIdentifier` creation, and public lookup with `relationType` values.
- [x] 1.4 `plugins/archive-cli/.claude-plugin/plugin.json` and a `.claude-plugin/marketplace.json` entry.
- [x] 1.5 `plugins/archive-cli/scripts/check-readiness.sh <osf|zenodo|datacite>` — presence-only,
      offline, never prints a secret; exit 0 ready, 1 unminted, 2 usage.
- [x] 1.6 Relation write paths: `related_identifiers` in the `zenodo` skill; the `datacite` skill for
      own-prefix DOIs; any other owner answers `ledger-only`.

## 2. Slim the doer

- [x] 2.1 Replace the inline backend detail in `plugins/archive/agents/archive-doer.md` with a
      toolbox table pointing at the three skills, matching how `datalad-doer` references `datalad-cli`.
- [x] 2.2 Keep the five-step procedure, the `unminted` contract, and the pre-publish confirmation in
      the doer unchanged; take readiness from `check-readiness.sh`, which also covers DataCite.

## 3. Rewire link-outputs

- [x] 3.1 Move the `RelatedIdentifier` mechanics out of
      `plugins/disseminate/skills/link-outputs/SKILL.md` and into a delegation to the archive doer;
      record an unresolvable external target and flag it in the log note and report.
- [x] 3.2 Confirm frontmatter and prose agree in both directions, as the lint requires.

## 4. Verify

- [x] 4.1 `python3 tests/lint-plugins.py` — 0 errors.
- [x] 4.2 `tests/e2e-smoke.sh`: with credentials cleared, `check-readiness.sh zenodo` reports
      `unminted` naming the missing item, and the release is recorded without a DOI.
- [x] 4.3 Gate the credentialed branch behind `DSH_ZENODO_SANDBOX_TOKEN` and the Zenodo sandbox, so
      the test never creates a permanent public record by default. *(The gate is verified to skip;
      the sandbox branch itself has not been run against the live sandbox.)*

## 5. Documentation

- [x] 5.1 Retire the "archive has no toolbox" claims: `README.md` (status line, plugin table, plugin
      count, capability-plane paragraph, "Where the harness stands"), `docs/motivation.md`, and
      `docs/funding/catalyst-fit.md`.
- [ ] 5.2 On archive, update the `archive` spec's Purpose, which says the toolbox is not yet built.
