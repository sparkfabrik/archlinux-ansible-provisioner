# Docker Testing Limitations

This document outlines what can and cannot be executed when testing the Ansible playbook in an Arch Linux Docker container.

## ✅ What CAN be tested in Docker

### Package Management
- ✅ Package installation via `pacman`
- ✅ Package installation via AUR (with `paru` or `yay`)
- ✅ Ansible collection installation
- ✅ File manipulation and configuration
- ✅ User and group creation
- ✅ Directory structure creation
- ✅ Template rendering
- ✅ Package dependency resolution

### Configuration Files
- ✅ Creating/editing configuration files
- ✅ Setting file permissions
- ✅ Creating symlinks
- ✅ Copying files

### Basic Validation
- ✅ Syntax checking of playbooks
- ✅ Dry-run mode (`--check`)
- ✅ Verifying package availability
- ✅ Testing Ansible logic and conditionals

## ❌ What CANNOT be tested in Docker

### Systemd Operations
- ❌ Starting/stopping services (`systemctl start/stop`)
- ❌ Enabling services at boot (`systemctl enable`)
- ❌ Timer configuration (`systemctl enable *.timer`)
- ❌ Service status checks

**Reason:** Docker containers typically don't run systemd as PID 1, and systemd services cannot be managed without a proper init system.

**Affected Tasks:**
- `systemctl enable reflector.timer` (system role)
- `systemctl enable btrfs-scrub@-.timer` (system role)
- `systemctl enable fstrim.timer` (system role)
- Bluetooth service management
- Audio service management (pipewire)
- Printing service management (CUPS)

### Bootloader Configuration
- ❌ GRUB installation and configuration
- ❌ `grub-mkconfig` operations
- ❌ Boot partition management

**Reason:** Docker containers don't have a bootloader or boot partition.

**Affected Tasks:**
- All tasks in `grub.yml`
- Bootloader installation tasks

### Kernel Operations
- ❌ Kernel installation/removal
- ❌ Kernel module loading
- ❌ `mkinitcpio` operations
- ❌ Kernel parameter configuration

**Reason:** Docker containers share the host kernel and cannot modify it.

**Affected Tasks:**
- All tasks in `kernel.yml`
- Kernel firmware installation
- Kernel header installation

### Hardware-Specific Operations
- ❌ GPU driver installation (NVIDIA, AMD)
- ❌ Hardware detection and configuration
- ❌ Display server configuration (X11, Wayland)
- ❌ Audio hardware configuration
- ❌ Bluetooth hardware configuration
- ❌ Power management (laptop mode, TLP)

**Reason:** Docker containers don't have direct access to hardware.

**Affected Roles:**
- `nvidia` role
- `amd` role
- `logitech` role
- Audio configuration tasks
- Bluetooth configuration tasks
- Laptop power management

### Desktop Environment
- ❌ GNOME installation and configuration
- ❌ Sway/i3 window manager setup
- ❌ X11 or Wayland session configuration
- ❌ Desktop extensions and themes

**Reason:** GUI applications and desktop environments cannot run in a standard Docker container without X11 forwarding.

**Affected Roles:**
- `gnome` role
- `sway` role
- `i3` role

### Filesystem Operations
- ❌ Partition management
- ❌ Filesystem creation (btrfs, ext4)
- ❌ Swap file/partition configuration
- ❌ Disk mounting operations
- ❌ LUKS encryption setup

**Reason:** Docker containers have limited filesystem access and cannot manage partitions.

**Affected Tasks:**
- All tasks in `swapfile.yml`
- Btrfs scrub operations
- Disk encryption tasks

### Network Configuration
- ❌ NetworkManager configuration
- ❌ systemd-resolved configuration
- ❌ Network interface management

**Reason:** Docker containers use the host's network stack and cannot configure network interfaces directly.

## 🧪 CI Testing Strategy

The CI workflow (`test-playbook.yml`) implements the following strategy:

1. **Syntax Validation**: All playbooks are syntax-checked
2. **Dry-Run Mode**: Test playbooks in check mode to validate logic
3. **Selective Execution**: Only run Docker-compatible tasks
4. **Custom Test Playbook**: Use `ci-test.yml` which excludes incompatible tasks

### Test Coverage

The CI tests cover approximately 40-50% of the playbook functionality:
- ✅ Package installation logic
- ✅ File and directory management
- ✅ User and group creation
- ✅ Configuration file generation
- ❌ System service management
- ❌ Hardware-specific configuration
- ❌ Boot and kernel management

## 📝 Recommendations

1. **Syntax checks**: Run on all playbooks to catch YAML errors
2. **Check mode**: Use `--check` flag to test without making changes
3. **Tag-based testing**: Test individual roles using tags
4. **Mock configurations**: Use minimal test configurations (see `config/ci-test.yaml`)
5. **Manual testing**: Critical features should be tested on real Arch Linux systems
6. **Scheduled runs**: Run CI weekly to catch dependency issues and breaking changes

## 🔄 Future Improvements

To improve test coverage, consider:

1. Using systemd-enabled Docker containers (requires privileged mode)
2. Creating mock services for testing service management logic
3. Using Vagrant or cloud VMs for full integration testing
4. Implementing unit tests for individual Ansible tasks
5. Adding linting with `ansible-lint`

## 📚 Related Files

- `.github/workflows/test-playbook.yml` - GitHub Actions workflow
- `config/ci-test.yaml` - Minimal test configuration
- `playbooks/ci-test.yml` - Docker-compatible test playbook
