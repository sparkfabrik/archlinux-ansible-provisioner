# README for Archlinux Ansible Provisioner

Welcome to the Archlinux Ansible Provisioner repository.

This project provides a comprehensive guide and a set of Ansible roles specifically designed to provision an Archlinux installation.

The purpose of this repository is to streamline the setup of Archlinux with a focus on personal and professional use.

## Disclaimer

Please be advised that this provisioner is provided **as-is**, with no warranty of any kind, either expressed or implied. It is intended solely for personal use, and its application is entirely at the user's own risk. The author(s) and contributor(s) of this repository are not responsible for any damage or loss resulting from the use of this provisioner.

It is also important to clarify that this provisioner is **not** intended to replace the official [Archlinux Installation Guide](https://wiki.archlinux.org/title/installation_guide).
The official guide is an invaluable resource for understanding the installation process and best practices for setting up Archlinux. Users are strongly encouraged to read and consult the official guide as a primary source of information.

## sf-toolbox — SparkFabrik Linux Toolbox

Standalone installer for SparkFabrik shared dev tools on supported Arch Linux-family distributions (`Arch Linux`, `CachyOS`, `EndeavourOS`, `Manjaro`) and Debian/Ubuntu. Works independently from the full system provisioner.

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

- **AI Coding**: opencode, openspec
- **Cloud/DevOps**: gcloud, glab, mkcert, docker (must be pre-installed)
- **Task Runner**: just, ajust (SparkFabrik wrapper)
- **Utilities**: gum
- **HTTP Proxy**: spark-http-proxy (local .loc domains)

### Requirements

- Supported Arch Linux-family distributions (`Arch Linux`, `CachyOS`, `EndeavourOS`, `Manjaro`), Debian, or Ubuntu
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

Enjoy your Archlinux setup with this Ansible provisioner, and remember to use it wisely and at your own risk.
