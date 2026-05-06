## ADDED Requirements

### Requirement: OS detection

The script SHALL detect the operating system family by reading `/etc/os-release` and classify it as either `Archlinux` or `Debian`. The script SHALL fail with a clear error message on unsupported distributions.

#### Scenario: Arch Linux detected
- **WHEN** `/etc/os-release` contains `ID=arch`
- **THEN** OS_FAMILY is set to "Archlinux" and Arch-specific logic is used

#### Scenario: Ubuntu detected
- **WHEN** `/etc/os-release` contains `ID=ubuntu`
- **THEN** OS_FAMILY is set to "Debian" and Debian-specific logic is used

#### Scenario: Unsupported OS
- **WHEN** `/etc/os-release` contains an unrecognized ID (e.g., `fedora`)
- **THEN** the script exits with error "Unsupported OS: <ID>"

### Requirement: Prerequisite checking

The script SHALL check that all packages listed in `config/toolbox-packages.yml` under `prerequisites` (and `prerequisites_arch` on Arch) are available as commands on the system. The script SHALL fail with a clear message listing all missing prerequisites.

#### Scenario: All prerequisites present
- **WHEN** all prerequisite commands are found in PATH
- **THEN** the script proceeds to the next phase

#### Scenario: Missing prerequisites
- **WHEN** one or more prerequisite commands are not found
- **THEN** the script exits with error listing each missing command

### Requirement: Conflict detection on Debian

The script SHALL check for packages listed in `removed_apt_packages` that are currently installed via apt/dpkg. It SHALL also detect matching PPA source files in `/etc/apt/sources.list.d/` using the glob patterns in `removed_apt_sources`.

#### Scenario: Conflicting apt package found
- **WHEN** a package from `removed_apt_packages` is installed (detected via `dpkg -l`)
- **THEN** it is added to the conflicts list for presentation and removal

#### Scenario: Conflicting PPA source found
- **WHEN** a file in `/etc/apt/sources.list.d/` matches a pattern from `removed_apt_sources`
- **THEN** it is added to the sources removal list

#### Scenario: No conflicts on Arch
- **WHEN** the OS is Archlinux
- **THEN** conflict detection is skipped entirely

### Requirement: Plan presentation

The script SHALL present a summary of detected state and planned actions before making any changes. The summary SHALL include: OS and version, user, mode (install/update), list of tools to install, list of conflicts to remove, and list of tools already present. The script SHALL ask for confirmation before proceeding.

#### Scenario: User confirms
- **WHEN** the user responds with Y or presses Enter at the confirmation prompt
- **THEN** the script proceeds to the execution phase

#### Scenario: User declines
- **WHEN** the user responds with N at the confirmation prompt
- **THEN** the script exits cleanly with no changes made

### Requirement: Mode detection

The script SHALL detect whether this is a fresh install or an update by checking if `/opt/archlinux-provisioner/.git` exists.

#### Scenario: Fresh install
- **WHEN** `/opt/archlinux-provisioner/.git` does not exist
- **THEN** the script clones the repository to `/opt/archlinux-provisioner`

#### Scenario: Update
- **WHEN** `/opt/archlinux-provisioner/.git` exists
- **THEN** the script runs `git pull` in the existing directory

### Requirement: Conflict removal

On Debian, the script SHALL remove conflicting apt packages and their PPA source files before installing managed versions. Removal SHALL use `sudo apt-get remove --purge` for packages and `sudo rm` for source files.

#### Scenario: Remove apt package and PPA source
- **WHEN** a conflict is detected (e.g., glab from GitLab PPA)
- **THEN** the package is purged via apt and the matching sources.list.d file is deleted

### Requirement: Homebrew bootstrap on Debian

On Debian, the script SHALL install Homebrew (linuxbrew) if not already present. It SHALL run the official installer non-interactively as the current user.

#### Scenario: Homebrew not installed on Debian
- **WHEN** OS is Debian and `/home/linuxbrew/.linuxbrew/bin/brew` does not exist
- **THEN** the Homebrew installer is downloaded and run with `NONINTERACTIVE=1`

#### Scenario: Homebrew already installed
- **WHEN** `/home/linuxbrew/.linuxbrew/bin/brew` exists
- **THEN** Homebrew installation is skipped

#### Scenario: Arch Linux
- **WHEN** OS is Archlinux
- **THEN** Homebrew installation is skipped entirely

### Requirement: Ansible installation

The script SHALL ensure Ansible is available. On Arch it SHALL use `pacman -S ansible`. On Debian it SHALL use `brew install ansible`.

#### Scenario: Ansible not installed on Arch
- **WHEN** `ansible-playbook` is not in PATH and OS is Archlinux
- **THEN** the script runs `sudo pacman -S --noconfirm ansible`

#### Scenario: Ansible not installed on Debian
- **WHEN** `ansible-playbook` is not in PATH and OS is Debian
- **THEN** the script runs `brew install ansible`

#### Scenario: Ansible already available
- **WHEN** `ansible-playbook` is already in PATH
- **THEN** Ansible installation is skipped

### Requirement: Ansible playbook execution

The script SHALL run `sudo ansible-playbook playbooks/toolbox.yml -i localhost, -c local` from the repo directory. It SHALL support a `TAGS` environment variable to filter which tasks run.

#### Scenario: Full run
- **WHEN** TAGS is not set
- **THEN** all tasks in toolbox.yml are executed

#### Scenario: Filtered run
- **WHEN** TAGS is set (e.g., `TAGS=sparkdock,ai`)
- **THEN** only matching tagged tasks are executed via `--tags`

### Requirement: Symlink creation

After successful execution, the script SHALL create a symlink at `/usr/local/bin/sf-toolbox` pointing to `bin/install.linux` in the repo, so users can run `sf-toolbox` for subsequent updates.

#### Scenario: Symlink created
- **WHEN** the playbook finishes successfully
- **THEN** `/usr/local/bin/sf-toolbox` symlinks to `/opt/archlinux-provisioner/bin/install.linux`

### Requirement: Graceful output

The script SHALL use ANSI-colored output for status messages (info, success, warning, error). If `gum` is available, it MAY use `gum style` for bordered presentation boxes. The script SHALL NOT depend on gum — plain ANSI is the fallback.

#### Scenario: gum available
- **WHEN** `gum` is found in PATH
- **THEN** the plan summary is rendered with `gum style` bordered box

#### Scenario: gum not available
- **WHEN** `gum` is not in PATH
- **THEN** the plan summary is rendered with plain printf and ANSI colors
