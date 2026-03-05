## ADDED Requirements

### Requirement: ajust command is available after provisioning
When a system is provisioned with `sparkfabrik: true`, the `ajust` command SHALL be available on PATH at `/usr/local/bin/ajust`.

#### Scenario: ajust is executable after provisioning
- **WHEN** the provisioner runs with `sparkfabrik: true`
- **THEN** `/usr/local/bin/ajust` exists and is executable

#### Scenario: ajust is not installed without sparkfabrik flag
- **WHEN** the provisioner runs with `sparkfabrik: false` or unset
- **THEN** `/usr/local/bin/ajust` SHALL NOT be created

### Requirement: just package is installed as a dependency
The `just` task runner SHALL be installed via pacman when `sparkfabrik: true`.

#### Scenario: just is available after provisioning
- **WHEN** the provisioner runs with `sparkfabrik: true`
- **THEN** `just` is installed and available in PATH

### Requirement: ajust justfile is deployed to the user home
The ajust justfile SHALL be deployed to `~/.local/share/ajust/justfile` owned by the provisioned user.

#### Scenario: justfile exists with correct ownership
- **WHEN** the provisioner runs with `sparkfabrik: true`
- **THEN** `~/.local/share/ajust/justfile` exists, is owned by `system.username`, and is readable

### Requirement: ajust lists available commands by default
Running `ajust` with no arguments SHALL display a list of available commands.

#### Scenario: default target shows command list
- **WHEN** user runs `ajust` with no arguments
- **THEN** a list of available commands is printed

### Requirement: ajust exposes sparkdock skills recipes
The `sf-skills-refresh` and `sf-skills-status` recipes from sparkdock's `05-skills.just` SHALL be available via `ajust` once sparkdock is cloned.

#### Scenario: skills refresh is available
- **WHEN** sparkdock is cloned at `~/.local/spark/sparkdock`
- **THEN** `ajust sf-skills-refresh` runs `sparkdock-skills-sync`

#### Scenario: skills status is available
- **WHEN** sparkdock is cloned at `~/.local/spark/sparkdock`
- **THEN** `ajust sf-skills-status` runs `sparkdock-skills-status`

#### Scenario: ajust works gracefully without sparkdock clone
- **WHEN** sparkdock is not yet cloned
- **THEN** `ajust` still starts and lists available commands (skills recipes simply absent)

### Requirement: ajust exposes sparkdock-fetch-updates recipe
Running `ajust sparkdock-fetch-updates` SHALL pull the latest sparkdock from the `master` branch.

#### Scenario: successful update when behind upstream
- **WHEN** user runs `ajust sparkdock-fetch-updates` and the local clone is behind `origin/master`
- **THEN** the clone is fast-forwarded to `origin/master` and a success message is printed

#### Scenario: no-op when already up to date
- **WHEN** user runs `ajust sparkdock-fetch-updates` and the local clone is current
- **THEN** "Already up to date." is printed and nothing is changed

#### Scenario: error when not on master branch
- **WHEN** user runs `ajust sparkdock-fetch-updates` and the local clone is on a non-master branch
- **THEN** an error message is printed and the command exits non-zero

### Requirement: ajust supports user customization
Users SHALL be able to add their own recipes to `~/.config/ajust/100-custom.just` and have them available via `ajust`.

#### Scenario: custom recipes are loaded when file exists
- **WHEN** `~/.config/ajust/100-custom.just` exists with valid just recipes
- **THEN** those recipes appear in `ajust --list`

#### Scenario: ajust works normally when no custom file exists
- **WHEN** `~/.config/ajust/100-custom.just` does not exist
- **THEN** `ajust` works without error
