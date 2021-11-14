# Archlinux ansible provisioner

This is a guide and a set of ansible roles to provision an Archlinux
installation, please be aware this is made just for personal use, use it at your own risk.

This Archlinux provisioner is not inteded bo a replacement of the Archlinux installation wiki (https://wiki.archlinux.org/title/installation_guide),
which i higly reccomend to read it, it's a very precious source of information and best practices.

This installer is based on Ansible, and it's composed by several roles:

```
playbooks/roles
├── bootstrap
├── gnome
├── logitech
├── nvidia
├── packages
└── system
```

* `bootstrap`: Bootstrap the base system using pacstrap, configure locales, hostname, time and create the first sudoer user. 
* `system`: Configure system services (bluetooth, audio, printing) and install some system dependencies.
* `gnome`: Install and configure Gnome DE with some extra packages, extensions and some custom shortcuts.
* `logitech`: Configure Logitech MX Master 2s mices with logid+solaar.
* `nvidia`: Install Nvidia drivers with nvidia-prime autodetection in case of hybrid graphics system
* `packages`: Install all needed packages for development, multimedia, utilities and so on.

To install it, just follow the [Installation guide](INSTALLATION.md)

You can find the full `pkglist` on the root of this repository, which is kept automatically updated from a running system

## Usage after installation

Once you've installed Archlinux using this ansible playbook, you can always re-run it totally or just partially, using tags.

For example, if you want to re-run again the Gnome configurations, you can run: `TAGS=gnome-config CONFIG=./config/default.yaml make local-install-tags`