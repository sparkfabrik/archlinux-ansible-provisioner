## Why

The provisioner already clones sparkdock to `~/.local/spark/sparkdock`, but its task-runner (`sjust`) is macOS-only (hardcoded paths, Homebrew install). Linux users have no equivalent command to refresh AI agent skills or run sparkdock maintenance recipes. `ajust` brings the same `just`-based UX to Linux with zero changes to sparkdock itself.

## What Changes

- New `ajust` command installed at `/usr/local/bin/ajust` (thin bash wrapper around `just`)
- New justfile at `~/.local/share/ajust/justfile` defining Linux-specific variables and importing portable sparkdock recipes
- `just` package installed via pacman when `sparkfabrik: true`
- Sparkdock Ansible role extended with a new `ajust` setup block

## Capabilities

### New Capabilities

- `ajust`: The `ajust` command — wrapper script, justfile, and Ansible provisioning that installs and wires everything together

### Modified Capabilities

- `sparkdock-role`: The sparkdock Ansible role gains a new task block for ajust setup (new functionality, no requirement changes to existing behavior)

## Impact

- `playbooks/roles/sparkdock/tasks/main.yml` — new task block appended
- `playbooks/roles/sparkdock/files/ajust/ajust.sh` — new file
- `playbooks/roles/sparkdock/files/ajust/justfile` — new file
- Runtime dependency: `just` (available in Arch repos)
- Only applies when `sparkfabrik: true` in config — no impact on non-sparkfabrik setups
