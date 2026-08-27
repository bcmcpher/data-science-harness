#!/usr/bin/env python3
"""Structural check for the evaluation fixtures under bench/.

No probe has ever been run (see docs/evaluation.md), so nothing here executes a benchmark. What
this catches is the failure mode a fixture set has *before* it is ever run: broken ground truth.

A routing task declares the planner skill that should be selected and the doers that planner should
reach. If that expectation does not match the planner's own `delegates_to`, or names a plugin that
provides no agent, the fixture would silently score every model wrong — and the more capable the
model, the worse it would score. That is the same class of defect `tests/lint-plugins.py` catches
for skills at `check_skill`, applied to the fixtures instead.

Checks:
  probes    parse; required keys present; `control` declared with a known kind; `invalidators`
            non-empty (a probe that cannot say how it breaks is not specified)
  tasks     parse; declare a probe; every task has an id and a prompt; ids unique within a suite;
            for routing tasks, expected_skill exists on disk, expected_delegates_to matches that
            skill's declared delegates_to, and every named plugin provides an agent
  rubrics   parse; dimensions declare id, evidence, and anchors

Exit codes: 0 = clean, 1 = problems found (or usage error), 2 = skipped (pyyaml not installed).

Usage: tests/check-bench-fixtures.py [-v] [repo_root]
"""
import os
import re
import sys

try:
    import yaml
except ImportError as exc:  # optional dep -> skip, don't fail a test suite
    print(f"SKIP: {exc} (need pyyaml)", file=sys.stderr)
    sys.exit(2)

PROBE_REQUIRED = ("id", "question", "metrics", "control", "invalidators")
CONTROL_KINDS = {"harness_off", "recorded_baseline", "absolute"}
METRIC_TYPES = {"exact", "graded", "judged", "binary", "measured"}

problems: list[tuple[str, str]] = []  # (path, message)
counts = {"probes": 0, "suites": 0, "tasks": 0, "rubrics": 0}


def problem(path: str, msg: str) -> None:
    problems.append((path, msg))


def load(root: str, path: str):
    rel = os.path.relpath(path, root)
    try:
        with open(path, encoding="utf-8") as fh:
            return rel, yaml.safe_load(fh)
    except Exception as exc:  # noqa: BLE001 - report any parse failure the same way
        problem(rel, f"does not parse as YAML: {exc}")
        return rel, None


def agent_providing_plugins(root: str) -> set[str]:
    """Plugin directories that actually contain an agent — the same resolution rule
    tests/lint-plugins.py uses when checking a skill's delegates_to."""
    plugins_dir = os.path.join(root, "plugins")
    found = set()
    if not os.path.isdir(plugins_dir):
        return found
    for name in os.listdir(plugins_dir):
        agents = os.path.join(plugins_dir, name, "agents")
        if os.path.isdir(agents) and any(f.endswith(".md") for f in os.listdir(agents)):
            found.add(name)
    return found


_DELEGATES = re.compile(r"^delegates_to:\s*\[(.*?)\]\s*$", re.M)


def declared_delegates(skill_path: str) -> list[str] | None:
    """The skill's declared delegates_to, or None if the file has no frontmatter."""
    with open(skill_path, encoding="utf-8") as fh:
        text = fh.read()
    parts = text.split("---")
    if len(parts) < 3:
        return None
    match = _DELEGATES.search(parts[1])
    if not match:
        return []
    return [item.strip() for item in match.group(1).split(",") if item.strip()]


def check_probe(root: str, path: str) -> None:
    rel, data = load(root, path)
    if data is None:
        return
    counts["probes"] += 1

    stem = os.path.splitext(os.path.basename(path))[0]
    for key in PROBE_REQUIRED:
        if key not in data:
            problem(rel, f"missing required key '{key}'")
    if data.get("id") not in (None, stem):
        problem(rel, f"id '{data['id']}' does not match filename '{stem}'")

    control = data.get("control")
    if isinstance(control, dict):
        kind = control.get("kind")
        if kind not in CONTROL_KINDS:
            problem(rel, f"control.kind '{kind}' is not one of {sorted(CONTROL_KINDS)}")
        if not control.get("description"):
            problem(rel, "control has no description")
    elif "control" in data:
        problem(rel, "control must be a mapping with 'kind' and 'description'")

    if not data.get("invalidators"):
        problem(rel, "invalidators is empty — a probe that cannot say how it breaks is not specified")

    for metric in data.get("metrics") or []:
        if not isinstance(metric, dict):
            problem(rel, f"metric is not a mapping: {metric!r}")
            continue
        mid = metric.get("id", "<unnamed>")
        if not metric.get("definition"):
            problem(rel, f"metric '{mid}' has no definition")
        mtype = metric.get("type")
        if mtype not in METRIC_TYPES:
            problem(rel, f"metric '{mid}' type '{mtype}' is not one of {sorted(METRIC_TYPES)}")
        if mtype == "judged" and not data.get("judging"):
            problem(rel, f"metric '{mid}' is judged but the probe declares no judging procedure")


