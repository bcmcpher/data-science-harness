#!/usr/bin/env python3
"""Structural lint for the harness's plugins, skills, and doer agents.

Static checks only — no dataset, no tools, no network. This catches the drift class that
nothing else does: a skill whose `delegates_to` names a doer that does not exist, a skill
added to disk but never registered in its plugin.json (so it never loads), a plugin missing
from the marketplace, a `name:` that no longer matches its directory, a check script that
imports a module no manifest declares, a README that tells contributors to edit a file that
does not exist.

Two check severities:
  ERROR — the harness is broken or will silently not load something. Fails the run.
  WARN  — a convention drift worth fixing. Does not fail unless --strict.

Vendored CLI toolboxes (plugins named `*-cli`) are held only to the universal checks
(name/description); the harness-specific frontmatter (plane/stamped/delegates_to) and the
planner section layout are not expected of them.

Exit codes: 0 = clean, 1 = errors found (or usage error), 2 = skipped (pyyaml not installed).

Usage: tests/lint-plugins.py [-v] [--strict] [repo_root]
"""
import ast
import json
import os
import re
import sys

try:
    import yaml
except ImportError as exc:  # optional dep -> skip, don't fail a test suite
    print(f"SKIP: {exc} (need pyyaml)", file=sys.stderr)
    sys.exit(2)

STAMPED_LETTERS = set("STAMPED")
PLANES = {"workflow", "capability"}
# Bare aliases the Claude Code source layout accepts for an agent's `model:`. bin/install.sh maps each
# to OpenCode's provider-prefixed form; a value missing from that map is stripped on install.
MODELS = {"haiku", "sonnet", "opus", "fable"}
# Agents that only read and report. Only these may pin `model:`; a doer that can mutate a dataset or
# publish runs on the session default.
PINNABLE_AGENTS = {"bids-doer", "coordinator"}
KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
PLANNER_SECTIONS = ("## When to use", "## Steps", "## Constraints")
DESCRIPTION_MAX = 1024
CHECK_SCRIPT_DIRS = ("tests", "schemas")

# Third-party modules whose import name differs from the distribution providing it. There is no
# way to derive this without installing the package, so it is a hand-kept list; extend it when a
# check script imports something new.
IMPORT_ALIASES = {"yaml": "pyyaml"}

findings: list[tuple[str, str, str]] = []  # (severity, path, message)
counts = {"skills": 0, "agents": 0, "plugins": 0}


def error(path: str, msg: str) -> None:
    findings.append(("ERROR", path, msg))


def warn(path: str, msg: str) -> None:
    findings.append(("WARN", path, msg))


def rel(root: str, path: str) -> str:
    return os.path.relpath(path, root)


# `argument-hint: [a] [b]` — two flow sequences on one line — is what Claude Code's lenient
# frontmatter parser accepts but strict YAML rejects. Quote such values on a retry so the rest
# of the frontmatter still gets checked; the file is reported as a portability WARN, not an error.
_TWO_FLOW_SEQS = re.compile(r"^([A-Za-z0-9_-]+):[ \t]*(\[.*\].*)$")


def _relax(raw: str) -> str:
    out = []
    for line in raw.splitlines():
        m = _TWO_FLOW_SEQS.match(line)
        if m and "] [" in m.group(2):
            out.append(f"{m.group(1)}: '{m.group(2).replace(chr(39), chr(39) * 2)}'")
        else:
            out.append(line)
    return "\n".join(out)


def read_frontmatter(root: str, path: str) -> dict | None:
    """Parse the leading `---` YAML block. Returns None after recording a finding if malformed."""
    p = rel(root, path)
    with open(path) as fh:
        text = fh.read()
    end = text.find("\n---", 3) if text.startswith("---") else -1
    if end == -1:
        error(p, "missing or unterminated `---` frontmatter block")
        return None

    raw = text[3:end]
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        try:
            data = yaml.safe_load(_relax(raw))
        except yaml.YAMLError:
            error(p, f"frontmatter is not valid YAML: {str(exc).splitlines()[0]}")
            return None
        warn(p, "frontmatter is not strict YAML (quote the `argument-hint` value); portable only to lenient parsers")

    if not isinstance(data, dict):
        error(p, "frontmatter is not a YAML mapping")
        return None
    return data


