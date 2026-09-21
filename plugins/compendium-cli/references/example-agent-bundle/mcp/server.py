"""Minimal stdio MCP server exposing this bundle's tools.

Each tool calls the study's own script. Nothing here implements an analysis: if a tool's behaviour
needs to change, the script changes and is re-run under provenance, and this file follows.
"""

import subprocess
import sys

TOOLS = {
    # tool name -> the script it wraps, and the parameters that script declares
    "age_vs_volume": {
        "script": "code/cmp-age-vs-volume.py",
        "params": ["--participants", "--out"],
        "recorded_result": "derivatives/cmp-age-vs-volume/",
    },
}


def call(tool: str, **kwargs) -> dict:
    spec = TOOLS[tool]
    argv = [sys.executable, spec["script"]]
    for flag in spec["params"]:
        argv += [flag, kwargs[flag.lstrip("-").replace("-", "_")]]
    proc = subprocess.run(argv, capture_output=True, text=True)
    return {"returncode": proc.returncode, "stdout": proc.stdout, "stderr": proc.stderr}


if __name__ == "__main__":
    raise SystemExit(
        "This is the bundle's server entry point. Register it through .mcp.json rather than "
        "running it directly; a server started by hand exposes tools nothing is holding open."
    )
