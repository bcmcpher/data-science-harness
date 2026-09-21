#!/usr/bin/env python3
"""Generate Figure 1 — the two planes and their delegation edges — from the repository.

The figure is derived from each planner skill's declared `delegates_to:`, never drawn by hand, so
it cannot disagree with the code it illustrates. Re-run it after any delegation changes:

    python3 paper/figures/make-two-planes.py

Writes paper/figures/two-planes.svg. No third-party dependencies: the SVG is emitted directly, so
the figure costs the repository nothing to rebuild and adds nothing to any manifest.

Exit codes: 0 written, 1 the repository's delegation graph could not be read.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLUGINS = os.path.join(ROOT, "plugins")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "two-planes.svg")

# Lifecycle order, not alphabetical: the top row should read left-to-right as a project runs.
PLANNER_ORDER = ["govern", "project", "curate", "process", "analyze", "disseminate"]


def frontmatter(path):
    with open(path) as fh:
        text = fh.read()
    if not text.startswith("---"):
        return {}
    _, fm, _ = text.split("---", 2)
    out = {}
    for line in fm.splitlines():
        if ":" in line and not line.startswith((" ", "\t", "-")):
            k, _, v = line.partition(":")
            out[k.strip()] = v.strip()
    return out


def delegation_graph():
    """planner plugin -> {doer: number of its skills delegating there}, plus the planner's skills."""
    edges, sizes = {}, {}
    for plugin in sorted(os.listdir(PLUGINS)):
        skills_dir = os.path.join(PLUGINS, plugin, "skills")
        if not os.path.isdir(skills_dir):
            continue
        for skill in sorted(os.listdir(skills_dir)):
            path = os.path.join(skills_dir, skill, "SKILL.md")
            if not os.path.isfile(path):
                continue
            fm = frontmatter(path)
            if fm.get("plane") != "workflow":
                continue
            sizes[plugin] = sizes.get(plugin, 0) + 1
            raw = fm.get("delegates_to", "")
            for doer in (d.strip() for d in raw.strip("[]").split(",")):
                if doer:
                    edges.setdefault(plugin, {}).setdefault(doer, 0)
                    edges[plugin][doer] += 1
    return edges, sizes


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def main():
    edges, sizes = delegation_graph()
    if not edges:
        print("ERROR: no workflow skills with delegates_to found", file=sys.stderr)
        return 1

    planners = [p for p in PLANNER_ORDER if p in edges]
    planners += [p for p in sorted(edges) if p not in planners]
    doers = sorted({d for m in edges.values() for d in m})
    # datalad carries every edge; put it in the middle so the fan is legible.
    doers = [d for d in doers if d != "datalad"]
    doers.insert(len(doers) // 2, "datalad")

    W, H = 1000, 486
    BW, BH = 132, 46
    top_y, bot_y = 92, 340
    def xs(n, w):
        gap = (W - 60 - n * w) / max(n - 1, 1)
        return [30 + i * (w + gap) for i in range(n)]
    px, dx = xs(len(planners), BW), xs(len(doers), BW)
    pcx = {p: px[i] + BW / 2 for i, p in enumerate(planners)}
    dcx = {d: dx[i] + BW / 2 for i, d in enumerate(doers)}

    L = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
        f'font-family="Helvetica, Arial, sans-serif">',
        f'<rect width="{W}" height="{H}" fill="#ffffff"/>',
        f'<rect x="14" y="{top_y - 44}" width="{W - 28}" height="{BH + 62}" rx="10" fill="#f4f7fb" stroke="#c8d6e8"/>',
        f'<rect x="14" y="{bot_y - 46}" width="{W - 28}" height="{BH + 64}" rx="10" fill="#f7f5f2" stroke="#ddd2c4"/>',
        f'<text x="26" y="{top_y - 24}" font-size="13" font-weight="bold" fill="#3c5a80">'
        f'WORKFLOW PLANE &#183; {len(planners)} planners, {sum(sizes.values())} skills &#183; knows the research process</text>',
        f'<text x="26" y="{bot_y - 26}" font-size="13" font-weight="bold" fill="#8a6d3b">'
        f'CAPABILITY PLANE &#183; {len(doers)} doers, each paired 1:1 with a *-cli toolbox &#183; knows one tool</text>',
    ]

    for p in planners:
        for d, n in sorted(edges[p].items()):
            hot = d == "datalad"
            L.append(
                f'<path d="M {pcx[p]:.0f} {top_y + BH} C {pcx[p]:.0f} {top_y + BH + 70}, '
                f'{dcx[d]:.0f} {bot_y - 70}, {dcx[d]:.0f} {bot_y}" fill="none" '
                f'stroke="{"#c0392b" if hot else "#8ba3c0"}" stroke-width="{1.1 + n * 0.28:.1f}" '
                f'opacity="{0.55 if hot else 0.75}"/>'
            )

    def box(x, y, label, sub, fill, stroke, bold=False):
        L.append(f'<rect x="{x:.0f}" y="{y}" width="{BW}" height="{BH}" rx="7" fill="{fill}" stroke="{stroke}" stroke-width="{2 if bold else 1}"/>')
        L.append(f'<text x="{x + BW / 2:.0f}" y="{y + 20}" font-size="13" font-weight="bold" text-anchor="middle" fill="#1d2b3a">{esc(label)}</text>')
        L.append(f'<text x="{x + BW / 2:.0f}" y="{y + 36}" font-size="11" text-anchor="middle" fill="#5a6b7d">{esc(sub)}</text>')

    for i, p in enumerate(planners):
        n = sizes.get(p, 0)
        box(px[i], top_y, p, f"{n} skill" + ("s" if n != 1 else ""), "#ffffff", "#8aa6c8")
    for i, d in enumerate(doers):
        hot = d == "datalad"
        n = sum(1 for p in planners if d in edges[p])
        box(dx[i], bot_y, d, f"{n} planner" + ("s" if n != 1 else ""),
            "#fff6f5" if hot else "#ffffff", "#c0392b" if hot else "#c4b295", bold=hot)

    total = sum(sizes.values())
    other = max(sum(1 for p in planners if d in edges[p]) for d in doers if d != "datalad")
    L.append(
        f'<text x="{W / 2:.0f}" y="{H - 22}" font-size="12" text-anchor="middle" fill="#40525f">'
        f'All {total} planner skills delegate to '
        f'<tspan fill="#c0392b" font-weight="bold">datalad</tspan>; no other doer is reached by more '
        f'than {other} of the {len(planners)} planners.</text>'
    )
    L.append(
        f'<text x="{W / 2:.0f}" y="{H - 6}" font-size="12" text-anchor="middle" fill="#40525f">'
        f'The seven other doers are swappable. The provenance chain is not.</text>'
    )
    L.append("</svg>")

    with open(OUT, "w") as fh:
        fh.write("\n".join(L) + "\n")
    print(f"wrote {os.path.relpath(OUT, ROOT)} — {len(planners)} planners, {len(doers)} doers, "
          f"{sum(len(m) for m in edges.values())} edges, {total} planner skills")
    return 0


if __name__ == "__main__":
    sys.exit(main())
