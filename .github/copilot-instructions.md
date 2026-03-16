# Copilot Instructions - Archlinux Ansible Provisioner

## Project Overview
This is an Ansible-based provisioner for setting up complete Archlinux systems with desktop environments, development tools, and personal configurations. It operates in two phases: **bootstrap** (initial system setup from live USB) and **system** (post-installation configuration).

## Architecture & Workflow

### Two-Phase Installation
1. **Bootstrap Phase**: Runs from Archlinux live USB to install base system via `pacstrap`
   - Command: `make bootstrap CONFIG=./config/default.yaml`
   - Configures locale, timezone, users, disk encryption (LUKS + BTRFS)

2. **System Phase**: Runs on installed system for desktop environment and packages
   - Command: `make local-install CONFIG=./config/default.yaml`
   - Installs GNOME/Sway/i3, development tools, SparkFabrik-specific configurations

### Role-Based Structure
All functionality is organized in `playbooks/roles/`:
- `bootstrap/`: Base system installation and user creation
- `system/`: Core services (audio, bluetooth, printing, power management)
- `packages/`: Software installation organized by category (development.yml, multimedia.yml, etc.)
- `gnome/`: Desktop environment with extensions and dconf settings
- `docker/`: Container runtime with custom network tools
- `nvidia/amd/`: Graphics driver installation with hybrid graphics support
- `sparkfabrik/`: Company-specific tools, wallpapers, and configurations

## Configuration System

### YAML Schema Validation
- Configuration in `config/default.yaml` validated against `config/schemas/configuration.schema.yaml`
- Use `make validate-json-schema` before any installation
- Desktop environments are conditionally enabled via config flags (`desktop.gnome`, `desktop.sway`, etc.)

### Key Configuration Patterns
```yaml
system:
  hostname: paolo
  username: paolo
  kernel: standard  # or zen, lts, hardened
desktop:
  gnome:
    extensions: [list-of-extension-ids]
    keybindings:
      open_terminal_shortcut: "<Super>Return"
    dconf:
      use_mouse_natural_scroll: true
```

## Development Workflows

### Local Testing & Iteration
- `make local-install-tags TAGS=gnome-config` - Run specific role tags
- `make local-install-apps` - Install only packages role
- `make regenerate-mkinitcpio-grub` - Rebuild bootloader after kernel changes

### Package Management Patterns
- Official packages: `community.general.pacman` module
- AUR packages: `kewlfft.aur.aur` module with `paru` helper
- Special `aur_builder` user created for AUR installations without sudo password

### Docker-Based Tooling
- `make build-docker-tools` - Build validation container with Node.js tools
- `make validate-json-schema` - Validate configuration files
- `make yaml-to-json` - Convert YAML templates to JSON

## Key Conventions

### Task Organization
- Each role's `main.yml` imports category-specific task files
- Use descriptive block names with appropriate tags: `[packages, dev, cloudnative]`
- Hardware-specific roles (nvidia, amd, logitech) use feature detection

### File Management
- Custom scripts and binaries in `files/bin/` directories
- Desktop environment configs in role-specific `files/` subdirectories
- System configuration files in `system/files/` (mkinitcpio.conf, systemd services)

### Conditional Logic
- Use `when:` conditions for hardware detection (e.g., nvidia-prime for hybrid graphics)
- Enable desktop environments via configuration flags, not hardcoded values
- Company-specific features controlled by `sparkfabrik: true` flag

## Critical Integration Points

### Disk Encryption & BTRFS
- LUKS encryption with BTRFS subvolumes: `@`, `@home`, `@snapshots`, `@home.snapshots`
- Bootloader installation varies by encryption: `install-grub-with-encryption` vs `install-grub-no-encryption`

### Chroot Operations
- System phase runs inside `arch-chroot /mnt` during initial installation
- Files copied to `/mnt/root/provisioner` before chroot execution

### AUR Package Installation
- Creates temporary `aur_builder` user with sudo privileges for makepkg/pacman
- All AUR operations must use `become_user: aur_builder`
- Paru AUR helper installed automatically if not present

When modifying this provisioner, ensure configuration schema validation passes and test changes with tag-specific runs before full system installation.