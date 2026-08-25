# AGENTS.md - Omarchy bar widget

Maintenance guide for the SparkFabrik Omarchy bar widget (`sparkfabrik.toolbox`) and its status backend. Read this before touching anything in this directory. The repo-level `AGENTS.md` rules (YAML style, shellcheck, CHANGELOG) apply on top.

## What this is

The Linux counterpart of the macOS sparkdock menu bar (`src/menubar-app` in the sparkdock repo). A native omarchy-shell bar-widget shows the freshness of the Spark dev stack and offers one-click upgrade actions. The design rule is inherited from macOS: **the UI owns no logic**. It renders JSON from `sf-toolbox-status` and shells out for actions.

| File                          | Role                                                             |
| ----------------------------- | ---------------------------------------------------------------- |
| `sf-toolbox-status`           | Status backend, installed to `/usr/local/bin`                    |
| `plugin/manifest.json`        | omarchy-shell plugin manifest (`kinds: ["bar-widget"]`)          |
| `plugin/Toolbox.qml`          | The widget: bar icon plus popup                                  |
| `plugin/menu.json`            | Declarative Tools/Company entries (same schema as macOS)         |
| `plugin/sparkfabrik-logo.png` | Bar and hero icon (180x180 source)                               |
| `sparkfabrik-toolbox.hook`    | Pacman post-transaction hook, installed to `/etc/pacman.d/hooks` |

The Ansible side lives in `../../tasks/omarchy-bar.yml` (install, tag `omarchy-bar`, gated on `/usr/share/omarchy`) and `../../tasks/omarchy-detect.yml` (ownership facts, tag `always`).

## The status contract

`sf-toolbox-status <subsystem>` uses the same exit codes as sparkdock's `sparkdock-check-updates` on macOS. Keep them stable, the widget and any future consumer depend on them:

- **0**: updates available
- **1**: up to date
- **2**: usage or check error
- **3**: not configured (subsystem not installed yet)

Subsystems: `toolbox`, `sparkdock`, `agents`, `packages`, `http-proxy`. `--json` aggregates those plus `docker` and `auth` (gcloud, glab, gh) in one process, which is what the widget calls. `--offline` skips `git fetch` and is used for the periodic timer refresh; the popup-open refresh does a full fetch.

Env overrides for tests and non-standard layouts: `SF_TOOLBOX_DIR`, `SF_SPARKDOCK_DIR`, `SF_HTTP_PROXY_DIR`, `SF_AGENTS_DIR`, `SF_STATUS_FETCH_TIMEOUT`.

Two traps already hit once, do not reintroduce them:

- **glab exit code lies.** `glab auth status` exits non-zero when ANY configured host has a stale token, even with a valid company login. Capture the output and grep for `Logged in to`. Capture before grepping: under `set -o pipefail` a failing command poisons the pipeline even when `grep -q` matches.
- **`checkupdates` exit codes.** 2 means "no updates" (not an error), 1 means error. Do not treat them alike.

## QML: how to work on the widget

The widget follows the structure of the built-in panels (`/usr/share/omarchy/shell/plugins/panels/power/Panel.qml` is the reference): `Panel` root, `BarIconButton` for the bar slot, `KeyboardPanel > PanelKeyCatcher > Column` for the popup. Use only these base components plus `PanelSectionHeader` and `PanelSeparator`: they are the smallest surface of omarchy-shell's unversioned internal API (`qs.Ui`, `qs.Commons`).

Hard-won layout rules:

- **The root `Panel` must set `implicitWidth`/`implicitHeight` from the button.** Without them the bar gives the widget a zero-width slot and the icon is invisible. This was the first shipping bug.
- **Never use an `Image`'s `implicitHeight` in layout math.** It is the source PNG's natural size (180px here), not the rendered size. Use `height`. This was the second shipping bug (a giant hero row).
- **Nerd Font glyphs fail silently.** An invalid codepoint renders as nothing, which looks like a missing widget. Verify any new glyph against a built-in panel before using it.

Runtime facts:

