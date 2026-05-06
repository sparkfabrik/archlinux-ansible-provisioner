## Why

Linux developers at SparkFabrik (on both Arch and Ubuntu) need a single command to install and update the company's shared tooling — sparkdock, AI coding tools, cloud-native CLI tools, and internal utilities. Today the provisioner is Arch-only and conflates full system provisioning with company tooling. macOS developers already have this via `sparkdock` / `install.macos`. Linux needs the same experience: clone, run one script, get all SparkFabrik tools working.

## What Changes

- New `bin/install.linux` entry point script that handles detection, presentation, conflict cleanup, and orchestration for both Arch and Ubuntu
- New `playbooks/toolbox.yml` playbook that imports only the company-tooling subset of tasks (sparkdock, AI, glab, gcloud, http-proxy)
- New `config/toolbox-packages.yml` as the single source of truth for package definitions, prerequisites, and conflict resolution — consumed by both the shell script (via a Python helper) and Ansible (via `include_vars`)
- New `bin/helpers/parse-packages.py` stdlib-only Python script to parse the YAML config for shell consumption
- Modified `packages/tasks/ai.yml` to install opencode via pacman on Arch (replacing npm), opencode+openspec via brew on Debian, and openspec via npm on Arch only
- Homebrew bootstrap and OS-specific task file splits (already implemented in PR #190 on branch `feat/debian-ubuntu-sparkdock-compat-189`)

## Capabilities

### New Capabilities

- `install-script`: The `bin/install.linux` bash script — preflight checks, OS detection, conflict detection/removal, Homebrew/Ansible bootstrap, self-update flow, and nice terminal presentation before acting
- `toolbox-playbook`: The `playbooks/toolbox.yml` Ansible playbook — direct task imports for the company-tooling subset, cross-platform (Arch + Debian)
- `package-config`: The `config/toolbox-packages.yml` declarative package definitions with prerequisites, homebrew packages, removed apt packages/sources, and the Python parser that makes them available to shell scripts

### Modified Capabilities

## Impact

- **New files:** `bin/install.linux`, `bin/helpers/parse-packages.py`, `playbooks/toolbox.yml`, `config/toolbox-packages.yml`
- **Modified files:** `packages/tasks/ai.yml` (OS-split for opencode/openspec install strategy), `packages/tasks/homebrew.yml` (add tap support)
- **Dependencies:** Requires `community.general` Ansible collection (already in requirements.yml); Python 3 on target system (always present on Arch/Ubuntu)
- **Symlink:** Creates `/usr/local/bin/sf-toolbox` pointing to `bin/install.linux` for subsequent update runs
- **Repo cloned to:** `/opt/archlinux-provisioner` as canonical install location
- **Supersedes:** PR #181 (approach replaced by PR #190's Homebrew-based architecture)