def body_of(path: str) -> str:
    with open(path) as fh:
        text = fh.read()
    end = text.find("\n---", 3) if text.startswith("---") else -1
    return text[end + 4 :] if end != -1 else text


# ----------------------------------------------------------------------------- skills
def check_skill(root: str, path: str, plugin_name: str, doers: dict[str, list[str]]) -> None:
    """path is a .../skills/<dir>/SKILL.md. `doers` maps plugin name -> its agent files."""
    counts["skills"] += 1
    p = rel(root, path)
    skill_dir = os.path.basename(os.path.dirname(path))
    is_harness = not plugin_name.endswith("-cli")

    fm = read_frontmatter(root, path)
    if fm is None:
        return

    name = fm.get("name")
    if not name:
        error(p, "frontmatter is missing `name`")
    else:
        if name != skill_dir:
            error(p, f"`name: {name}` does not match its directory `{skill_dir}/`")
        if not KEBAB.match(str(name)):
            warn(p, f"`name: {name}` is not kebab-case")

    desc = (fm.get("description") or "").strip()
    if not desc:
        error(p, "frontmatter is missing `description` (this is how the skill gets triggered)")
    else:
        if len(desc) > DESCRIPTION_MAX:
            warn(p, f"description is {len(desc)} chars (>{DESCRIPTION_MAX}); harnesses may truncate it")
        if '"' not in desc:
            warn(p, "description has no quoted trigger phrases (e.g. 'Trigger on \"run the comparison\"')")

    # `argument-hint: [paths...]` is valid YAML but parses as a one-element LIST, not the usage
    # string it looks like. Quote it so every harness sees the same value.
    hint = fm.get("argument-hint")
    if hint is not None and not isinstance(hint, str):
        warn(p, f"`argument-hint` parses as {type(hint).__name__}, not a string — quote the value")

    if not is_harness:
        return

    # --- harness-specific frontmatter
    plane = fm.get("plane")
    if plane is None:
        warn(p, "missing `plane:` (workflow | capability)")
    elif plane not in PLANES:
        error(p, f"`plane: {plane}` is not one of {sorted(PLANES)}")

    stamped = fm.get("stamped")
    if stamped is None:
        warn(p, "missing `stamped:` (the STAMPED letters this skill advances)")
    elif not isinstance(stamped, list):
        error(p, f"`stamped:` must be a list, got {type(stamped).__name__}")
    else:
        bad = [x for x in stamped if str(x) not in STAMPED_LETTERS]
        if bad:
            error(p, f"`stamped:` has invalid letter(s) {bad}; valid are {sorted(STAMPED_LETTERS)}")
        if len(stamped) != len(set(map(str, stamped))):
            warn(p, "`stamped:` has duplicate letters")

    declared = fm.get("delegates_to") or []
    if not isinstance(declared, list):
        error(p, f"`delegates_to:` must be a list, got {type(declared).__name__}")
        declared = []
    for target in declared:
        if str(target) not in doers:
            error(p, f"`delegates_to: {target}` — no plugin `{target}` with an agents/ doer exists")

    # --- body: planner layout + delegation consistency
    body = body_of(path)
    for section in PLANNER_SECTIONS:
        if section not in body:
            warn(p, f"body is missing the `{section}` section (see templates/skill/SKILL.md)")

    # A doer named in prose ("delegate to the **datalad** doer") must be declared in frontmatter,
    # otherwise the two drift apart. Strip emphasis so `**datalad doer**` matches too.
    plain = body.replace("*", "")
    mentioned = {d for d in doers if re.search(rf"\b{re.escape(d)}\s+doer\b", plain, re.I)}
    for d in sorted(mentioned - set(map(str, declared))):
        error(p, f"body delegates to the `{d}` doer but `delegates_to:` does not list it")
    for d in sorted(set(map(str, declared)) & set(doers) - mentioned):
        warn(p, f"`delegates_to: {d}` is declared but the body never delegates to that doer")


