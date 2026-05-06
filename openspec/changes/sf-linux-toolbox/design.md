## Context

SparkFabrik has ~majority macOS developers using `sparkdock` (clone + `install.macos` → all company tools installed), plus a minority on Linux (Arch and Ubuntu at various versions). The current `archlinux-ansible-provisioner` handles full Arch system provisioning (kernel, desktop, drivers, packages) alongside company tooling. Ubuntu users have no equivalent — they manually install tools or rely on stale PPAs.

PR #190 (`feat/debian-ubuntu-sparkdock-compat-189`) already landed the OS-specific task split pattern (Homebrew on Debian for dev tools, pacman on Arch) and Debian support for sparkdock, glab, http-proxy, and gcloud roles.

What's missing is the **entry point** — a single script that bootstraps everything and a focused playbook that runs only the company-relevant subset.

## Goals / Non-Goals

**Goals:**

- Single command (`bin/install.linux` or `sf-toolbox`) to install/update all SparkFabrik shared tooling on Arch or Ubuntu
- Detect-present-confirm flow: show the user what will happen before making changes
- Handle conflict resolution (stale apt/PPA packages that clash with brew-managed versions)
- Declarative package config (`config/toolbox-packages.yml`) as single source of truth for both the shell script and Ansible
- Self-updating: subsequent runs pull latest and re-run ansible
- No npm dependency on Debian (opencode + openspec via Homebrew)

**Non-Goals:**

- Full system provisioning on Ubuntu (kernel, drivers, desktop, base packages)
- Replacing the existing `system.yml` workflow for Arch full installs
- Docker installation (assumed pre-installed)
- Zsh configuration beyond sparkdock.zshrc sourcing (oh-my-zsh, starship, etc. are user's responsibility)
- Supporting non-Debian/Ubuntu Linux distros (Fedora, NixOS, etc.)
- Interactive tool selection menu (all-or-nothing for now)

## Decisions

### 1. Single script for install and update

**Decision:** One `bin/install.linux` script handles both first-time install and updates, detecting mode by checking if `/opt/archlinux-provisioner` exists.

**Rationale:** Mirrors sparkdock's pattern where `sparkdock.macos` is both installer and updater. Simpler onboarding ("just run this one command"). The symlink at `/usr/local/bin/sf-toolbox` gives users a memorable command for subsequent runs.

**Alternative considered:** Separate `install.linux` + `sf-toolbox` scripts. Rejected because the logic overlap is >90% and maintaining two scripts creates drift.

### 2. Direct task imports in toolbox.yml (not role imports)

**Decision:** `playbooks/toolbox.yml` uses `import_tasks:` to directly import specific task files from roles, not `roles:` directive.

**Rationale:** Importing full roles would parse ALL task files in that role (including `base.yml`, `development.yml`, etc.) even when filtered by tags. Direct imports load only what's needed — no risk of parsing failures from Arch-specific tasks on Ubuntu. Explicit and minimal.

**Alternative considered:** `roles:` + `--tags` filtering. Rejected because role `main.yml` imports everything and tags only filter at runtime — any parse-time issues in unrelated files would still surface.

### 3. Homebrew for dev tools on Debian only

**Decision:** Homebrew (linuxbrew) is the package manager for dev tools on Debian/Ubuntu. Arch continues using pacman for everything available in official repos.

**Rationale:** Ubuntu's apt repos have ancient or missing versions of tools like just, gum, glab, mkcert. Homebrew provides current versions with pre-built bottles (fast). On Arch, pacman's official repos already have current versions — adding brew would create package manager confusion.

**Alternative considered:** apt PPAs for each tool, snap, or direct binary downloads. Rejected because managing N different sources is fragile; Homebrew is a single, well-maintained aggregator.

### 4. Python helper for YAML parsing in shell

**Decision:** A small `bin/helpers/parse-packages.py` script (stdlib only, no PyYAML) parses `config/toolbox-packages.yml` for the shell script to consume.

**Rationale:** The shell script runs before Ansible/brew/yq are available, so we can't depend on them. Python 3 is always present on both Arch and Ubuntu. The YAML format is simple enough (flat lists) to parse without PyYAML using regex.

**Alternative considered:** Inline sed/awk parsing in bash. Rejected because it's brittle and harder to maintain. Python is more readable and testable.

### 5. Conflict cleanup in shell, not Ansible

**Decision:** The `bin/install.linux` script removes conflicting apt/PPA packages before invoking Ansible. Ansible tasks only do fresh installs.

**Rationale:** Clean separation of concerns — the script handles "make the system ready" and Ansible handles "install what we want." Also, Ansible would need `sudo` and apt module calls interleaved with brew calls, making the playbook messier.

### 6. AI tools install strategy (opencode: pacman on Arch, brew on Debian; openspec: npm on Arch, brew on Debian)

**Decision:** opencode installs from Arch `extra` repo (pacman) on Arch and from `anomalyco/tap` (brew) on Debian. openspec installs from npm on Arch and from brew on Debian. The npm-installed `opencode-ai` package is removed on Arch (migration).

**Rationale:** opencode is now in the official Arch `extra` repository — pacman is the canonical install method. openspec is not in pacman/AUR, so npm remains necessary on Arch only. On Debian, both are in Homebrew, eliminating the node/npm prerequisite entirely.

### 7. Presentation before action

**Decision:** The script detects everything (OS, prerequisites, installed tools, conflicts), then presents a summary and asks for confirmation before making any changes.

**Rationale:** Builds trust — developers see exactly what will happen on their machine. Mirrors the UX of package managers (`apt` shows what it will install before proceeding). Uses ANSI colors/formatting; uses `gum` for nicer output if already available, falls back gracefully.

## Risks / Trade-offs

- **[Homebrew version drift]** → Brew packages update independently of the provisioner. A `brew upgrade` by the user could update tools beyond what the team expects. Mitigation: we don't pin versions; latest is acceptable for dev tools.

- **[Python 3 availability]** → Extremely unlikely to be missing, but an ancient Ubuntu (16.04) might only have Python 2. Mitigation: we only support Ubuntu 22.04+ (document in README).

- **[/opt/archlinux-provisioner permissions]** → Cloning to `/opt/` requires sudo for initial directory creation. Mitigation: script creates dir with `sudo mkdir` then `chown`s it to the user, so subsequent git operations don't need root.

- **[Ansible version skew on Debian]** → `brew install ansible` gives latest, which may have deprecation warnings for older module syntax in the codebase. Mitigation: the codebase already uses FQCN and modern syntax per AGENTS.md guidelines.

- **[Breaking the existing Arch full-install flow]** → Risk of accidentally affecting `system.yml` while modifying shared task files. Mitigation: `toolbox.yml` imports task files directly — no changes to `system.yml` or role `main.yml` structure.
