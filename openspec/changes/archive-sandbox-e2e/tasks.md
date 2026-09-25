## 1. Zenodo skill and doer: new version

- [ ] 1.1 `plugins/archive-cli/skills/zenodo/SKILL.md`: add a new-version branch to deposit. When the product already has a Zenodo DOI, call `actions/newversion` on the latest version, read `links.latest_draft`, replace the carried-over files, PUT the full metadata, confirm, and publish. Report the new `doi` and the unchanged `conceptdoi`
- [ ] 1.2 Add a line to the skill's constraints saying that `tests/e2e-smoke.sh` mirrors these steps by number, so a change to a step also changes the test
- [ ] 1.3 `plugins/archive/agents/archive-doer.md`: a deposit for a product that already holds a Zenodo DOI follows the new-version step
- [ ] 1.4 `python3 tests/lint-plugins.py --strict` and its selftest pass

## 2. Readiness gate

- [ ] 2.1 OSF, no credentials (`env -u OSF_TOKEN -u OSF_USERNAME -u OSF_PASSWORD`): exit 1, `result: unminted`, `missing: OSF_TOKEN`
- [ ] 2.2 OSF with `OSF_USERNAME` but no `OSF_PASSWORD`: `missing: OSF_TOKEN` still printed
- [ ] 2.3 OSF with a sentinel `OSF_TOKEN`: the sentinel is never printed. If `python3 -c 'import datalad_osf'` succeeds, assert exit 0; otherwise assert exit 1 with `missing: datalad-osf extension` and no `missing: OSF_TOKEN`
- [ ] 2.4 Print the OSF and DataCite live-deposit skip lines with the reason from design D5

## 3. Zenodo sandbox cycle

- [ ] 3.1 Add `zenodo_cleanup` (delete an unpublished deposition, discard an open edit, ignore errors, never print the token) and call it from `cleanup` before `$WORKDIR` is removed
- [ ] 3.2 Comment each existing sandbox step with the skill step it mirrors; add one `related_identifiers` entry to the first deposit's metadata; track the unpublished id for cleanup until publish succeeds
- [ ] 3.3 Assert that the publish response has `doi` starting with `10.5072/` and has a `conceptdoi`
- [ ] 3.4 Relate (skill step 9): `actions/edit`, GET, merge `isSupplementTo 10.21105/joss.03262` twice, PUT, publish, GET. Assert that both entries are present exactly once, with the relation spelled `isSupplementTo`
- [ ] 3.5 New version (task 1.1): `actions/newversion`, read `links.latest_draft`, upload a changed file under a new name, PUT metadata, publish. Assert a `10.5072/` `doi` that differs from the first, and a `conceptdoi` equal to the first
- [ ] 3.6 Check the failure path by hand: with a token set, force a failing step after create, and confirm the draft is gone from the sandbox account and the token appears nowhere in the output
- [ ] 3.7 Update the header comment of `e2e-smoke.sh` to list the archive blocks and their gates

## 4. Documentation

- [ ] 4.1 Write `docs/testing/archive-sandbox.md`, covering:
  - create a sandbox.zenodo.org account, separate from production;
  - create a personal access token with `deposit:write` and `deposit:actions`;
  - `export DSH_ZENODO_SANDBOX_TOKEN=…`;
  - `source ~/miniconda3/etc/profile.d/conda.sh && conda activate datalad`, then `bash tests/e2e-smoke.sh`;
  - what the sandbox block does, and that each run leaves published sandbox records;
  - what a pass proves and does not prove;
  - a "Last run" section, initially "not yet run"
- [ ] 4.2 Link the doc from `README.md`'s testing section

## 5. Record the result (after the user's run)

- [ ] 5.1 Record in "Last run": the date, the pass/fail count, the two sandbox DOIs and the concept DOI, and whether the new-version draft carried the previous files
- [ ] 5.2 If the run passed, narrow the caveats in `README.md` (lines 253-258 and the Status line) and `docs/motivation.md` (the capability-plane row). They should say that the Zenodo deposit path has run against the sandbox, and that production Zenodo, OSF and DataCite remain unexercised
- [ ] 5.3 If it failed, fix the skill or the test (keep the D1 step comments in sync), then re-run before 5.2
- [ ] 5.4 `openspec validate --all --strict` passes
