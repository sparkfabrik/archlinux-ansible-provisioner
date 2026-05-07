## Context

The `sf-toolbox` role's `ai.yml` currently deploys the base `opencode.json`
into the user's home directory at `~/.config/opencode/opencode.json`. Because
opencode merges system-wide (`/etc/opencode/opencode.json`) and user-local
(`~/.config/opencode/opencode.json`) configuration, placing the shipped
defaults under `/etc/opencode/` frees the user-local path for personal
overrides that survive re-provisioning.

All tasks in `ai.yml` run inside a single `block:` under the
`Configure AI tools` play. The playbook is executed with `sudo`, so writing to
`/etc/` requires no additional `become:` directive; writing user-owned paths
still uses the existing owner/group variables.

## Goals / Non-Goals

**Goals:**

- Deploy the base opencode configuration to `/etc/opencode/opencode.json`
  owned by `root:root`.
- Keep `~/.config/opencode/` as a user-owned directory for personal
  configuration overrides.
- Inform the user (via `ansible.builtin.debug`) that they can create
  `~/.config/opencode/opencode.json` for custom settings.
- Automatically clean up a user-local `~/.config/opencode/opencode.json` that
  is identical to the shipped source, and warn the user if the file contains
  non-custom content.

**Non-Goals:**

- Modifying the opencode configuration content itself.
- Implementing any config-merge logic (opencode already handles this).
- Managing additional files under `/etc/opencode/`.

## Decisions

### 1. Destination path: `/etc/opencode/opencode.json`

OpenCode natively reads `/etc/opencode/opencode.json` as the system-wide
config. Placing the shipped defaults there follows the tool's own convention
and requires no extra flags or symlinks.

**Alternative considered:** Symlinking `~/.config/opencode/opencode.json` to
`/etc/opencode/opencode.json` — rejected because it would still occupy the
user-local path and prevent personal overrides.

### 2. Ownership for `/etc/opencode/` and its contents

The `/etc/opencode/` directory is owned by `root:root` to prevent unprivileged
users from adding or removing files. The `opencode.json` file inside it is
owned by the provisioned user so they can edit the system-wide configuration
directly without requiring elevated privileges.

### 3. Debug message instead of a template or README

A one-line `ansible.builtin.debug` message at provision time is the lightest
way to inform users without creating additional files they might need to
maintain. It keeps the role self-contained.

### 4. User-local config cleanup via `diff -q`

Use `ansible.builtin.stat` to check if `~/.config/opencode/opencode.json`
exists, then `ansible.builtin.command: diff -q` to compare it against the
sparkdock source file. This avoids reading file contents into Ansible variables
and delegates comparison to the OS. The task uses
`failed_when: opencode_config_diff.rc > 1` so that `diff` errors (rc=2, e.g.
missing source file or permission issues) fail the play instead of being
silently treated as "files differ". Downstream tasks guard against the diff
task being skipped with `opencode_config_diff is not skipped`. Based on the
exit code:

- `rc == 0` (identical): delete the user-local file with
  `ansible.builtin.file: state=absent`.
- `rc != 0` (different): display a warning via `ansible.builtin.debug`
  advising the user to keep only personal customizations.

**Alternative considered:** Using `ansible.builtin.slurp` to read both files
and compare checksums in Jinja2 — rejected as unnecessarily complex when
`diff -q` is simpler and already available on all target systems.

## Risks / Trade-offs

- **[Existing user-local file]** → Users who previously relied on the
  provisioner writing `~/.config/opencode/opencode.json` will no longer get
  that file. Mitigation: the debug message tells them where the system config
  now lives and how to add personal overrides.
