## 0. Minimal working core

All of it; it is four files and no behaviour.

## 1. Declare the split

- [x] 1.1 `LICENSE-CONTENT.md` — the CC BY 4.0 notice in the form Creative Commons specifies, linking
      the canonical legal code. Do not transcribe the legal text.
- [x] 1.2 `REUSE.toml` mapping paths to SPDX identifiers, with a comment saying `LICENSES/` is
      deliberately absent and why.
- [x] 1.3 A `## License` section in the README stating both, with the path boundary spelled out.
- [x] 1.4 Note in the root `LICENSE` — or beside it in the README — that MIT covers the code and
      points at the content licence, so a reader landing on `LICENSE` first is not misled.

## 2. Verify

- [x] 2.1 Every top-level path is covered by exactly one `REUSE.toml` entry.
- [x] 2.2 `paper/myst.yml`'s declaration agrees with `REUSE.toml` for `paper/`.
- [x] 2.3 `python3 tests/lint-plugins.py --strict` still clean — no plugin content changed.

## Notes

- Verified every top-level path is covered by exactly one `REUSE.toml` block, except `LICENSE`
  itself, which is the MIT text. `paper/myst.yml` agrees with the repository-wide split.
- `LICENSE` now opens with a line saying it covers the code and pointing at `LICENSE-CONTENT.md`,
  so a reader who lands there first is not misled into thinking MIT covers the prose.
- `reuse lint` will still report non-compliance: `LICENSES/` is absent by design, because the CC BY
  4.0 legal code has to be copied verbatim from the canonical source rather than reconstructed.
  That is the follow-up, and it is a copy job, not a decision.