# ----------------------------------------------------------------------------- agents
def check_agent(root: str, path: str) -> None:
    counts["agents"] += 1
    p = rel(root, path)
    stem = os.path.splitext(os.path.basename(path))[0]

    fm = read_frontmatter(root, path)
    if fm is None:
        return

    name = fm.get("name")
    if not name:
        error(p, "frontmatter is missing `name`")
    elif name != stem:
        error(p, f"`name: {name}` does not match its filename `{stem}.md`")

    if not (fm.get("description") or "").strip():
        error(p, "frontmatter is missing `description` (this is how the doer gets selected)")
    if not fm.get("tools"):
        warn(p, "no `tools:` declared — the doer will inherit the full tool set")

    model = fm.get("model")
    if model is not None:
        if str(model) not in MODELS:
            error(p, f"`model: {model}` is not an allowed value ({', '.join(sorted(MODELS))})")
        if stem not in PINNABLE_AGENTS:
            error(p, f"declares `model: {model}` but only read-only agents may pin a model")


# ----------------------------------------------------------------------------- plugins
def check_plugin(root: str, plugin_dir: str, doers: dict[str, list[str]]) -> str | None:
    """Validate one plugin's manifest against what is on disk. Returns its declared name."""
    counts["plugins"] += 1
    plugin_name = os.path.basename(plugin_dir)
    manifest_path = os.path.join(plugin_dir, ".claude-plugin", "plugin.json")
    p = rel(root, manifest_path)

    if not os.path.exists(manifest_path):
        error(rel(root, plugin_dir), "no .claude-plugin/plugin.json — the plugin will not load")
        return None
    try:
        with open(manifest_path) as fh:
            manifest = json.load(fh)
    except json.JSONDecodeError as exc:
        error(p, f"is not valid JSON: {exc}")
        return None

    declared_name = manifest.get("name")
    if declared_name != plugin_name:
        error(p, f"`name: {declared_name}` does not match its directory `{plugin_name}/`")
    for field in ("description", "version"):
        if not manifest.get(field):
            warn(p, f"missing `{field}`")

    # listed -> on disk
    listed_skills = {os.path.normpath(s) for s in manifest.get("skills", [])}
    for entry in sorted(listed_skills):
        if not os.path.exists(os.path.join(plugin_dir, entry, "SKILL.md")):
            error(p, f"lists skill `{entry}` but {entry}/SKILL.md does not exist")
    listed_agents = {os.path.normpath(a) for a in manifest.get("agents", [])}
    for entry in sorted(listed_agents):
        if not os.path.exists(os.path.join(plugin_dir, entry)):
            error(p, f"lists agent `{entry}` but that file does not exist")

    # on disk -> listed (an unregistered skill/agent silently never loads)
    skills_root = os.path.join(plugin_dir, "skills")
    if os.path.isdir(skills_root):
        for d in sorted(os.listdir(skills_root)):
            if os.path.exists(os.path.join(skills_root, d, "SKILL.md")):
                if os.path.normpath(f"./skills/{d}") not in listed_skills:
                    error(p, f"skills/{d}/ exists on disk but is not listed in `skills[]` — it will not load")
    agents_root = os.path.join(plugin_dir, "agents")
    if os.path.isdir(agents_root):
        for f in sorted(os.listdir(agents_root)):
            if f.endswith(".md") and os.path.normpath(f"./agents/{f}") not in listed_agents:
                error(p, f"agents/{f} exists on disk but is not listed in `agents[]` — it will not load")

    # contents
    if os.path.isdir(skills_root):
        for d in sorted(os.listdir(skills_root)):
            skill_md = os.path.join(skills_root, d, "SKILL.md")
            if os.path.exists(skill_md):
                check_skill(root, skill_md, plugin_name, doers)
    if os.path.isdir(agents_root):
        for f in sorted(os.listdir(agents_root)):
            if f.endswith(".md"):
                check_agent(root, os.path.join(agents_root, f))

    return declared_name


