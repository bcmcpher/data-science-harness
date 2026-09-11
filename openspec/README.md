# OpenSpec in data-science-harness

This directory is the record of *intent* for the harness: what each part is required to do
(`specs/`), and what we have decided to change next (`changes/`). It was introduced as a brownfield
retrofit — the specs describe a system that already exists and is already linted, so a requirement
here should be readable as a claim about the current repository, not a wish.

```
openspec/
├── specs/<capability>/spec.md   requirements as they stand today
└── changes/<change-id>/         proposal.md, design.md, specs/ deltas, tasks.md
    └── archive/                 changes merged back into specs/
```

## Naming: two different things are called a "capability"

OpenSpec calls each folder under `specs/` a **capability**. This repository separately uses
**capability plane** to mean the thin tool wrappers (`datalad`, `bids`, `containers`, …) as opposed
to the **workflow plane** (`govern`, `curate`, `analyze`, …). These are unrelated senses of the word.

The convention here: **spec names mirror the thing they describe**, usually a plugin directory name.
`openspec/specs/datalad/` describes a capability-plane plugin; `openspec/specs/analyze/` describes a
workflow-plane one; `openspec/specs/project-ledger/` describes neither, it describes a schema. The
folder being under `specs/` says nothing about which plane its subject belongs to.

`project-mgmt` is named that way rather than `project` to avoid colliding with OpenSpec's own
project-level vocabulary; it describes the `plugins/project/` plugin.

## What the specs cover

| Group | Specs |
|---|---|
| Workflow plane | `govern`, `project-mgmt`, `curate`, `analyze`, `process`, `disseminate` |
| Capability plane | `datalad`, `nipoppy`, `bids`, `containers`, `archive` |
| Cross-cutting | `project-ledger`, `skill-format`, `harness-distribution`, `structural-lint`, `dependency-environment` |
| Research communication | `literature-record`, `evaluation-protocol`, `publication` |

## Conventions

- **Ground requirements in a check that exists.** The retrofit's value is that a spec restates
  something enforceable — `tests/lint-plugins.py`'s error conditions, `tests/e2e-smoke.sh`'s
  assertions, `schemas/project.schema.json`. A requirement grounded in nothing is a wish, and wishes
  belong in a change proposal.
- **Specs describe the present.** If something is not built, it is a change, not a spec.
- **Additive, not breaking.** The `project:` header and the append-only `log:` stay as they are.
- **Ledger-first.** Formalize the schema before the skills that write to it.
- **One step deep before the next step wide.** Finish a capability end-to-end — doer, toolbox,
  planner rewired, assertion — before starting another. A half-built capability is worse than an
  absent one, because the planner will try to use it.
- **A capability change is done when its planner's `delegates_to:` grows.** That field is the
  observable signal that a conceptual step gained a real tool. If it still reads `[datalad]`,
  nothing shipped.
- **Dual-harness from the start.** Anything added must survive the OpenCode frontmatter rewrite in
  `bin/install.sh`.

## Working with it

```bash
openspec list                 # changes
openspec list --specs         # specs
openspec show <id>            # a change or spec
openspec status --change <id> # artifact completion
openspec validate --all --strict --no-interactive
openspec archive <change>     # merge deltas into specs/ once implemented
```

Slash commands `/opsx:propose`, `/opsx:explore`, `/opsx:apply`, and `/opsx:archive` are installed for
Claude Code and OpenCode.

## Requirement format

Every `### Requirement:` text must contain SHALL or MUST in its opening sentence — the validator
checks for it — and must carry at least one `#### Scenario:` with `**WHEN**` / `**THEN**` bullets.
