# AGENTS.md - Archlinux Ansible Provisioner

## Project Overview

Ansible-based provisioner for Arch Linux systems. Manages full system setup:
bootstrap, system services, desktop environments (Gnome/Sway/i3), packages,
drivers (Nvidia/AMD), Docker, and hardware-specific configs (Logitech).

Configuration is YAML-driven (`config/default.yaml`) validated against a JSON
schema (`config/schemas/configuration.schema.yaml`). Playbooks run locally with
`sudo` -- `become` is never set at the play level.

## Build / Validate / Run Commands

```shell
make init                                        # Install Ansible Galaxy deps
make validate-json-schema                        # Validate config (Docker required)
CONFIG=./config/custom.yaml make validate-json-schema

make local-install                               # Full install (validate + all roles)
TAGS=gnome-config CONFIG=./config/default.yaml make local-install-tags  # Single tag
TAGS=packages,dev CONFIG=./config/default.yaml make local-install-tags  # Multiple tags

# Run a single role directly (without Make)
sudo ansible-playbook ./playbooks/system.yml -i localhost, -c local \
  --tags docker --extra-vars "@./config/default.yaml"

make ansible-system-check                        # Syntax-check playbooks against config
make local-install-apps                          # Packages only
make regenerate-mkinitcpio-grub                  # Regenerate mkinitcpio + grub
make generate-json-schema-docs                   # Schema docs (Docker required)
make install-githooks                            # Install git hooks
```

## Repository Structure

> **Agent rule:** When adding, removing, or renaming files or directories that
> affect this structure, update this section to keep it accurate.

```
playbooks/
  bootstrap.yml          # Pacstrap + base system config
  system.yml             # Main playbook: pre_tasks + all roles
  roles/
    amd/                 # AMD GPU drivers
    bootstrap/           # Base system (pacstrap, locales, user)
    distro/              # Distribution detection and info
    docker/              # Docker + optional HTTP proxy
    gnome/               # Gnome DE, extensions, dconf, keybindings
    i3/ | logitech/ | nvidia/ | sway/   # WMs + hardware drivers
    packages/            # All user packages (dev, multimedia, fonts, etc.)
    sparkdock/ | sparkfabrik/            # SparkFabrik internal tooling
    system/              # Core services (DNS, bluetooth, audio, grub, etc.)
config/
  default.yaml.tpl       # Configuration template -- copy to default.yaml
  schemas/               # JSON schema for config validation
```

## Ansible Code Style Guidelines

### YAML Formatting

- Start every YAML file with `---` document marker.
- Use **2-space indentation** throughout.
- Indent `block:` contents by **4 spaces** relative to the `block:` keyword:
  ```yaml
  - name: Install and configure docker
    tags: [docker]
    block:
      - name: Install docker
        community.general.pacman:
          name:
            - docker
            - docker-compose
  ```

### Boolean Values

- Use `true`/`false` (not `yes`/`no`) for all new code.

### Module Naming (FQCN)

- Always use **Fully Qualified Collection Names** for new code:
  `ansible.builtin.copy`, `ansible.builtin.file`, `ansible.builtin.shell`,
  `ansible.builtin.systemd`, `ansible.builtin.command`, `ansible.builtin.stat`,
  `ansible.builtin.lineinfile`, `ansible.builtin.git`, `ansible.builtin.set_fact`,
  `community.general.pacman`, `community.general.ini_file`, `kewlfft.aur.aur`.

### Task Naming

- Use **sentence case** (capitalize first word only): `"Install docker"`.
- Be descriptive but concise. No trailing period.
- Use backticks for technical terms: ``"Create the `aur_builder` user"``.

### Tags

- Always use **bracket list syntax**: `tags: [system, bluetooth]`.
- Tags are **lowercase**, single words or hyphenated: `gnome-config`, `spark-http-proxy`.
- Apply tags at the **block or import level**, not on individual tasks within blocks.

### Variables

- Reference with **spaces inside braces**: `{{ system.username }}`.
- Use **dot notation** for nested access: `desktop.gnome.dconf.clock_show_seconds`.
- **Double-quote** any value that starts with `{{`:
  ```yaml
  become_user: "{{ system.username }}"
  dest: "{{ system.home }}/.config/app/config.json"
  ```
- Use `| default()` for optional variables:
  ```yaml
  when: sparkfabrik | default(false)
  owner: "{{ system.username | default(current_user) }}"
  ```
- Variable names use **snake_case**: `configure_hibernate`, `install_chrome_beta`.

### `become` / Privilege Escalation

- Never set `become` at the play level -- playbooks run via `sudo`.
- Set `become` at the **block or task level** when switching users:
  ```yaml
  - name: Install AUR package
    become: true
    become_user: aur_builder
    kewlfft.aur.aur:
      name: some-package
  ```

