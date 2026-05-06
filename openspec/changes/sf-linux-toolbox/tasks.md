## 1. Package Configuration

- [ ] 1.1 Create `config/toolbox-packages.yml` with prerequisites, prerequisites_arch, homebrew_taps, homebrew_packages, removed_apt_packages, removed_apt_sources, removed_npm_packages
- [ ] 1.2 Create `bin/helpers/parse-packages.py` stdlib-only YAML list parser

## 2. Toolbox Playbook

- [ ] 2.1 Create `playbooks/toolbox.yml` with pre_tasks (user detection), vars (sparkdock_default_path, sparkfabrik), include_vars for toolbox-packages.yml, and direct task imports
- [ ] 2.2 Update `playbooks/roles/packages/tasks/homebrew.yml` to add tap support (iterate `toolbox.homebrew_taps` with `community.general.homebrew_tap`)
- [ ] 2.3 Update `playbooks/roles/packages/tasks/ai.yml` — add opencode via pacman on Arch, opencode+openspec via brew on Debian, remove opencode-ai npm package on Arch, keep openspec npm on Arch

## 3. Install Script

- [ ] 3.1 Create `bin/install.linux` with OS detection (reading /etc/os-release)
- [ ] 3.2 Add prerequisite checking (reads from toolbox-packages.yml via parse-packages.py)
- [ ] 3.3 Add conflict detection for Debian (checks dpkg for removed_apt_packages, globs sources.list.d for removed_apt_sources)
- [ ] 3.4 Add plan presentation (system info, will install, will remove, already OK, confirmation prompt) with ANSI colors and optional gum rendering
- [ ] 3.5 Add conflict removal execution (apt-get remove --purge + PPA source file deletion)
- [ ] 3.6 Add repo clone/update logic (fresh clone to /opt/archlinux-provisioner or git pull)
- [ ] 3.7 Add Homebrew bootstrap on Debian (NONINTERACTIVE installer, skip if present)
- [ ] 3.8 Add Ansible installation (pacman on Arch, brew on Debian, skip if present)
- [ ] 3.9 Add ansible-galaxy collection install + ansible-playbook invocation with TAGS support
- [ ] 3.10 Add symlink creation (/usr/local/bin/sf-toolbox → bin/install.linux)
- [ ] 3.11 Make script executable and test --help / dry-run behavior

## 4. Integration and Cleanup

- [ ] 4.1 Update CHANGELOG.md with new entries for install.linux, toolbox.yml, and package-config
- [ ] 4.2 Update GitHub issue #189 with final scope
- [ ] 4.3 Commit spec artifacts (separate commit)
- [ ] 4.4 Commit implementation (separate commit)
- [ ] 4.5 Push and update PR #190
