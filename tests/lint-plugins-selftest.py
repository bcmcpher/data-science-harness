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


def add_orphan_skill(root):
    d = os.path.join(root, "plugins", "analyze", "skills", "orphan")
    os.makedirs(d)
    with open(os.path.join(d, "SKILL.md"), "w") as fh:
        fh.write('---\nname: orphan\ndescription: "x"\n---\n')


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
    (
        "plugin.json lists a skill that does not exist",
        lambda r: sub(
            f"{r}/plugins/govern/.claude-plugin/plugin.json", '"./skills/qc-review"', '"./skills/qc-reviewww"'
        ),
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
