# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added Debian/Ubuntu compatibility for sparkdock, AI tooling, and shell setup using Homebrew as the package manager for dev tools on Debian systems
- Added Homebrew bootstrap task that auto-installs linuxbrew on Debian/Ubuntu systems
- Added OS-specific task file split pattern (e.g., `packages-arch.yml` / `packages-debian.yml`) to keep platform logic separated
- Added `gum spin` wrapper for headless `sparkdock-agents-sync` execution in non-interactive Ansible context
- Added CHANGELOG.md following Keep a Changelog conventions
