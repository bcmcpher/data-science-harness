## Context

`plugins/datalad-cli/` is the reference shape: 19 skills, one per verb, each `user-invocable: true`
with `allowed-tools` scoped to what that verb needs, plus six shared reference documents. The doer
reads the matching skill and follows its steps. `bids` and `nipoppy` both deviate from that shape,
in opposite directions.

`plugins/disseminate/references/equator-guidelines.md` exists as a single file; COBIDAS has nothing.

## Goals / Non-Goals

**Goals:**
- `bids-validator` invocable on its own and assertable in the e2e test.
- `nipoppy-cli` structured by command class so the doer's classification rule has something to point
  at.
- Guideline text bundled, so checklist items come from a fixed source.

**Non-Goals:**
- Changing the doers' contracts. `bids` stays read-only; `nipoppy` still hands mutating commands to
  the datalad doer.
- Vendoring full guideline documents where licensing does not permit it — reference the canonical
  source and bundle only what may be redistributed.

## Decisions

- **Split `nipoppy-cli` by command class, not by every subcommand.** The nipoppy doer already
  distinguishes read-only, mutating, and setup commands, and that distinction is the one that changes
  behaviour. Splitting further would produce skills with nothing to say.
- **`bids-validator` is one skill, not a toolbox.** BIDS validation is a single verb; the toolbox
  exists so the verb is addressable, not to manufacture symmetry with `datalad-cli`.
- **Bundle checklist items, cite the source.** Where a guideline's full text cannot be redistributed,
  the reference file carries the item list and points at the canonical URL — the same approach
  `docs/writing/index.md` already takes with its attribution note.
- **Reference sets live with the plugin that cites them**, matching the existing
  `plugins/disseminate/references/` layout, so `bin/install.sh` copies them with the bundle.

## Risks / Trade-offs

- **Guideline licensing varies.** EQUATOR checklists and COBIDAS have different redistribution terms;
  each reference file must state what it contains and where the authoritative version lives.
- **Splitting `nipoppy-cli` moves knowledge out of a working doer**, with the same doer-to-toolbox
  drift risk as the archive split, and no lint check covering it.
- **This change touches four planners**, so it is broader than it is deep. It is the one phase where
  the one-step-deep principle argues for doing `bids` first and stopping to verify before touching
  `nipoppy`.
