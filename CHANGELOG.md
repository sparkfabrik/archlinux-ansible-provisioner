# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