# ------------------------------------------------------------------------- marketplace
def check_marketplace(root: str, plugin_dirs: list[str], declared_names: dict[str, str]) -> None:
    path = os.path.join(root, ".claude-plugin", "marketplace.json")
    p = rel(root, path)
    if not os.path.exists(path):
        error(p, "marketplace manifest not found")
        return
    try:
        with open(path) as fh:
            market = json.load(fh)
    except json.JSONDecodeError as exc:
        error(p, f"is not valid JSON: {exc}")
        return

    listed = {}
    for entry in market.get("plugins", []):
        name, source = entry.get("name"), entry.get("source", "")
        src_dir = os.path.normpath(os.path.join(root, source))
        listed[os.path.basename(src_dir)] = name
        if not os.path.isdir(src_dir):
            error(p, f"plugin `{name}` points at `{source}` which does not exist")
        elif declared_names.get(os.path.basename(src_dir)) not in (None, name):
            error(
                p,
                f"entry `{name}` disagrees with {source}/.claude-plugin/plugin.json "
                f"(`{declared_names[os.path.basename(src_dir)]}`)",
            )
        if not entry.get("description"):
            warn(p, f"plugin `{name}` has no description")

    for d in plugin_dirs:
        if os.path.basename(d) not in listed:
            error(p, f"plugins/{os.path.basename(d)}/ exists but is not in the marketplace — it is not installable")


_QUOTED = re.compile(r"\"([^\"]*)\"|'([^']*)'")
_REQ_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")


def _requirement_names(chunk: str) -> set[str]:
    names = set()
    for m in _QUOTED.finditer(chunk):
        name = _REQ_NAME.match((m.group(1) or m.group(2) or "").strip())
        if name:
            names.add(name.group(0).lower().replace("_", "-"))
    return names


def declared_distributions(text: str) -> set[str]:
    """Distribution names from `[project] dependencies` and every `[dependency-groups]` array.

    Hand-rolled rather than tomllib: `requires-python` is >=3.10 and tomllib arrived in 3.11, so
    the lint has to read this on the interpreter CI pins.
    """
    names: set[str] = set()
    section = ""
    depth = 0
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if depth:
            if "include-group" not in line:  # a group including another group, not a requirement
                names |= _requirement_names(line)
            depth += line.count("[") - line.count("]")
            continue
        if line.startswith("[") and "=" not in line:
            section = line.strip("[]").strip()
            continue
        key, sep, rest = line.partition("=")
        if not sep or not rest.strip().startswith("["):
            continue
        if key.strip() == "dependencies" or section == "dependency-groups":
            names |= _requirement_names(rest)
            depth = rest.count("[") - rest.count("]")
    return names


