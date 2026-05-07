## Why

The opencode base configuration (`opencode.json`) is currently deployed to
the user's home directory (`~/.config/opencode/opencode.json`). This prevents
users from layering their own customizations on top of the shipped defaults,
since the same path would be overwritten on every provisioning run. Moving the
base config to `/etc/opencode/` establishes a clear system-wide vs. user-local
split, letting users maintain personal overrides that are merged with the
shipped configuration.

## What Changes

- Create `/etc/opencode/` directory owned by `root:root` with mode `0755`.
- Copy the base `opencode.json` to `/etc/opencode/opencode.json` (owned by
  `root:root`, mode `0644`) instead of `~/.config/opencode/opencode.json`.
- Keep the `~/.config/opencode/` directory creation (user-owned) so users have
  a ready location for their personal configuration.
- Add a debug message informing the user they can place a custom
  `~/.config/opencode/opencode.json` that will be merged with the system-wide
  configuration.

## Capabilities

### New Capabilities

- `system-opencode-config`: Ship the opencode base configuration to
  `/etc/opencode/opencode.json` as a system-wide default, keeping user-local
  `~/.config/opencode/` for personal customizations.

### Modified Capabilities

_(none)_

## Impact

- **Affected file**: `playbooks/roles/sf-toolbox/tasks/ai.yml` (lines 51-65).
- No new dependencies or schema changes required — the config source path
  remains the same, only the destination changes.
- Existing user-local `~/.config/opencode/opencode.json` files will no longer
  be overwritten by provisioning, which is the desired outcome.
