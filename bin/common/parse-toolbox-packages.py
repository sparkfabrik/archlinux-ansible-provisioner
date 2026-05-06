#!/usr/bin/env python3
"""Parse YAML lists from toolbox-packages.yml without external dependencies.

Usage: parse-packages.py <yaml-file> <dotted.key.path>

Supports dotted paths for nested access (e.g., "prerequisites.common",
"debian.remove.apt"). Outputs one item per line to stdout.
Exits 0 even if key is not found (empty output).
"""
import sys
import re


def parse_nested(filepath, dotted_key):
    """Extract a list from a YAML file by dotted key path."""
    with open(filepath) as f:
        lines = f.readlines()

    keys = dotted_key.split(".")
    target_depth = len(keys)
    current_depth = 0
    in_section = False
    items = []

    for line in lines:
        stripped = line.rstrip()

        # Skip empty lines and comments when not collecting items
        if not stripped or stripped.startswith("#"):
            continue

        # Calculate indentation level (2 spaces per level)
        indent = len(line) - len(line.lstrip())
        level = indent // 2

        if not in_section:
            # Look for each key in the path at the expected depth
            if current_depth < target_depth:
                expected_key = keys[current_depth]
                pattern = rf"^{' ' * (current_depth * 2)}{re.escape(expected_key)}:\s*$"
                if re.match(pattern, stripped):
                    current_depth += 1
                    if current_depth == target_depth:
                        in_section = True
                    continue
                # Reset if we hit a same-level key that doesn't match
                if level <= (current_depth * 2) // 2 and current_depth > 0:
                    if not stripped.startswith(" " * (current_depth * 2)):
                        current_depth = 0
        else:
            # We're in the target section — collect list items
            # End of section: line at same or lower indentation as the key
            if level < target_depth:
                break

            # Collect list items at the expected indentation
            m = re.match(r"^\s+-\s+(.+)", stripped)
            if m:
                value = m.group(1).strip().strip('"').strip("'")
                items.append(value)
            elif stripped and not stripped.startswith(" " * (target_depth * 2)):
                # Hit a sibling key at same level — end of section
                break

    return items


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <yaml-file> <dotted.key.path>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    key = sys.argv[2]

    try:
        items = parse_nested(filepath, key)
    except FileNotFoundError:
        print(f"Error: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    for item in items:
        print(item)


if __name__ == "__main__":
    main()
