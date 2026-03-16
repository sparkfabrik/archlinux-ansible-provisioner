# README for Archlinux Ansible Provisioner

Welcome to the Archlinux Ansible Provisioner repository.

This project provides a comprehensive guide and a set of Ansible roles specifically designed to provision an Archlinux installation.

The purpose of this repository is to streamline the setup of Archlinux with a focus on personal and professional use.

## Continuous Integration

This repository includes automated testing via GitHub Actions to ensure the playbook remains functional. The CI workflow tests the playbook against a clean Arch Linux Docker image on every pull request and weekly on a schedule.

**Note:** Due to Docker limitations, not all tasks can be tested in CI. See [DOCKER-TESTING.md](docs/DOCKER-TESTING.md) for details on what can and cannot be tested in a containerized environment.

## Disclaimer

Please be advised that this provisioner is provided **as-is**, with no warranty of any kind, either expressed or implied. It is intended solely for personal use, and its application is entirely at the user's own risk. The author(s) and contributor(s) of this repository are not responsible for any damage or loss resulting from the use of this provisioner.

It is also important to clarify that this provisioner is **not** intended to replace the official [Archlinux Installation Guide](https://wiki.archlinux.org/title/installation_guide).
The official guide is an invaluable resource for understanding the installation process and best practices for setting up Archlinux. Users are strongly encouraged to read and consult the official guide as a primary source of information.

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

To install and use this provisioner, follow the detailed instructions provided in the [Installation Guide](docs/INSTALLATION.md) section of this repository.

### Usage After Installation

This Ansible playbook is designed for both initial setup and subsequent adjustments. You can rerun the entire playbook or specific parts of it using tags.

For instance, to reapply Gnome configurations, use the following command:

```shell
TAGS=gnome-config CONFIG=./config/default.yaml make local-install-tags
```

## Contribution

Contributions to this repository are welcome. Please ensure that any contributions follow the existing structure and standards. For significant changes, open an issue first to discuss what you would like to change.

Enjoy your Archlinux setup with this Ansible provisioner, and remember to use it wisely and at your own risk.

