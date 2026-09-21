#!/usr/bin/env python3
"""Self-test for lint-plugins.py — negative cases.

A lint that has never failed proves nothing. Each case copies plugins/ + .claude-plugin/ to a
throwaway directory, injects one specific kind of drift, and asserts the lint exits 1 with an
error. The final control case asserts the pristine repo is clean, so the suite cannot pass by
the lint simply erroring on everything.

Add a case here whenever you add a check to lint-plugins.py.

Exit codes: 0 = all cases behaved, 1 = a case did not. Requires pyyaml (via the lint).

Usage: tests/lint-plugins-selftest.py
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINT = os.path.join(REPO, "tests", "lint-plugins.py")
ANSI = re.compile(r"\x1b\[[0-9]*m")


def sub(path, old, new):
    with open(path) as fh:
        text = fh.read()
    assert old in text, f"fixture text not found in {path}: {old!r}"
    with open(path, "w") as fh:
        fh.write(text.replace(old, new, 1))


def drop_marketplace_entry(root, name):
    p = os.path.join(root, ".claude-plugin", "marketplace.json")
    m = json.load(open(p))
    m["plugins"] = [x for x in m["plugins"] if x["name"] != name]
    json.dump(m, open(p, "w"), indent=2)


def drop_manifest_agent(root, plugin, entry):
    p = os.path.join(root, "plugins", plugin, ".claude-plugin", "plugin.json")
    m = json.load(open(p))
    m["agents"] = [a for a in m["agents"] if a != entry]
    json.dump(m, open(p, "w"), indent=2)


def set_agent_model(root, plugin, agent, value):
    """Declare `model: <value>` on an agent, replacing any model it already pins."""
    p = os.path.join(root, "plugins", plugin, "agents", f"{agent}.md")
    _, fm, body = open(p).read().split("---", 2)
    fm = "".join(ln for ln in fm.splitlines(keepends=True) if not ln.startswith("model:"))
    with open(p, "w") as fh:
        fh.write(f"---{fm}model: {value}\n---{body}")


def add_orphan_skill(root):
    d = os.path.join(root, "plugins", "analyze", "skills", "orphan")
    os.makedirs(d)
    with open(os.path.join(d, "SKILL.md"), "w") as fh:
        fh.write('---\nname: orphan\ndescription: "x"\n---\n')


def add_undeclared_import(root):
    """A manifest plus a check script importing something it does not declare.

    Builds its own minimal pyproject.toml rather than copying the real one, so the case states
    exactly what it assumes: `yaml` is declared (as pyyaml, via the alias table) and must pass;
    `requests` is not and must error.
    """
    with open(os.path.join(root, "pyproject.toml"), "w") as fh:
        fh.write('[dependency-groups]\ndev = ["pyyaml>=6.0"]\n')
    os.makedirs(os.path.join(root, "tests"))
    with open(os.path.join(root, "tests", "check-thing.py"), "w") as fh:
        fh.write("import os\nimport yaml\nimport requests\n")


def readme_with(root, text):
    """Write a sandbox README. The lint's doc-claims check is skipped when none exists, so a case
    that exercises it has to supply one."""
    with open(os.path.join(root, "README.md"), "w") as fh:
        fh.write(text)


def readme_row(root, row):
    """A README whose repo-wide counts are correct, so only the per-plugin row can be at fault."""
    readme_with(root, f"**22 plugins**, split across the two planes.\n\n{row}\n")


def archived_change_link(root):
    """A doc linking to a change that has since archived. Both halves have to exist: the archive
    entry the link should have been re-pointed at, and the stale link itself."""
    os.makedirs(os.path.join(root, "openspec", "changes", "archive", "2026-01-01-add-a-thing"))
    readme_with(root, "**22 plugins**\n\nsee [`add-a-thing`](openspec/changes/add-a-thing).\n")


def drop_doer_from_marketplace_prose(root, name):
    p = os.path.join(root, ".claude-plugin", "marketplace.json")
    m = json.load(open(p))
    d = m["metadata"]["description"]
    assert f", {name}" in d, f"{name} not enumerated in the marketplace description"
    m["metadata"]["description"] = d.replace(f", {name}", "", 1)
    json.dump(m, open(p, "w"), indent=2)


WARN_CASES = [
    (
        "argument-hint parses as a list, not a string",
        lambda r: sub(
            f"{r}/plugins/datalad-cli/skills/datalad-status/SKILL.md",
            "argument-hint: '[paths...]'",
            "argument-hint: [paths...]",
        ),
        "argument-hint",
    ),
    (
        "frontmatter is not strict YAML",
        lambda r: sub(
            f"{r}/plugins/datalad-cli/skills/datalad-save/SKILL.md",
            "argument-hint: '[message] [paths...]'",
            "argument-hint: [message] [paths...]",
        ),
        "not strict YAML",
    ),
    (
        "description has no quoted trigger phrases",
        lambda r: sub(
            f"{r}/plugins/analyze/skills/checkpoint/SKILL.md", 'description: >', 'description: no triggers here\nx: >'
        ),
        "quoted trigger phrases",
    ),
]

CASES = [
    (
        "delegates_to names a nonexistent doer",
        lambda r: sub(f"{r}/plugins/analyze/skills/checkpoint/SKILL.md", "delegates_to: [datalad]", "delegates_to: [ghost]"),
    ),
    ("skill on disk, absent from plugin.json", add_orphan_skill),
    (
        "skill name != its directory",
        lambda r: sub(f"{r}/plugins/analyze/skills/checkpoint/SKILL.md", "name: checkpoint", "name: checkpointt"),
    ),
    (
        "invalid STAMPED letter",
        lambda r: sub(f"{r}/plugins/analyze/skills/checkpoint/SKILL.md", "stamped: [T]", "stamped: [T, Z]"),
    ),
    (
        "body delegates to an undeclared doer",
        lambda r: sub(
            f"{r}/plugins/analyze/skills/run-comparison/SKILL.md",
            "delegates_to: [containers, datalad]",
            "delegates_to: [datalad]",
        ),
    ),
    ("plugin missing from marketplace", lambda r: drop_marketplace_entry(r, "bids")),
    ("agent on disk, absent from plugin.json", lambda r: drop_manifest_agent(r, "bids", "./agents/bids-doer.md")),
    (
        "skill with an empty description",
        lambda r: sub(f"{r}/plugins/govern/skills/preregister/SKILL.md", "description: >", 'description: ""\nx: >'),
    ),
    (
        "plugin.json name != its directory",
        lambda r: sub(f"{r}/plugins/bids/.claude-plugin/plugin.json", '"name": "bids"', '"name": "bidz"'),
    ),
    ("check script imports a module pyproject.toml does not declare", add_undeclared_import),
    (
        "README sends contributors to a plugin.yaml that does not exist",
        lambda r: readme_with(r, "**13 plugins**\n\n4. Add the path to `plugin.yaml`\n"),
    ),
    (
        "README's plugin count disagrees with disk",
        lambda r: readme_with(r, "**11 plugins**, split across the two planes.\n"),
    ),
    (
        "marketplace claims a STAMPED principle outside the closed set",
        lambda r: sub(
            f"{r}/.claude-plugin/marketplace.json",
            "Advances STAMPED Distributability.",
            "Advances STAMPED Metadata.",
        ),
    ),
    (
        "marketplace's workflow-planner count disagrees with disk",
        lambda r: sub(
            f"{r}/.claude-plugin/marketplace.json",
            "6 workflow-plane planner plugins",
            "2 workflow-plane planner plugins",
        ),
    ),
    (
        "marketplace counts planner *skills* where the checkable number is plugins",
        lambda r: sub(
            f"{r}/.claude-plugin/marketplace.json",
            "6 workflow-plane planner plugins",
            "6 workflow-plane planner skills",
        ),
    ),
    (
        "plugin.json lists a skill that does not exist",
        lambda r: sub(
            f"{r}/plugins/govern/.claude-plugin/plugin.json", '"./skills/qc-review"', '"./skills/qc-reviewww"'
        ),
    ),
    ("agent declares a model outside the allowed set", lambda r: set_agent_model(r, "bids", "bids-doer", "haikoo")),
    ("mutating doer declares a model", lambda r: set_agent_model(r, "datalad", "datalad-doer", "haiku")),
    (
        "README's per-plugin skill count disagrees with disk",
        lambda r: readme_row(r, "| `bids-cli` | toolbox | validator | 7 skills, one per command | S, M |"),
    ),
    ("a doc links to a change that has been archived", archived_change_link),
    (
        "marketplace omits a capability doer from its enumerated list",
        lambda r: drop_doer_from_marketplace_prose(r, "liab"),
    ),
]


def run_lint(root, *extra):
    proc = subprocess.run([sys.executable, LINT, root, *extra], capture_output=True, text=True)
    out = ANSI.sub("", proc.stdout)
    lines = [ln.strip() for ln in out.splitlines()]
    return (
        proc.returncode,
        [ln[6:].strip() for ln in lines if ln.startswith("ERROR")],
        [ln[5:].strip() for ln in lines if ln.startswith("WARN")],
    )


def in_sandbox(mutate, *lint_args):
    tmp = tempfile.mkdtemp()
    root = os.path.join(tmp, "repo")
    os.makedirs(root)
    shutil.copytree(f"{REPO}/plugins", f"{root}/plugins")
    shutil.copytree(f"{REPO}/.claude-plugin", f"{root}/.claude-plugin")
    try:
        mutate(root)
        return run_lint(root, *lint_args)
    finally:
        shutil.rmtree(tmp)


def main():
    failures = 0
    total = 0

    def record(ok, label, detail):
        nonlocal failures, total
        total += 1
        if not ok:
            failures += 1
        print(f"  {'PASS' if ok else 'FAIL'}  {label:<44} -> {detail[:104]}")

    print("ERROR cases (must fail the lint):")
    for label, mutate in CASES:
        code, errs, _ = in_sandbox(mutate)
        record(code == 1 and bool(errs), label, errs[0] if errs else f"exit={code}, no ERROR raised")

    print("\nWARN cases (must warn, but not fail unless --strict):")
    for label, mutate, needle in WARN_CASES:
        code, errs, warns = in_sandbox(mutate)
        hit = next((w for w in warns if needle in w), None)
        ok = code == 0 and not errs and hit is not None
        detail = hit if hit else f"exit={code}, errors={len(errs)}, no WARN matching {needle!r}"
        record(ok, label, detail)
        strict_code, _, _ = in_sandbox(mutate, "--strict")
        record(strict_code == 1, f"{label} (--strict)", f"exit={strict_code}")

    print("\nControl:")
    code, errs, warns = run_lint(REPO)
    record(
        code == 0 and not errs and not warns,
        "pristine repo is clean",
        f"exit={code}, {len(errs)} error(s), {len(warns)} warning(s)",
    )

    print(f"\n{total - failures}/{total} self-test cases passed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
