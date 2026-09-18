"""Reproduction tests: each tool must reproduce the result its recorded run produced.

A test that asserts only that the tool ran would pass over a tool returning the wrong answer, which
is the failure this file exists to catch.
"""

import pathlib

RECORDED = pathlib.Path("derivatives/cmp-age-vs-volume/model-summary.tsv")


def test_age_vs_volume_reproduces_recorded_result():
    assert RECORDED.exists(), (
        f"{RECORDED} is missing — there is no recorded result to reproduce, so this tool should not "
        "be in the bundle"
    )
    raise NotImplementedError(
        "Call the tool over the same inputs and compare against RECORDED, to the tolerance the "
        "analysis states. Left unimplemented here on purpose: this is an example of the bundle's "
        "shape, and a reproduction test that passed without comparing anything would be exactly the "
        "thing mcp-scaffold refuses to emit."
    )