- Actions run in a visible terminal via `xdg-terminal-exec bash -lc '<cmd>; ...'` through `Quickshell.execDetached`. Each launched command appends `omarchy-shell -q sparkfabrik.toolbox refresh`, so the dots update the moment an action finishes (the Linux equivalent of the macOS `notifyutil` mechanism). The widget owns its `IpcHandler` (`manageIpc: false` on the Panel base) to expose that `refresh` method.
- Refresh points: shell start, popup open (full fetch), a 30-minute offline timer, the manual Refresh button, a click on any status row (cheap offline pass), the post-action IPC ping, and the pacman stamp file (`/var/lib/sparkfabrik-toolbox/pacman-stamp`, touched by the root-side hook and watched with `FileView watchChanges`; a file watch avoids any cross-user IPC).
- The Tools and Company entries come from `plugin/menu.json`, same schema as the macOS `Resources/menu.json` (`type: command|url`, optional `requires_binary` hides entries for absent tools; availability is resolved with one batched `command -v` pass).
- The attention badge and the urgent hero color come from `hasAttention` in `Toolbox.qml`; auth states deliberately do not raise attention.

## Local test loop

Work on the files here, then sync and reload:

```bash
cp plugin/* ~/.config/omarchy/plugins/sparkfabrik.toolbox/
omarchy-restart-shell
```

- **Never run `omarchy-refresh-shell`.** It resets the user's `shell.json` to defaults and silently drops the widget from the bar. `omarchy-restart-shell` is the correct reload.
- **Lint before loading**: `qmllint -I "$OMARCHY_PATH/shell" plugin/Toolbox.qml` catches QML mistakes statically. Runtime errors land in the newest quickshell log: `ls -t /run/user/1000/quickshell/by-id/*/log.qslog | head -1`, grep for `cannot`, `is not a type`, `ReferenceError`, `TypeError`.
- The warning `IpcHandler ... will not be used because another handler is registered` appears for every panel on restart and is harmless.
- First install of a new plugin id needs `omarchy-shell shell rescanPlugins` before `omarchy-plugin-enable <id> --section right`.
- IPC smoke test: `omarchy-shell -q sparkfabrik.toolbox open|close|toggle|refresh`.
- Full lifecycle checklist (from the Omarchy develop guide): click, Escape, `omarchy-shell shell summon/hide`, disable and re-enable, shell restart, removal.
- Test the full Ansible path with: `sudo ansible-playbook playbooks/sf-toolbox.yml -i localhost, -c local --tags omarchy-bar`, twice (the second run must be idempotent).

Shell script changes must pass `shellcheck` (`docker run --rm -v "$(pwd):/src" koalaman/shellcheck:stable /src/sf-toolbox-status`).

## Package ownership: the delegation rule

Omarchy manages several dev tools itself through mise wrappers in `~/.local/bin` (generated by `omarchy-mise-install`, tool list in `/usr/share/omarchy/install/user/mise.sh`) and regenerates them on every `omarchy update`. Competing installs get reverted by its migrations, so the rule is: **one tool, one owner; on Omarchy the owner of an Omarchy-managed tool is Omarchy**.

`../../tasks/omarchy-detect.yml` inventories the wrappers at runtime (`grep -l 'mise use -g' ~/.local/bin/*`) into `omarchy_mise_tools`, and derived facts exclude the shadowed packages (`github-cli`, `opencode` from pacman, `@github/copilot` from npm) and skip the Claude Code installer. When extending sf-toolbox with a new tool, check whether Omarchy's `mise.sh` already lists it and add the guard.

Boundaries that must hold:

- Never remove or reinstall a tool Omarchy manages.
- Never write `~/.local/state/omarchy/preinstalls-removed`. Opting out of Omarchy's preinstalls is the user's decision, not the provisioner's.
- `is_sf_managed()` in `bin/install.linux` must keep classifying mise-wrapper files as not sf-managed, or the pre-install conflict report lies.

## When Omarchy updates break the widget

The widget depends on omarchy-shell internals that carry no compatibility promise. If it disappears or errors after an Omarchy update, check in order:

1. The quickshell log for QML errors (component renamed or property removed).
2. That `~/.config/omarchy/shell.json` still lists `sparkfabrik.toolbox` (a shell.json reset drops it; re-run the `omarchy-bar` tag).
3. That the base components still exist: `ls /usr/share/omarchy/shell/Ui/` should list `Panel.qml`, `BarIconButton.qml`, `KeyboardPanel.qml`, `PanelKeyCatcher.qml`, `PanelSectionHeader.qml`, `PanelSeparator.qml`.
