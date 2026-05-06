#!/usr/bin/env python3
"""Parse simple YAML lists from toolbox-packages.yml without external dependencies.

Usage: parse-packages.py <yaml-file> <key>

Outputs one item per line to stdout. Exits 0 even if key is not found (empty output).
Only supports flat list values (- item format), not nested structures.
"""
import sys
import re


def parse_list(filepath, key):
    """Extract a flat list from a YAML file by top-level key name."""
    with open(filepath) as f:
        lines = f.readlines()

    in_section = False
    items = []
    for line in lines:
        stripped = line.rstrip()

        # Start of target section
        if re.match(rf"^{re.escape(key)}:\s*$", stripped):
            in_section = True
            continue

        # End of section: new top-level key (non-indented, non-comment, non-empty)
        if in_section and stripped and not stripped.startswith(" ") and not stripped.startswith("#"):
            break

        # Collect list items
        if in_section:
            m = re.match(r"^\s+-\s+(.+)", stripped)
            if m:
                value = m.group(1).strip().strip('"').strip("'")
                items.append(value)

    return items


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <yaml-file> <key>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    key = sys.argv[2]

    try:
        items = parse_list(filepath, key)
    except FileNotFoundError:
        print(f"Error: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    for item in items:
        print(item)


if __name__ == "__main__":
    main()
