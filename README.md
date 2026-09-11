# README for Archlinux Ansible Provisioner

Welcome to the Archlinux Ansible Provisioner repository.

This project provides a comprehensive guide and a set of Ansible roles specifically designed to provision an Archlinux installation.

The purpose of this repository is to streamline the setup of Archlinux with a focus on personal and professional use.

## Disclaimer

Please be advised that this provisioner is provided **as-is**, with no warranty of any kind, either expressed or implied. It is intended solely for personal use, and its application is entirely at the user's own risk. The author(s) and contributor(s) of this repository are not responsible for any damage or loss resulting from the use of this provisioner.

It is also important to clarify that this provisioner is **not** intended to replace the official [Archlinux Installation Guide](https://wiki.archlinux.org/title/installation_guide).
The official guide is an invaluable resource for understanding the installation process and best practices for setting up Archlinux. Users are strongly encouraged to read and consult the official guide as a primary source of information.

## sf-toolbox — SparkFabrik Linux Toolbox

Standalone installer for SparkFabrik shared dev tools on Arch Linux, CachyOS, Omarchy, and Debian/Ubuntu. Works independently from the full system provisioner.

### Quick Bootstrap

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sparkfabrik/archlinux-ansible-provisioner/main/bin/bootstrap.sh)
```

### Usage

```bash
sf-toolbox                              # Update all tools
TAGS=ai,glab sf-toolbox                 # Run specific tags only
SKIP_TAGS=gcloud sf-toolbox             # Skip specific tags
```

### What Gets Installed

- **AI Coding**: opencode, openspec, codex
- **Desktop AI (opt-in)**: ChatGPT/Codex desktop (`chatgpt`) on supported platforms
- **Cloud/DevOps**: gcloud, glab, mkcert, docker (must be pre-installed)
- **Task Runner**: just, ajust (SparkFabrik wrapper)
- **Utilities**: gum, Upterm
- **HTTP Proxy**: spark-http-proxy (local .loc domains)

### ChatGPT desktop and package sources

Recipe access is configured by default; desktop installation is opt-in. Use:

```bash
CHATGPT_DESKTOP=1 TAGS=chatgpt-desktop sf-toolbox
```

Set `CHATGPT_DESKTOP=1` on later runs to update the desktop app too. Selecting its tag alone does not enable installation. Direct Ansible callers can pass `-e sf_toolbox_chatgpt_desktop=true`.

- **Arch Linux and CachyOS (x86_64):** sf-toolbox fetches reviewed recipes from `sparkfabrik/arch-packages`, builds `chatgpt-desktop` as a dedicated unprivileged user, and installs it through pacman. Later runs check the recipe version and update only when newer. No community AUR recipe or republished OpenAI binary is used.
- **Omarchy (x86_64):** install its own `openai-codex-desktop` package through pacman. Omarchy/yay handles updates; sf-toolbox does not build our recipe or replace existing desktop packages there.
- **Ubuntu 24.04/26.04 and Debian 13 (x86_64 and ARM64):** the first installation uses [OpenAI's official `.deb`](https://learn.chatgpt.com/docs/linux/linux-app). It configures OpenAI's signed apt repository, which handles subsequent updates.
- **Other platforms:** the desktop app is skipped; the remaining toolbox continues normally.

Launch it with `chatgpt`. The Codex CLI remains a separate tool. On Omarchy, its mise-managed CLI and existing desktop/web-app shortcuts are left alone. An existing Arch package named `chatgpt` is preserved rather than silently replaced.

Sf-toolbox also registers the SparkFabrik Git recipe source in `/etc/paru.conf`. An active user-level paru configuration must include the system configuration or carry the same section. Paru users can update recipes with `paru -Syu --mode repo,pkgbuilds`. Yay consumes the Omarchy desktop package and any configured binary repositories normally. On other Arch systems, yay can build a checked-out recipe with `yay -Bi <directory>`, but sf-toolbox handles updates to our Git-hosted desktop recipe. Sf-toolbox does not require or install either helper.

The binary pacman channel is separate and defaults to disabled. Enable `sparkfabrik_arch_repo: true` only after binary packages are published; initial activation verifies repository availability and the public-key fingerprint. Recipe access does not require that channel.

For direct Ansible use, `sf_toolbox_chatgpt_desktop` defaults to `false` and `sf_toolbox_arch_pkgbuilds: false` disables paru configuration. `sf_toolbox_arch_packages_revision` defaults to reviewed `main`; tests or controlled rollouts may pin a commit. Cached downloads and builds remain under `/var/cache/sf-toolbox/`.

### Requirements

- Arch Linux, CachyOS, Omarchy, Debian, or Ubuntu
- `git`, `zsh`, `docker`, `curl`, `python3` (and `node`/`npm` on Arch)

## About This Provisioner

This provisioner is based on Ansible and is structured into several roles for different aspects of the Archlinux setup:

### Playbooks/Roles Structure

```shell
playbooks/roles
├── bootstrap
├── gnome
├── logitech
├── nvidia
├── packages
└── system
```

- **bootstrap**: Bootstrap the base system using `pacstrap`, configure locales, hostname, time, and create the first sudoer user.
- **system**: Configure system services (e.g., bluetooth, audio, printing) and install some system dependencies.
- **gnome**: Install and configure Gnome Desktop Environment with extra packages, extensions, and custom shortcuts.
- **logitech**: Configure Logitech MX Master 2s mice with `logid`+`solaar`.
- **nvidia**: Install Nvidia drivers with `nvidia-prime` autodetection for hybrid graphics systems.
- **packages**: Install a comprehensive set of packages for development, multimedia, utilities, and more.

### Installation Guide

To install and use this provisioner, follow the detailed instructions provided in the [Installation Guide](INSTALLATION.md) section of this repository.

### Usage After Installation

This Ansible playbook is designed for both initial setup and subsequent adjustments. You can rerun the entire playbook or specific parts of it using tags.

For instance, to reapply Gnome configurations, use the following command:

```shell
TAGS=gnome-config CONFIG=./config/default.yaml make local-install-tags
```

## Contribution

Contributions to this repository are welcome. Please ensure that any contributions follow the existing structure and standards. For significant changes, open an issue first to discuss what you would like to change.

Enjoy your Arch Linux setup with this Ansible provisioner, and remember to use it wisely and at your own risk.