def check_task_suite(root: str, path: str, providers: set[str]) -> None:
    rel, data = load(root, path)
    if data is None:
        return
    counts["suites"] += 1

    probe = data.get("probe")
    if not probe:
        problem(rel, "suite declares no probe")
    elif not os.path.isfile(os.path.join(root, "bench", "probes", f"{probe}.yaml")):
        problem(rel, f"probe '{probe}' has no fixture in bench/probes/")

    seen: set[str] = set()
    for task in data.get("tasks") or []:
        counts["tasks"] += 1
        tid = task.get("id")
        if not tid:
            problem(rel, f"task has no id: {task!r}")
            continue
        if tid in seen:
            problem(rel, f"duplicate task id '{tid}'")
        seen.add(tid)
        if not task.get("prompt"):
            problem(rel, f"task '{tid}' has no prompt")

        if probe != "routing":
            continue

        expected = task.get("expected_skill")
        if not expected:
            problem(rel, f"task '{tid}' has no expected_skill")
            continue
        if "/" not in expected:
            problem(rel, f"task '{tid}' expected_skill '{expected}' is not 'plugin/skill'")
            continue

        plugin, skill = expected.split("/", 1)
        skill_path = os.path.join(root, "plugins", plugin, "skills", skill, "SKILL.md")
        if not os.path.isfile(skill_path):
            problem(rel, f"task '{tid}' expects '{expected}', which is not on disk")
            continue

        declared = declared_delegates(skill_path)
        if declared is None:
            problem(rel, f"task '{tid}': '{expected}' has no parseable frontmatter")
            continue

        wanted = task.get("expected_delegates_to")
        if wanted is None:
            problem(rel, f"task '{tid}' has no expected_delegates_to")
            continue
        if sorted(wanted) != sorted(declared):
            problem(
                rel,
                f"task '{tid}' expects delegates_to {sorted(wanted)} but '{expected}' "
                f"declares {sorted(declared)} — ground truth is stale",
            )
        for target in wanted:
            if target not in providers:
                problem(rel, f"task '{tid}': '{target}' provides no agent, so it can never be reached")


def check_rubric(root: str, path: str) -> None:
    rel, data = load(root, path)
    if data is None:
        return
    counts["rubrics"] += 1

    stem = os.path.splitext(os.path.basename(path))[0]
    if data.get("id") not in (None, stem):
        problem(rel, f"id '{data['id']}' does not match filename '{stem}'")

    dimensions = data.get("dimensions")
    if not dimensions:
        problem(rel, "rubric declares no dimensions")
        return
    for dim in dimensions:
        if not isinstance(dim, dict):
            problem(rel, f"dimension is not a mapping: {dim!r}")
            continue
        did = dim.get("id", "<unnamed>")
        if not dim.get("evidence"):
            problem(rel, f"dimension '{did}' has no evidence — what is inspected?")
        if not dim.get("anchors"):
            problem(rel, f"dimension '{did}' has no anchors — scores would not be reproducible")


def walk(root: str, subdir: str):
    directory = os.path.join(root, "bench", subdir)
    if not os.path.isdir(directory):
        return
    for name in sorted(os.listdir(directory)):
        if name.endswith((".yaml", ".yml")):
            yield os.path.join(directory, name)


def main(argv: list[str]) -> int:
    verbose = "-v" in argv
    args = [a for a in argv if not a.startswith("-")]
    root = os.path.abspath(args[0]) if args else os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..")
    )

    if not os.path.isdir(os.path.join(root, "bench")):
        print(f"ERROR: no bench/ directory under {root}", file=sys.stderr)
        return 1

    providers = agent_providing_plugins(root)
    if verbose:
        print(f"agent-providing plugins: {sorted(providers)}")

    for path in walk(root, "probes"):
        check_probe(root, path)
    for path in walk(root, "tasks"):
        check_task_suite(root, path, providers)
    for path in walk(root, "rubrics"):
        check_rubric(root, path)

    for rel, msg in problems:
        print(f"ERROR {rel}: {msg}")

    summary = (
        f"{counts['probes']} probes, {counts['suites']} suites "
        f"({counts['tasks']} tasks), {counts['rubrics']} rubrics"
    )
    if problems:
        print(f"\n{summary} — {len(problems)} problem(s)")
        return 1
    print(f"{summary} — clean")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