def imported_modules(tree: ast.AST) -> set[str]:
    """Top-level module names, including imports nested in try/except optional-dependency guards."""
    mods = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            mods.update(a.name.split(".")[0] for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            mods.add(node.module.split(".")[0])
    return mods


def _is_local(root: str, script_dir: str, mod: str) -> bool:
    return any(
        os.path.exists(os.path.join(d, mod + ".py")) or os.path.isdir(os.path.join(d, mod))
        for d in (script_dir, root)
    )


def check_script_imports(root: str) -> None:
    """Every third-party module a check script imports must be declared in pyproject.toml.

    The failure this catches is a script that runs on the author's machine and exits 2 — "skipped,
    dependency absent" — everywhere else, which reads as a pass. A skip must mean the environment
    was not set up, never that the manifest is incomplete.
    """
    manifest = os.path.join(root, "pyproject.toml")
    if not os.path.isfile(manifest):
        return  # nothing to check against
    with open(manifest) as fh:
        declared = declared_distributions(fh.read())

    for d in CHECK_SCRIPT_DIRS:
        base = os.path.join(root, d)
        if not os.path.isdir(base):
            continue
        for name in sorted(os.listdir(base)):
            if not name.endswith(".py"):
                continue
            path = os.path.join(base, name)
            with open(path) as fh:
                source = fh.read()
            try:
                tree = ast.parse(source)
            except SyntaxError as exc:
                error(rel(root, path), f"does not parse: {exc}")
                continue
            for mod in sorted(imported_modules(tree)):
                if mod in sys.stdlib_module_names or _is_local(root, base, mod):
                    continue
                dist = IMPORT_ALIASES.get(mod, mod).lower().replace("_", "-")
                if dist not in declared:
                    error(
                        rel(root, path),
                        f"imports `{mod}` but pyproject.toml declares no `{dist}` — "
                        "a synced environment will not have it",
                    )


# The mechanically checkable doc claims. Prose claims in general are not tractable to check, and a
# check that half-worked would be its own drift — so this is deliberately narrow: the manifest
# filename the Contributing steps send a new contributor to edit, the plugin count, and the two
# claims the marketplace description makes about the closed STAMPED set and the workflow plane.
_PLUGIN_COUNT = re.compile(r"\*\*(\d+) plugins\*\*")
_PLANNER_COUNT = re.compile(r"(\d+) workflow-plane planner (plugins|skills)")
_TABLE_ROW_SKILLS = re.compile(r"\b(\d+) skills?\b")
_CHANGE_LINK = re.compile(r"openspec/changes/(?!archive\b)([A-Za-z0-9][A-Za-z0-9._-]*)")
_DOER_LIST = re.compile(r"capability-plane doers \(([^)]*)\)")
# "STAMPED Metadata" shipped in the marketplace for months because the closed-set check only ever
# read skill frontmatter. Any capitalised word introduced as a STAMPED dimension is a candidate.
_STAMPED_PROSE = re.compile(r"STAMPED[- ]([A-Z][a-z]+)")
STAMPED_NAMES = {
    "Self-containment": "S",
    "Self": "S",
    "Tracking": "T",
    "Tracked": "T",
    "Actionability": "A",
    "Actionable": "A",
    "Modularity": "M",
    "Modular": "M",
    "Portability": "P",
    "Portable": "P",
    "Ephemerality": "E",
    "Ephemeral": "E",
    "Distributability": "D",
    "Distributable": "D",
}


def check_marketplace_claims(root: str, plugin_dirs: list[str]) -> None:
    """The marketplace description is the first statement of the framework most readers meet, and
    no other check reads it. Both claims below are the shape check_doc_claims already uses."""
    path = os.path.join(root, ".claude-plugin", "marketplace.json")
    p = rel(root, path)
    if not os.path.isfile(path):
        return  # check_marketplace already errored
    with open(path) as fh:
        text = fh.read()

    for name in sorted({m.group(1) for m in _STAMPED_PROSE.finditer(text)}):
        if name not in STAMPED_NAMES:
            error(
                p,
                f"names `STAMPED {name}`, which is not one of the seven principles; valid names are "
                "Self-containment, Tracking, Actionability, Modularity, Portability, Ephemerality, "
                "Distributability",
            )

    workflow_dirs = [
        d
        for d in plugin_dirs
        if any(
            _has_workflow_skill(os.path.join(d, "skills", s))
            for s in (os.listdir(os.path.join(d, "skills")) if os.path.isdir(os.path.join(d, "skills")) else [])
        )
    ]
    claimed = _PLANNER_COUNT.search(text)
    if not claimed:
        warn(
            p,
            "states no planner count in the form `N workflow-plane planner plugins`, so the "
            "description's account of the workflow plane cannot be checked",
        )
    elif claimed.group(2) == "skills":
        # The count that can be checked here is of plugins containing a workflow skill, not of
        # the skills themselves; the two differ by a factor of six and the wording hid that.
        error(
            p,
            f"says `{claimed.group(1)} workflow-plane planner skills`; that count is of planner "
            "*plugins*. Write `planner plugins`, or state the skill count separately",
        )
    elif int(claimed.group(1)) != len(workflow_dirs):
        error(
            p,
            f"claims {claimed.group(1)} workflow-plane planners; {len(workflow_dirs)} plugins on "
            f"disk contain a `plane: workflow` skill ({', '.join(sorted(os.path.basename(d) for d in workflow_dirs))})",
        )

    # The description enumerates the doers by name. A capability added after the description was
    # written is silently absent from the project's own one-paragraph account of itself.
    listed = _DOER_LIST.search(text)
    if listed:
        named = {n.strip().strip("`") for n in listed.group(1).split(",") if n.strip()}
        actual = _capability_doers(plugin_dirs)
        missing = sorted(actual - named)
        unknown = sorted(named - actual)
        if missing:
            error(p, f"enumerates the capability-plane doers but omits {', '.join(missing)}")
        if unknown:
            error(p, f"names {', '.join(unknown)} as capability-plane doers; no such doer is on disk")


def _skill_count(plugin_dir: str) -> int:
    """Skill directories on disk, which is what a README row claiming `N skills` is asserting."""
    skills = os.path.join(plugin_dir, "skills")
    if not os.path.isdir(skills):
        return 0
    return sum(1 for s in os.listdir(skills) if os.path.isfile(os.path.join(skills, s, "SKILL.md")))


def _capability_doers(plugin_dirs: list[str]) -> set[str]:
    """Plugins that provide a doer agent and are not planners. `project` ships an agent
    (`coordinator`) but is a workflow plugin, so it is not a capability-plane doer."""
    out = set()
    for d in plugin_dirs:
        if not os.path.isdir(os.path.join(d, "agents")):
            continue
        skills = os.path.join(d, "skills")
        names = os.listdir(skills) if os.path.isdir(skills) else []
        if any(_has_workflow_skill(os.path.join(skills, s)) for s in names):
            continue
        out.add(os.path.basename(d))
    return out


def _has_workflow_skill(skill_dir: str) -> bool:
    path = os.path.join(skill_dir, "SKILL.md")
    if not os.path.isfile(path):
        return False
    with open(path) as fh:
        return any(line.strip() == "plane: workflow" for line in fh)


def check_doc_claims(root: str, plugin_dirs: list[str]) -> None:
    readme = os.path.join(root, "README.md")
    if not os.path.isfile(readme):
        return
    with open(readme) as fh:
        text = fh.read()

    if "plugin.yaml" in text:
        error(
            "README.md",
            "references `plugin.yaml`, which does not exist — manifests are "
            "`.claude-plugin/plugin.json`. A contributor following the Contributing steps would "
            "edit a file that is not there",
        )

    claimed = _PLUGIN_COUNT.search(text)
    if not claimed:
        warn("README.md", "states no plugin count in the form `**N plugins**`, so the count cannot be checked")
    elif int(claimed.group(1)) != len(plugin_dirs):
        error(
            "README.md",
            f"claims {claimed.group(1)} plugins; {len(plugin_dirs)} are on disk",
        )

    # The repo-wide plugin count above is coarse: it stays correct while an individual plugin's
    # row goes stale, which is exactly how `compendium-cli` sat at "1 skill" through two changes
    # that took it to four. Check the per-plugin column too.
    by_name = {os.path.basename(d): d for d in plugin_dirs}
    for lineno, line in enumerate(text.splitlines(), start=1):
        if not line.lstrip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        head = cells[0].strip("`")
        if head not in by_name:
            continue
        stated = _TABLE_ROW_SKILLS.search(" | ".join(cells[1:]))
        if not stated:
            continue
        actual = _skill_count(by_name[head])
        if int(stated.group(1)) != actual:
            error(
                f"README.md:{lineno}",
                f"the `{head}` row claims {stated.group(1)} skill(s); {actual} are on disk",
            )


_DOC_GLOBS = ("README.md", "docs")


def check_change_links(root: str) -> None:
    """A link to `openspec/changes/<name>` is a promise that the change is still open. When the
    change archives, the link 404s and the sentence around it usually describes the work as
    pending — which is worse than the dead link, because it reads as current."""
    changes = os.path.join(root, "openspec", "changes")
    if not os.path.isdir(changes):
        return
    archive = os.path.join(changes, "archive")
    archived = sorted(os.listdir(archive)) if os.path.isdir(archive) else []

    docs: list[str] = []
    readme = os.path.join(root, "README.md")
    if os.path.isfile(readme):
        docs.append(readme)
    docs_dir = os.path.join(root, "docs")
    for dirpath, _dirnames, filenames in os.walk(docs_dir):
        docs.extend(os.path.join(dirpath, f) for f in sorted(filenames) if f.endswith(".md"))

    for path in docs:
        with open(path) as fh:
            lines = fh.read().splitlines()
        for lineno, line in enumerate(lines, start=1):
            for m in _CHANGE_LINK.finditer(line):
                name = m.group(1)
                if os.path.isdir(os.path.join(changes, name)):
                    continue
                match = [a for a in archived if a.endswith(f"-{name}")]
                where = f"{rel(root, path)}:{lineno}"
                if match:
                    error(
                        where,
                        f"links to `openspec/changes/{name}`, which archived to "
                        f"`openspec/changes/archive/{match[0]}/`. Re-point the link and re-read "
                        "the sentence around it — it likely still describes the work as pending",
                    )
                else:
                    error(where, f"links to `openspec/changes/{name}`, which does not exist")


def main() -> None:
    argv = [a for a in sys.argv[1:] if not a.startswith("-")]
    flags = {a for a in sys.argv[1:] if a.startswith("-")}
    if flags - {"-v", "--verbose", "--strict"} or len(argv) > 1:
        print("usage: lint-plugins.py [-v] [--strict] [repo_root]", file=sys.stderr)
        sys.exit(1)
    verbose = bool(flags & {"-v", "--verbose"})
    strict = "--strict" in flags

    root = os.path.abspath(argv[0]) if argv else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    plugins_root = os.path.join(root, "plugins")
    if not os.path.isdir(plugins_root):
        print(f"ERROR: no plugins/ directory under {root}", file=sys.stderr)
        sys.exit(1)

    plugin_dirs = [
        os.path.join(plugins_root, d)
        for d in sorted(os.listdir(plugins_root))
        if os.path.isdir(os.path.join(plugins_root, d))
    ]
    # Resolve the doer registry first — skills' `delegates_to` is checked against it.
    doers = {
        os.path.basename(d): sorted(f for f in os.listdir(os.path.join(d, "agents")) if f.endswith(".md"))
        for d in plugin_dirs
        if os.path.isdir(os.path.join(d, "agents"))
    }

    declared_names = {}
    for d in plugin_dirs:
        declared = check_plugin(root, d, doers)
        if declared:
            declared_names[os.path.basename(d)] = declared
    check_marketplace(root, plugin_dirs, declared_names)
    check_script_imports(root)
    check_doc_claims(root, plugin_dirs)
    check_marketplace_claims(root, plugin_dirs)
    check_change_links(root)

    errors = [f for f in findings if f[0] == "ERROR"]
    warnings = [f for f in findings if f[0] == "WARN"]
    for severity, path, msg in errors + warnings:
        color = "\033[31m" if severity == "ERROR" else "\033[33m"
        print(f"  {color}{severity}\033[0m {path}: {msg}")

    print(
        f"\nchecked {counts['plugins']} plugins, {counts['skills']} skills, "
        f"{counts['agents']} agents (delegation targets: {', '.join(sorted(doers))})"
    )
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    if verbose and not findings:
        print("all structural checks passed")
    sys.exit(1 if errors or (strict and warnings) else 0)


if __name__ == "__main__":
    main()
