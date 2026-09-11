"""Print the prefix of a recognized user npm Codex symlink, or nothing."""

import sys
from pathlib import Path


def user_prefix(binary, home):
    path = Path(binary)
    home = Path(home).resolve()
    if not path.is_symlink():
        return None
    target = path.resolve()
    if target.parts[-6:] != (
        "lib",
        "node_modules",
        "@openai",
        "codex",
        "bin",
        "codex.js",
    ):
        return None
    prefix = target.parents[5]
    if prefix != home and home not in prefix.parents:
        return None
    if path.parent.resolve() != prefix / "bin":
        return None
    return prefix


if __name__ == "__main__":
    prefix = user_prefix(*sys.argv[1:])
    if prefix is not None:
        print(prefix)
