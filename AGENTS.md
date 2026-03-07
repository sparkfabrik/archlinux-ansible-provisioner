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

make local-install-apps                          # Packages only
make regenerate-mkinitcpio-grub                  # Regenerate mkinitcpio + grub
make generate-json-schema-docs                   # Schema docs (Docker required)
make install-githooks                            # Install git hooks
```

## Repository Structure

```
playbooks/
  bootstrap.yml          # Pacstrap + base system config
  system.yml             # Main playbook: pre_tasks + all roles
  roles/
    amd/                 # AMD GPU drivers
    bootstrap/           # Base system (pacstrap, locales, user)
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
- Use backticks for technical terms: `` "Create the `aur_builder` user" ``.

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
