## ADDED Requirements

### Requirement: YAML package definitions

The file `config/toolbox-packages.yml` SHALL define all package-related configuration in a single YAML file. It SHALL contain the following top-level keys: `prerequisites`, `prerequisites_arch`, `homebrew_taps`, `homebrew_packages`, `removed_apt_packages`, `removed_apt_sources`, `removed_npm_packages`.

#### Scenario: Valid YAML structure
- **WHEN** the file is parsed by Python or Ansible
- **THEN** all keys resolve to lists of strings

### Requirement: Prerequisites definition

The `prerequisites` key SHALL list commands that MUST be available on all platforms before the toolbox can run. The `prerequisites_arch` key SHALL list additional commands required only on Arch Linux.

#### Scenario: Common prerequisites
- **WHEN** the toolbox targets any Linux system
- **THEN** `prerequisites` includes: git, zsh, docker, curl, python3

#### Scenario: Arch-specific prerequisites
- **WHEN** the toolbox targets Arch Linux
- **THEN** `prerequisites_arch` includes: node, npm (needed for openspec)

### Requirement: Homebrew package list

The `homebrew_packages` key SHALL list all packages to install via Homebrew on Debian/Ubuntu systems. These same packages are installed via pacman on Arch (mapped in the Ansible tasks, not in this file).

#### Scenario: Package list content
- **WHEN** the toolbox installs on Debian
- **THEN** `homebrew_packages` includes: just, gum, glab, mkcert, anomalyco/tap/opencode, openspec

### Requirement: Homebrew taps

The `homebrew_taps` key SHALL list Homebrew taps that MUST be added before installing packages that require them.

#### Scenario: Tap required for opencode
- **WHEN** the toolbox installs opencode via brew on Debian
- **THEN** `homebrew_taps` includes `anomalyco/tap` and it is added before package installation

### Requirement: Conflict package list

The `removed_apt_packages` key SHALL list apt package names that conflict with brew-managed versions and MUST be removed before installation on Debian.

#### Scenario: Conflict list
- **WHEN** the toolbox detects conflicting packages on Debian
- **THEN** it checks against: glab, google-cloud-cli, google-cloud-cli-gke-gcloud-auth-plugin, mkcert, just, gum

### Requirement: PPA source patterns

The `removed_apt_sources` key SHALL list glob patterns used to find and remove stale PPA source files from `/etc/apt/sources.list.d/`.

#### Scenario: Source cleanup patterns
- **WHEN** the toolbox cleans up conflicting sources
- **THEN** it removes files matching: `*gitlab*`, `*charm*`, `*cloud.google*`

### Requirement: Removed npm packages

The `removed_npm_packages` key SHALL list npm global packages to remove (migration cleanup). On Arch, `opencode-ai` is removed because opencode is now installed via pacman.

#### Scenario: npm migration cleanup
- **WHEN** the toolbox runs on Arch
- **THEN** `opencode-ai` npm package is removed if present

### Requirement: Python parser

A `bin/helpers/parse-packages.py` script SHALL parse the YAML config using only Python 3 standard library (no PyYAML dependency). It SHALL accept a file path and a key name as arguments and output the list items one per line to stdout.

#### Scenario: Parse prerequisites
- **WHEN** `python3 bin/helpers/parse-packages.py config/toolbox-packages.yml prerequisites` is run
- **THEN** stdout contains one prerequisite per line (git, zsh, docker, curl, python3)

#### Scenario: Parse homebrew packages
- **WHEN** `python3 bin/helpers/parse-packages.py config/toolbox-packages.yml homebrew_packages` is run
- **THEN** stdout contains one package per line including quoted values like `anomalyco/tap/opencode`

#### Scenario: Non-existent key
- **WHEN** a key that doesn't exist in the YAML is requested
- **THEN** no output is produced (empty result, exit 0)