### Conditionals

- Preferred pattern for booleans: `when: variable == true` or `when: variable | default(false)`.
- Command output checks: `when: result.stdout != ""`.
- Multi-condition: use `and`/`or` inline or YAML list for implicit AND.

### No Templates / No Handlers

- This codebase uses **no Jinja2 templates** (`.j2` files) and **no handlers**.
- Small config files are created inline with `copy:` + `content: |`.
- Use `ansible.builtin.lineinfile` or `replace` for modifying existing files.
- Services are enabled/restarted via direct `ansible.builtin.systemd` tasks.

### Task Organization

- Split complex roles into sub-files by concern (e.g., `dns.yml`, `bluetooth.yml`).
- Use `import_tasks:` (static import) in `main.yml` -- never `include_tasks:`.
- Use `block:` as the primary structural unit to group related tasks.
- Prefer `community.general.pacman` with `name:` list over `loop:` for packages.
- Quote octal file modes as strings: `mode: "0755"`, `mode: "0644"`.

### Error Handling

- Use `ignore_errors: true` for hardware detection commands that may fail.
- Use `register:` to capture command output for conditional logic.
- Use `changed_when: false` on read-only commands; `failed_when: false` on optional probes.

### Configuration Schema

When adding new configurable features:

1. Add the variable to `config/default.yaml.tpl` with a sensible default.
2. Add the schema definition to `config/schemas/configuration.schema.yaml`.
3. Use `| default()` in tasks for backward compatibility.

### Adding or Modifying Packages in `packages` and `sparkdock` Roles

Packages are **never hardcoded** in task files. Each role that installs packages
uses a distro-specific vars file and references package lists by variable name.

**Vars files location:**

- `playbooks/roles/packages/vars/Archlinux.yml` — all package lists for the `packages` role.
- `playbooks/roles/sparkdock/vars/Archlinux.yml` — package lists for the `sparkdock` role.

**Vars file format:** Each variable is a YAML list named with a descriptive
`snake_case` key, prefixed by concern, suffixed `_aur` for AUR-only packages.
A comment above each list references the task file path (relative to repo root)
that consumes it:

```yaml
# playbooks/roles/<role>/tasks/<file>.yml
browser_pkgs_aur:
  - google-chrome
  - firefox
```

**How task files are structured:** Each task file has a standalone `include_vars`
task **before** any blocks, loading the distro-specific vars file into the
`distro_packages` namespace. Blocks then reference `distro_packages.<variable_name>`.

```yaml
---
- name: Load packages variables
  tags: [packages, dev, cloudnative]
  ansible.builtin.include_vars:
    file: "{{ ansible_facts['distribution'] }}.yml"
    name: distro_packages

- name: Install cloud native packages
  tags: [packages, dev, cloudnative]
  block:
    - name: Install cloud native packages
      when: ansible_facts['distribution'] == "Archlinux"
      community.general.pacman:
        name: "{{ distro_packages.development_pkgs_cloudnative }}"

- name: Install development packages
  tags: [packages, dev]
  block:
    - name: Install development packages
      when: ansible_facts['distribution'] == "Archlinux"
      community.general.pacman:
        name: "{{ distro_packages.development_pkgs_dev }}"
```

**`include_vars` rules:**

- Placed **once per file**, at the top, **outside** any block.
- Its `tags:` list must be the **union of all tags** from every block in the
  file, including inner task tags (e.g., if a task inside a block has
  `tags: [audio]`, add `audio` to the `include_vars` tags).
- The variable name is always `distro_packages`.
- **Never** duplicate the `include_vars` call inside or across blocks.

**Steps to add a new package:**

1. Open the role's `vars/Archlinux.yml`.
2. Find the matching variable list for the concern (e.g., `base_pkgs_system`,
   `productivity_pkgs_aur`). Add the package to the list alphabetically.
3. If no matching list exists, create a new variable with the naming convention
   `<concern>_pkgs` (pacman) or `<concern>_pkgs_aur` (AUR). Add a comment
   above it with the consuming task file path relative to the repo root.
4. In the task file, reference the variable as
   `distro_packages.<variable_name>`.
5. If the task file does not already have a top-level `include_vars` task,
   add one **before** any blocks, with tags set to the union of all block
   tags in the file.
6. Every `community.general.pacman` and `kewlfft.aur.aur` task **must** have
   `when: ansible_facts['distribution'] == "Archlinux"`.

**Migrating hardcoded packages:** If a task file lists packages inline instead
of referencing a variable (e.g., `name: [google-chrome, firefox]`), move the
list to `vars/Archlinux.yml` under a new variable, add the `include_vars`
task at the top of the file if missing, and replace the inline list with the
variable reference.

**Validation:** Run `make ansible-system-check` after changes.
