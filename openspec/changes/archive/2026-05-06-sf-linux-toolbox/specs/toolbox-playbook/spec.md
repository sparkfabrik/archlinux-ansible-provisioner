## ADDED Requirements

### Requirement: Direct task imports

The playbook SHALL import task files directly from role directories using `import_tasks:` instead of importing full roles via the `roles:` directive. Only the company-tooling task files SHALL be imported.

#### Scenario: Playbook structure
- **WHEN** `playbooks/toolbox.yml` is parsed by Ansible
- **THEN** it imports only: `homebrew.yml`, `sparkdock/tasks/main.yml`, `ai.yml`, `glab.yml`, `gcloud.yml`, `sparkfabrik-http-proxy.yml`

### Requirement: User auto-detection

The playbook SHALL auto-detect the current user and home directory in `pre_tasks` using `ansible_facts['env']['SUDO_USER']` with fallback to `ansible_facts['user_id']`.

#### Scenario: Run via sudo
- **WHEN** the playbook is invoked with `sudo ansible-playbook`
- **THEN** `current_user` resolves to the original user (from SUDO_USER) and `current_home` to their home directory

### Requirement: Self-contained variables

The playbook SHALL define all required variables inline (`vars:` block) without requiring an external config file. Variables SHALL include `sparkdock_default_path` and `sparkfabrik: true`.

#### Scenario: Run without extra-vars
- **WHEN** `ansible-playbook toolbox.yml` is run without `--extra-vars`
- **THEN** all tasks have access to `sparkdock_default_path` (resolving to `~/.local/spark/sparkdock`) and `sparkfabrik` (true)

### Requirement: Package config loading

The playbook SHALL load `config/toolbox-packages.yml` via `include_vars` into a namespaced variable `toolbox`, making package lists available to tasks.

#### Scenario: Variable access
- **WHEN** tasks reference `toolbox.homebrew_packages` or `toolbox.prerequisites`
- **THEN** the values from `config/toolbox-packages.yml` are returned

### Requirement: Cross-platform execution

The playbook SHALL execute successfully on both Arch Linux and Debian/Ubuntu. Tasks with OS-specific logic SHALL use `when: ansible_os_family` guards or import OS-specific sub-files.

#### Scenario: Run on Arch
- **WHEN** `ansible_os_family == "Archlinux"`
- **THEN** pacman-based tasks execute, brew-based tasks are skipped

#### Scenario: Run on Ubuntu
- **WHEN** `ansible_os_family == "Debian"`
- **THEN** brew-based tasks execute, pacman-based tasks are skipped

### Requirement: Tag support

All imported task blocks SHALL have tags applied so that `--tags` filtering works for selective execution.

#### Scenario: Run only sparkdock tasks
- **WHEN** the playbook is invoked with `--tags sparkdock`
- **THEN** only sparkdock-related tasks execute

#### Scenario: Run only AI tools
- **WHEN** the playbook is invoked with `--tags ai`
- **THEN** only AI tool installation tasks execute
