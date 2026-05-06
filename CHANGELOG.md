# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added `bin/install.linux` single-command installer/updater (`sf-toolbox`) with detect→plan→confirm→execute flow, gum integration, and conflict removal on Debian
- Added `playbooks/toolbox.yml` lightweight playbook for company tooling only (sparkdock, AI, glab, gcloud, http-proxy) without full system provisioning
- Added `config/toolbox-packages.yml` as single source of truth for package definitions consumed by both shell and Ansible
- Added `src/scripts/parse-packages.py` stdlib-only YAML parser for shell consumption
- Added `src/scripts/logging.sh` shared logging helpers (sourced from sparkdock) with gum integration and ANSI fallback
- Added Debian/Ubuntu compatibility for sparkdock, AI tooling, and shell setup using Homebrew as the package manager for dev tools on Debian systems
- Added Homebrew bootstrap task that auto-installs linuxbrew on Debian/Ubuntu systems
- Added OS-specific task file split pattern (e.g., `packages-arch.yml` / `packages-debian.yml`) to keep platform logic separated
- Added `gum spin` wrapper for headless `sparkdock-agents-sync` execution in non-interactive Ansible context
- Added CHANGELOG.md following Keep a Changelog conventions
