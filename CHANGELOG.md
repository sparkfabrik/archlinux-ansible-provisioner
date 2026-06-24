# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `sf-toolbox` now installs and refreshes global OpenSpec skills and prompt commands (`~/.claude/skills/openspec-*`, `~/.claude/commands/opsx/*`) for Claude during provisioning by running `ajust sf-openspec-install-global claude`, mirroring the macOS sparkdock provisioning; idempotent and skipped when the OpenSpec CLI is absent ([sparkfabrik/sparkdock#521](https://github.com/sparkfabrik/sparkdock/pull/521))
- Enable the Claude Code `gh` skill gate automatically in the `sf-toolbox` role by running the sparkdock-installed `claude-gh-gate.py enable` (blocks raw `gh` commands until the `gh` skill is loaded), with a fallback warning to run `ajust claude-gh-gate-enable` manually if the sparkdock script is missing. Mirrors the existing caveman/rtk setup pattern and the macOS sparkdock provisioning.
- Install `spark-http-proxy` on Linux via a git clone + symlink (under `~/.local/spark/http-proxy/src`) instead of a standalone downloaded script, mirroring the macOS sparkdock mechanism. This makes `spark-http-proxy self-update` work, keeps the compose file in sync with the CLI, and deterministically updates to the latest `main` on every provision. Migrates existing installs by replacing the standalone CLI file with a symlink and removing the now-stale standalone `compose.yml` that would otherwise shadow the clone
- Added `http-proxy-install-update` ajust recipe (group `http-proxy`) for parity with macOS sjust; updates `spark-http-proxy` via the CLI's own `self-update` (git-pulls the clone it was installed from), so it needs no provisioner checkout or config
- Fixed the `provision-tags` ajust recipe default `provisioner_path` (`$HOME/provisioner` → `/opt/archlinux-provisioner`, where `bootstrap.sh`/`install.linux` install the provisioner) so provisioner-tag recipes find the checkout without manually setting `AJUST_PROVISIONER_PATH`
- Configured `*.loc` local DNS resolution on all OSes (including Debian/Ubuntu) by invoking `spark-http-proxy configure-dns` during `sf-toolbox` provisioning
- Added `ripgrep` (`rg`) to `sf-toolbox` packages for both Arch Linux (pacman) and Debian/Ubuntu (Homebrew)
- Added language server binaries for Claude Code's official code-intelligence plugins to the `sf-toolbox` role so org-level `enabledPlugins` can wire them in without per-machine setup: `intelephense`, `typescript`, `typescript-language-server`, `pyright` via npm (covers `php-lsp`, `typescript-lsp`, `pyright-lsp` plugins) and `gopls` via pacman on Arch / Homebrew on Debian/Ubuntu (covers `gopls-lsp` plugin). LSP processes only spawn when matching file extensions are present in the workspace, so devs not working in a given language pay no runtime cost
- Switched Claude Code from `claude-code` (stable) to `claude-code@latest` cask on Debian/Ubuntu, which tracks latest releases instead of pinned stable versions; includes migration task to auto-uninstall old cask
- Added `/usr/local/bin/sparkfabrik-claude-code-otel-headers` — Claude Code OTLP `otelHeadersHelper` script, sourced from sparkdock ([sparkfabrik/sparkdock#483](https://github.com/sparkfabrik/sparkdock/pull/483)).
- Added automatic caveman configuration via sparkdock setup script (`sjust/scripts/caveman/setup.sh`) in `sf-toolbox` role, with fallback warning to run `ajust sf-caveman-install` manually
- Added automatic rtk configuration via sparkdock setup script after installation, with fallback warning to run `ajust sf-rtk-setup` manually
- Added rtk-ai (Rust Token Killer) installation to `sf-toolbox` role with automatic version management from GitHub releases
- Added GitHub Copilot CLI as a managed sf-toolbox coding agent (npm on Arch, brew cask on Debian/Ubuntu)
- Added Claude Code as a managed sf-toolbox coding agent (curl installer on Arch, brew cask on Debian/Ubuntu)
- Added Homebrew cask support to sf-toolbox packages task for Debian/Ubuntu
- Added `--help` / `-h` flag to `sf-toolbox` with colored output and OS detection display
- Added `playbooks/roles/sf-toolbox/` role with per-tool task files (packages, gcloud, ai, glab, ajust, http-proxy)
- Added `detect` section in toolbox package definitions for binary detection in the installer
- Added clean arch/debian separation in toolbox package definitions with dotted-path support in the parser

### Changed

- Delegated `*.loc` systemd-resolved configuration to the `spark-http-proxy` CLI and removed the bespoke `docker` role drop-in (`docker-dev-dns.conf`, `172.17.0.1:19322`); the CLI now writes `http-proxy.conf` (`127.0.0.1:19322`). Legacy `~docker`/dnsdock routing is no longer configured
- Replaced the obsolete Python `yq` package (pacman) with `go-yq`, the mikefarah Go yq v4 (`extra` repo); the old `yq` is now removed first since the two packages conflict
- Homebrew formulae, casks, and rtk now install with `state: latest` so packages upgrade on every run
- Split rtk installation by OS: GitHub releases on Archlinux, Homebrew on Debian/Ubuntu
- Moved `github-cli` (gh) installation from `packages` role to `sf-toolbox` role with Debian/Ubuntu support via Homebrew
- Moved GitHub Copilot CLI installation from `packages/tasks/development.yml` to sf-toolbox role
- Disabled Google Cloud SDK usage reporting both at install time (`--usage-reporting false`) and persistently via `gcloud config set core/disable_usage_reporting true` to avoid sending telemetry to Google
- Moved opencode base configuration from `~/.config/opencode/opencode.json` to `/etc/opencode/opencode.json` (user-owned, in a `root:root` directory) to support user-local overrides via `~/.config/opencode/opencode.json`
- Added automatic cleanup of duplicate `~/.config/opencode/opencode.json` when identical to the shipped source, with a warning when the file contains non-custom content
- Standardized all shell variable references in `bin/install.linux` to use curly braces syntax (`${VAR}`)
- Moved `config/toolbox-packages.yml` into `playbooks/roles/sf-toolbox/vars/main.yml` (auto-loaded by Ansible, no more `include_vars`)
- Renamed `playbooks/toolbox.yml` to `playbooks/sf-toolbox.yml` for consistent naming with the `sf-toolbox` role and installer
- Restructured toolbox package config from flat keys to nested `arch`/`debian`/`common` sections
- Moved `src/scripts/parse-packages.py` to `bin/common/parse-toolbox-packages.py` with support for dotted key paths
- Moved `just`/`gum` package installation from sparkdock role to sf-toolbox role
- Moved ajust setup (wrapper, justfile, completion, recipes) from sparkdock role to sf-toolbox role
- Stripped sparkdock role down to git clone + agent resources sync only
- Simplified `bin/install.linux` — removed conflict detection/removal, removed plan presentation, added detect/inform status display
- Removed invasive apt package and PPA source removal on Debian (Homebrew PATH precedence handles conflicts)
- Updated `system.yml` to import sf-toolbox role (alongside existing roles)

### Fixed

- Fixed `sf-toolbox` npm packages (e.g. `@fission-ai/openspec`) never upgrading after first install by switching the Arch and Debian/Ubuntu npm install tasks from `state: present` to `state: latest`, matching the existing Homebrew behavior
- Fixed rtk not detected by sf-toolbox conflict system; added `rtk` to `toolbox.detect` list and `is_sf_managed()`, removed redundant per-role `which -a` detection that didn't feed into the conflict resolver
- Fixed `resolve_repo_dir` in `bin/install.linux` always preferring `/opt/archlinux-provisioner` over local checkout, preventing local development testing
- Fixed `sf-toolbox` OS detection to treat `CachyOS` as `Archlinux`
- Fixed `sf-toolbox` symlink breaking `SCRIPT_DIR` resolution by resolving symlinks with `readlink -f` before computing the directory

### Removed

- Removed `playbooks/roles/packages/tasks/ai.yml`, `glab.yml`, `gcloud.yml`, `homebrew.yml` (merged into sf-toolbox)
- Removed `playbooks/roles/docker/tasks/sparkfabrik-http-proxy.yml` (merged into sf-toolbox)
- Removed `playbooks/roles/sparkdock/tasks/packages-arch.yml` and `packages-debian.yml` (merged into sf-toolbox)
- Removed sparkdock zshrc sourcing (replaced by ajust shell integration)

- Added GitHub Actions CI workflow testing the toolbox playbook on Ubuntu 24.04, Ubuntu 26.04, and Arch Linux
- Added `bin/install.linux` single-command installer/updater (`sf-toolbox`) with detect→plan→confirm→execute flow, gum integration, and conflict removal on Debian
- Added `playbooks/toolbox.yml` lightweight playbook for company tooling only (sparkdock, AI, glab, gcloud, http-proxy) without full system provisioning
- Added `config/toolbox-packages.yml` as single source of truth for package definitions consumed by both shell and Ansible
- Added `src/scripts/parse-packages.py` stdlib-only YAML parser for shell consumption
- Added `bin/common/logging.sh` shared logging helpers (sourced from sparkdock) with gum integration and ANSI fallback
- Added Debian/Ubuntu compatibility for sparkdock, AI tooling, and shell setup using Homebrew as the package manager for dev tools on Debian systems
- Added Homebrew bootstrap task that auto-installs linuxbrew on Debian/Ubuntu systems
- Added OS-specific task file split pattern (e.g., `packages-arch.yml` / `packages-debian.yml`) to keep platform logic separated
- Added `gum spin` wrapper for headless `sparkdock-agents-sync` execution in non-interactive Ansible context
- Added CHANGELOG.md following Keep a Changelog conventions
