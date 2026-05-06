#!/usr/bin/env python3
"""Parse YAML lists from toolbox vars using PyYAML.

Usage: parse-toolbox-packages.py <yaml-file> <dotted.key.path>

Supports dotted paths for nested access (e.g., "toolbox.detect",
"toolbox.prerequisites.common", "toolbox.debian.homebrew").
Outputs one item per line to stdout.
Exits 0 even if key is not found (empty output).

Requires PyYAML (always available — Ansible depends on it).
"""
import sys

try:
    import yaml
except ImportError:
    print("Error: PyYAML is not installed. Install it with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def resolve_dotted_path(data, dotted_key):
    """Walk a nested dict by dotted key path, returning the value or None."""
    keys = dotted_key.split(".")
    current = data
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <yaml-file> <dotted.key.path>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    key = sys.argv[2]

    try:
        with open(filepath) as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"Error: file not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error: invalid YAML in {filepath}: {e}", file=sys.stderr)
        sys.exit(1)

    if data is None:
        return

    value = resolve_dotted_path(data, key)

    if value is None:
        return

    if isinstance(value, list):
        for item in value:
            print(item)
    else:
        print(value)


if __name__ == "__main__":
    main()
