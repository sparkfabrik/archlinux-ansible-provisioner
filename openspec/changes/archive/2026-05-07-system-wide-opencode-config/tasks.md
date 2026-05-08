## 1. Update opencode config deployment in ai.yml

- [x] 1.1 Add task to create `/etc/opencode/` directory owned by `root:root` with mode `0755`
- [x] 1.2 Change the copy task destination from `~/.config/opencode/opencode.json` to `/etc/opencode/opencode.json` with user ownership and mode `0644`
- [x] 1.3 Add `ansible.builtin.debug` task after the user-local directory creation informing users they can create `~/.config/opencode/opencode.json` for personal overrides

## 2. User-local config cleanup

- [x] 2.1 Add `stat` task to check if `~/.config/opencode/opencode.json` exists
- [x] 2.2 Add `command` task using `diff -q` to compare user-local file with sparkdock source (when file exists)
- [x] 2.3 Add `file: state=absent` task to delete user-local file when identical (diff rc == 0)
- [x] 2.4 Add `debug` task to warn user when files differ (diff rc != 0) that the file should contain only customizations

## 3. Changelog

- [x] 3.1 Add entry to CHANGELOG.md under `## [Unreleased]`
