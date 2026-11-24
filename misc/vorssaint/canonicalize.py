#!/usr/bin/env python3
# canonicalize a plist to stdout: sorted keys + sorted JSON-in-string values.
# The app's export shuffles JSON key order between runs; this makes the
# file byte-stable so diff-based guards mean something.
import json
import plistlib
import sys


def canon(v):
    if isinstance(v, dict):
        return {k: canon(x) for k, x in sorted(v.items())}
    if isinstance(v, list):
        return [canon(x) for x in v]
    if isinstance(v, str) and v.lstrip()[:1] in "{[":
        try:
            return json.dumps(json.loads(v), sort_keys=True, separators=(",", ":"))
        except ValueError:
            return v
    return v


if len(sys.argv) != 2:
    print("usage: plist-canonicalize.py FILE", file=sys.stderr)
    sys.exit(2)

try:
    with open(sys.argv[1], "rb") as f:
        plistlib.dump(canon(plistlib.load(f)), sys.stdout.buffer, sort_keys=True)
except (OSError, ValueError, IndexError) as e:
    print(f"plist-canonicalize: {sys.argv[1]}: {e}", file=sys.stderr)
    sys.exit(1)
