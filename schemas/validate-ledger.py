#!/usr/bin/env python3
"""Validate a project.yaml ledger against schemas/project.schema.json.

Exit codes: 0 = valid, 1 = invalid (or usage error), 2 = skipped (pyyaml/jsonschema
not installed). The schema is located next to this script, so callers only pass the ledger.

Usage: validate-ledger.py <path/to/project.yaml>
"""
import os
import sys

try:
    import json

    import jsonschema
    import yaml
except ImportError as exc:  # optional deps -> skip, don't fail a test suite
    print(f"SKIP: {exc} (need pyyaml + jsonschema)", file=sys.stderr)
    sys.exit(2)


class _StrTimestampLoader(yaml.SafeLoader):
    """SafeLoader that leaves ISO timestamps/dates as plain strings.

    The ledger's `created`/`ts`/`due` are JSON strings; PyYAML would otherwise coerce them to
    datetime/date objects, which are not JSON string types and would spuriously fail the schema.
    """


for _ch, _resolvers in list(_StrTimestampLoader.yaml_implicit_resolvers.items()):
    _StrTimestampLoader.yaml_implicit_resolvers[_ch] = [
        (tag, regexp) for tag, regexp in _resolvers if tag != "tag:yaml.org,2002:timestamp"
    ]


def main() -> None:
    if len(sys.argv) != 2:
        print("usage: validate-ledger.py <project.yaml>", file=sys.stderr)
        sys.exit(1)
    ledger_path = sys.argv[1]
    schema_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "project.schema.json")

    with open(schema_path) as fh:
        schema = json.load(fh)
    with open(ledger_path) as fh:
        data = yaml.load(fh, Loader=_StrTimestampLoader)

    try:
        jsonschema.validate(instance=data, schema=schema)
    except jsonschema.ValidationError as err:
        loc = "/".join(str(p) for p in err.absolute_path) or "<root>"
        print(f"INVALID {ledger_path}: at {loc}: {err.message}", file=sys.stderr)
        sys.exit(1)

    print(f"VALID {ledger_path}")


if __name__ == "__main__":
    main()
