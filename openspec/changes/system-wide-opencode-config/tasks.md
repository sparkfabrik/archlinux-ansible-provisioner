## 1. Update opencode config deployment in ai.yml

- [ ] 1.1 Add task to create `/etc/opencode/` directory owned by `root:root` with mode `0755`
- [ ] 1.2 Change the copy task destination from `~/.config/opencode/opencode.json` to `/etc/opencode/opencode.json` with owner `root:root` and mode `0644`
- [ ] 1.3 Add `ansible.builtin.debug` task after the user-local directory creation informing users they can create `~/.config/opencode/opencode.json` for personal overrides

## 2. Changelog

- [ ] 2.1 Add entry to CHANGELOG.md under `## [Unreleased]`
