## 1. Package Configuration

- [x] 1.1 Create package definitions at `playbooks/roles/sf-toolbox/vars/main.yml` (auto-loaded by Ansible) with nested `toolbox:` key containing `arch`, `debian`, `common`, `detect`, `prerequisites`
- [x] 1.2 Create `bin/common/parse-toolbox-packages.py` PyYAML-based parser with dotted path access

## 2. Toolbox Playbook

- [x] 2.1 Create `playbooks/sf-toolbox.yml` with pre_tasks (user detection), vars (sparkdock_default_path, sparkfabrik), play-level environment PATH, and roles (sparkdock + sf-toolbox)
- [x] 2.2 Create `playbooks/roles/sf-toolbox/tasks/homebrew.yml` with tap support, shellenv integration, and profile.d
- [x] 2.3 Create per-tool task files: `packages.yml` (pacman/apt/homebrew installs), `ai.yml` (opencode/openspec completions + config), `glab.yml`, `gcloud.yml`, `ajust.yml`, `http-proxy.yml`

## 3. Install Script

- [x] 3.1 Create `bin/install.linux` with OS detection (reading /etc/os-release, supporting Arch/Debian family)
- [x] 3.2 Add tool detection via `show_status()` (reads `toolbox.detect` list via parser, shows installed/missing)
- [x] 3.3 Add Homebrew first-install explanation and confirmation prompt (Debian only, respects NONINTERACTIVE)
- [x] 3.4 Add repo clone/update logic (fresh clone to /opt/archlinux-provisioner or git pull, local dev checkout detection)
- [x] 3.5 Add Homebrew bootstrap on Debian (handled in Ansible `homebrew.yml`, no apt conflict removal needed — brew PATH wins)
- [x] 3.6 Add Ansible installation (pacman on Arch, apt on Debian, skip if present)
- [x] 3.7 Add ansible-galaxy collection install + ansible-playbook invocation with TAGS and SKIP_TAGS support
- [x] 3.8 Add symlink creation (/usr/local/bin/sf-toolbox → bin/install.linux)
- [x] 3.9 Add shell-enable post-install step (via ajust, skipped in NONINTERACTIVE mode)
- [x] 3.10 Add shared logging helpers (`bin/common/logging.sh` with gum integration and ANSI fallback)

## 4. Integration and Cleanup

- [x] 4.1 Update CHANGELOG.md with new entries
- [x] 4.2 Create CI workflow (`.github/workflows/test-toolbox.yml` — Ubuntu 24.04, Ubuntu 26.04, Arch Linux)
- [x] 4.3 Create PR #190 with full implementation
- [x] 4.4 Address code review findings (ajust cross-platform, glab idempotency, ai.yml privileges, PyYAML parser, apt ansible install)
