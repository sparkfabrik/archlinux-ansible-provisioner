"""Run with python3 -m unittest discover -s tests -p test_codex_migration.py -v.

Real Ansible task flow, with package managers and packaged Codex replaced by
inert fixtures. No system packages, user installations or privileges are changed.
"""

import getpass
import importlib.util
import json
import os
import shlex
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
ROLE = REPO / "playbooks/roles/sf-toolbox"
spec = importlib.util.spec_from_file_location(
    "prefix", REPO / "bin/common/codex-npm-prefix.py"
)
prefix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prefix)


class MigrationTest(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="codex-migration-"))
        self.home = self.root / "home"
        self.npm_prefix = self.home / "custom prefix"
        self.bin = self.npm_prefix / "bin"
        self.bin.mkdir(parents=True)
        target = self.npm_prefix / "lib/node_modules/@openai/codex/bin/codex.js"
        target.parent.mkdir(parents=True)
        target.write_text("#!/bin/sh\nexit 0\n")
        target.chmod(0o755)
        self.codex = self.bin / "codex"
        self.codex.symlink_to(target)
        self.log = self.root / "calls.jsonl"
        self.packaged = self.root / "packaged-codex"
        self.env = os.environ | {
            "HOME": str(self.home),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
        }

    def test_prefix_recognition(self):
        self.assertEqual(prefix.user_prefix(self.codex, self.home), self.npm_prefix)
        self.assertIsNone(prefix.user_prefix(self.codex.resolve(), self.home))
        self.assertIsNone(prefix.user_prefix(self.codex, self.home / "other"))
        other = self.bin / "other-codex"
        other.symlink_to(self.root / "unrelated")
        self.assertIsNone(prefix.user_prefix(other, self.home))

    def test_conflict_check_allows_only_recognized_npm_codex(self):
        source = (REPO / "bin/install.linux").read_text()
        functions = source[
            source.index("is_mise_managed() {") : source.index("# ─── Bootstrap")
        ]
        bootstrap = f"""set -eu
source {shlex.quote(str(REPO / "bin/common/logging.sh"))}
yaml_python() {{ printf '%s' {shlex.quote(sys.executable)}; }}
REPO_DIR={shlex.quote(str(REPO))}
OS_FAMILY=Archlinux
NONINTERACTIVE=0
"""
        # Limit the package catalog in this fixture, so installed host tools are irrelevant.
        catalog = self.root / "catalog"
        (catalog / "bin/common").mkdir(parents=True)
        (catalog / "playbooks/roles/sf-toolbox/vars").mkdir(parents=True)
        (catalog / "playbooks/roles/sf-toolbox/vars/main.yml").write_text(
            "toolbox:\n  detect: [codex]\n"
        )
        for name in ("parse-toolbox-packages.py", "codex-npm-prefix.py"):
            (catalog / "bin/common" / name).symlink_to(REPO / "bin/common" / name)
        script = (
            bootstrap
            + functions
            + f"\nREPO_DIR={shlex.quote(str(catalog))}\ncheck_conflicts\n"
        )
        result = subprocess.run(
            ["bash", "-c", script],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.codex.rename(self.bin / "saved-npm-codex")
        self.codex.write_text("#!/bin/sh\nexit 0\n")
        self.codex.chmod(0o755)
        result = subprocess.run(
            ["bash", "-c", script],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Conflicting tools detected", result.stdout + result.stderr)

    def test_wrapper_passes_user_path_as_json(self):
        source = (REPO / "bin/install.linux").read_text()
        function = source[
            source.index("run_ansible() {") : source.index("create_symlink() {")
        ]
        sudo = self.bin / "sudo"
        sudo.write_text(
            f"#!{sys.executable}\nimport json,os,sys\nfrom pathlib import Path\nPath(os.environ['CAPTURE']).write_text(json.dumps(sys.argv[1:]))\n"
        )
        sudo.chmod(0o755)
        galaxy = self.bin / "ansible-galaxy"
        galaxy.write_text("#!/bin/sh\nexit 0\n")
        galaxy.chmod(0o755)
        capture = self.root / "ansible-args.json"
        script = f"""set -eu
log_info() {{ :; }}
log_error() {{ :; }}
yaml_python() {{ printf '%s' {shlex.quote(sys.executable)}; }}
REPO_DIR={shlex.quote(str(REPO))}
{function}
run_ansible
"""
        result = subprocess.run(
            ["bash", "-c", script],
            env=self.env | {"CAPTURE": str(capture)},
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        args = json.loads(capture.read_text())
        passed = json.loads(args[args.index("--extra-vars") + 1])
        self.assertEqual(passed, {"sf_toolbox_user_path": self.env["PATH"]})

    def run_play(self, mode="success", omarchy=False):
        modules = (
            self.root
            / "collections/ansible_collections/community/general/plugins/modules"
        )
        modules.mkdir(parents=True, exist_ok=True)
        mock = """from ansible.module_utils.basic import AnsibleModule
import json, os
from pathlib import Path
m = AnsibleModule(argument_spec=dict(name=dict(type='raw'), state=dict(type='str'), global_=dict(type='bool', aliases=['global']), path=dict(type='str')), supports_check_mode=True)
name = m.params['name']
with open(os.environ['FIXTURE_LOG'], 'a') as f:
    f.write(json.dumps({'package': name, 'state': m.params['state']}) + '\\n')
if m.params['state'] == 'present' and 'openai-codex' in name:
    if os.environ['FIXTURE_MODE'] == '404':
        m.fail_json(msg='Failed to install package(s)', stderr='failed retrieving file codex: 404')
    if os.environ['FIXTURE_MODE'] == 'other-error':
        m.fail_json(msg='Failed to install package(s)', stderr='invalid signature')
m.exit_json(changed=False)
"""
        for name in ("pacman", "npm", "homebrew", "homebrew_cask"):
            (modules / f"{name}.py").write_text(mock)
        self.packaged.write_text(
            f"#!{sys.executable}\nimport os\nfrom pathlib import Path\np=Path(os.environ['FIXTURE_LOG'])\np.open('a').write('{{\"verify\":true}}\\n')\nraise SystemExit(1 if os.environ['FIXTURE_MODE']=='bad-binary' else 0)\n"
        )
        self.packaged.chmod(0o755)
        mise = self.bin / "mise"
        mise.write_text(
            f"#!{sys.executable}\nimport json,os,sys\nfrom pathlib import Path\nPath(os.environ['FIXTURE_LOG']).open('a').write(json.dumps({{'mise':sys.argv[1:]}})+'\\n')\n"
        )
        mise.chmod(0o755)
        npm = self.bin / "npm"
        npm.write_text(
            f"#!{sys.executable}\nimport json,os,sys\nfrom pathlib import Path\np=Path(os.environ['FIXTURE_LOG'])\np.open('a').write(json.dumps({{'npm':sys.argv[1:],'home':os.environ['HOME']}})+'\\n')\nlink=Path(sys.argv[sys.argv.index('--prefix')+1])/'bin/codex'\nlink.rename(link.with_name('migrated-codex'))\n"
        )
        npm.chmod(0o755)
        tasks = yaml.safe_load((ROLE / "tasks/packages.yml").read_text())
        # Redirect the absolute packaged executable only; retain task order, conditions and rescue.
        verify = tasks[-1]["block"][0]["ansible.builtin.command"]["argv"]
        self.assertIn("/usr/bin/codex", verify[0])
        self.assertIn("/home/linuxbrew/.linuxbrew/bin/codex", verify[0])
        verify[0] = str(self.packaged)
        config = yaml.safe_load((ROLE / "vars/main.yml").read_text())["toolbox"]
        self.assertNotIn("@openai/codex", config["common"]["remove"]["npm"])
        config["arch"]["pacman"] = ["openai-codex"]
        config["arch"]["npm"] = []
        config["arch"]["remove"]["pacman"] = []
        config["common"]["remove"]["npm"] = []
        play = [
            {
                "hosts": "localhost",
                "gather_facts": False,
                "vars": {
                    "ansible_become": False,
                    "ansible_python_interpreter": sys.executable,
                    "ansible_facts": {"os_family": "Archlinux"},
                    "toolbox": config,
                    "role_path": str(ROLE),
                    "current_user": getpass.getuser(),
                    "current_home": str(self.home),
                    "sf_toolbox_user_path": self.env["PATH"],
                    "omarchy_detected": omarchy,
                    "omarchy_mise_tools": ["codex"] if omarchy else [],
                    "omarchy_shadowed_pacman": ["openai-codex"] if omarchy else [],
                },
                "environment": {
                    # Omarchy provides mise; the fixture stands in for it.
                    "PATH": (str(self.bin) + ":" if omarchy else "") + "/usr/bin:/bin",
                    "HOME": str(self.home),
                    "FIXTURE_LOG": str(self.log),
                    "FIXTURE_MODE": mode,
                },
                "tasks": tasks,
            }
        ]
        playbook = self.root / "play.json"
        playbook.write_text(json.dumps(play))
        result = subprocess.run(
            ["ansible-playbook", "-i", "localhost,", "-c", "local", str(playbook)],
            env=self.env
            | {
                "ANSIBLE_COLLECTIONS_PATH": str(self.root / "collections"),
                "ANSIBLE_LOCAL_TEMP": str(self.root / "ansible"),
                "ANSIBLE_NOCOLOR": "1",
            },
            capture_output=True,
            text=True,
            check=False,
        )
        (self.root / f"{mode}.log").write_text(result.stdout + result.stderr)
        return result

    def npm_calls(self):
        """The npm invocations the fixture logged, not the packages named npm."""
        return [
            call
            for call in (json.loads(s) for s in self.log.read_text().splitlines())
            if "npm" in call
        ]

    def test_success_and_repeated_run(self):
        result = self.run_play()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.codex.exists())
        calls = [json.loads(s) for s in self.log.read_text().splitlines()]
        self.assertEqual(calls[-2], {"verify": True})
        self.assertEqual(
            calls[-1],
            {
                "npm": [
                    "uninstall",
                    "--global",
                    "--prefix",
                    str(self.npm_prefix),
                    "@openai/codex",
                ],
                "home": str(self.home),
            },
        )
        result = self.run_play()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(self.npm_calls()), 1)

    def test_failures_preserve_npm_copy(self):
        for mode in ("404", "other-error", "bad-binary"):
            with self.subTest(mode=mode):
                result = self.run_play(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertTrue(self.codex.exists())
                self.assertEqual(self.npm_calls(), [])
                if mode == "404":
                    self.assertIn("sudo pacman -Syu", result.stdout)
                if mode == "other-error":
                    self.assertIn("invalid signature", result.stdout)
                    self.assertNotIn("Run `sudo pacman -Syu`", result.stdout)

    def test_omarchy_is_not_migrated(self):
        result = self.run_play(omarchy=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.codex.exists())
        self.assertEqual(self.npm_calls(), [])
        # Omarchy takes its Node.js from mise, never from pacman.
        packages = [
            call
            for call in (json.loads(s) for s in self.log.read_text().splitlines())
            if call.get("package")
        ]
        self.assertNotIn("npm", [p for call in packages for p in call["package"]])


if __name__ == "__main__":
    unittest.main()
