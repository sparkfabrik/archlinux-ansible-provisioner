## 1. Ansible Role Files

- [ ] 1.1 Create `playbooks/roles/sparkdock/files/ajust/ajust.sh` wrapper script
- [ ] 1.2 Create `playbooks/roles/sparkdock/files/ajust/justfile` with Linux sparkdock_path, sparkdock-fetch-updates recipe, and optional imports

## 2. Ansible Tasks

- [ ] 2.1 Add ajust setup block to `playbooks/roles/sparkdock/tasks/main.yml`: install `just` via pacman
- [ ] 2.2 Add task: ensure `~/.local/share/ajust` directory exists (owned by system.username)
- [ ] 2.3 Add task: copy justfile to `~/.local/share/ajust/justfile`
- [ ] 2.4 Add task: copy `ajust.sh` to `/usr/local/bin/ajust` with mode 0755
