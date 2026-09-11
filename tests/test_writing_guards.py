"""Run isolated Ansible guard installation: python3 tests/test_writing_guards.py SPARKDOCK_CHECKOUT."""

import getpass
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def main():
    sparkdock = Path(sys.argv[1]).resolve()
    tasks = (
        Path(__file__).resolve().parents[1]
        / "playbooks/roles/sf-toolbox/tasks/claude-gh-gate.yml"
    )
    root = Path(tempfile.mkdtemp(prefix="writing-guard-ansible-"))
    print(f"Retained fixtures: {root}")
    for tag, engines in (
        ("claude-gh-gate", {"claude"}),
        ("codex-writing-guard", {"codex"}),
        ("writing-guard", {"claude", "codex"}),
    ):
        home = root / tag
        home.mkdir()
        paths = {
            "claude": home / ".claude/settings.json",
            "codex": home / ".codex/hooks.json",
        }
        # A scoped install must not read or repair the other agent's malformed file.
        for engine in paths.keys() - engines:
            paths[engine].parent.mkdir()
            paths[engine].write_text("untouched")
        playbook = home / "playbook.json"
        playbook.write_text(
            json.dumps(
                [
                    {
                        "hosts": "localhost",
                        "gather_facts": False,
                        "environment": {
                            "CLAUDE_CONFIG_DIR": str(home / ".claude"),
                            "CODEX_HOME": str(home / ".codex"),
                        },
                        "tasks": [{"ansible.builtin.import_tasks": str(tasks)}],
                    }
                ]
            )
        )
        variables = {
            "ansible_become": False,
            "ansible_python_interpreter": sys.executable,
            "system": {"home": str(home), "username": getpass.getuser()},
            "sparkdock": {"path": str(sparkdock)},
        }
        for run in range(2):
            result = subprocess.run(
                [
                    "ansible-playbook",
                    "-i",
                    "localhost,",
                    "-c",
                    "local",
                    str(playbook),
                    "--tags",
                    tag,
                    "-e",
                    json.dumps(variables),
                ],
                env=os.environ
                | {"ANSIBLE_LOCAL_TEMP": str(root / "ansible"), "ANSIBLE_NOCOLOR": "1"},
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode:
                raise AssertionError(result.stdout + result.stderr)
            if run and not re.search(r"changed=0\s", result.stdout):
                raise AssertionError(result.stdout)
            for engine, path in paths.items():
                if engine in engines:
                    data = json.loads(path.read_text())
                    assert "PreToolUse" in data["hooks"], (tag, engine)
                else:
                    assert path.read_text() == "untouched", (tag, engine)
        print(f"PASS {tag}: registration, isolation and idempotency")


if __name__ == "__main__":
    main()
