## ADDED Requirements

### Requirement: System-wide opencode configuration directory

The provisioner SHALL create the `/etc/opencode/` directory owned by `root:root`
with mode `0755` before copying the configuration file.

#### Scenario: Directory does not exist

- **WHEN** the provisioner runs and `/etc/opencode/` does not exist
- **THEN** the directory is created with owner `root`, group `root`, and mode `0755`

#### Scenario: Directory already exists

- **WHEN** the provisioner runs and `/etc/opencode/` already exists
- **THEN** the directory ownership and permissions are enforced to `root:root` and `0755`

### Requirement: Deploy base opencode configuration to system-wide path

The provisioner SHALL copy the base `opencode.json` from the sparkdock config
path to `/etc/opencode/opencode.json` with owner and group set to the
provisioned user and mode `0644`.

#### Scenario: Configuration file is copied

- **WHEN** the provisioner runs the copy task
- **THEN** `/etc/opencode/opencode.json` exists with the provisioned user as owner and group, and mode `0644`

### Requirement: User-local opencode directory is preserved

The provisioner SHALL continue to create `~/.config/opencode/` owned by the
provisioned user so it is available for personal configuration overrides.

#### Scenario: User directory is created

- **WHEN** the provisioner runs
- **THEN** `~/.config/opencode/` exists with the provisioned user as owner and group, mode `0755`

### Requirement: Debug message about user customization

The provisioner SHALL display a debug message informing the user that they can
create `~/.config/opencode/opencode.json` as a personal customization file
that will be merged with the system-wide configuration.

#### Scenario: Debug message is displayed

- **WHEN** the provisioner finishes configuring opencode
- **THEN** a debug message is shown indicating that `~/.config/opencode/opencode.json` can be used for personal overrides merged with `/etc/opencode/opencode.json`

### Requirement: Clean up duplicate user-local configuration

The provisioner SHALL check whether `~/.config/opencode/opencode.json` exists.
If it does, the provisioner SHALL compare it with the sparkdock source
configuration file. If the files are identical, the user-local file SHALL be
deleted. If the files differ, the provisioner SHALL display a warning message
informing the user that the file should contain only personal customizations
and that any configuration already present in the system-wide file can be
removed.

#### Scenario: User-local file does not exist

- **WHEN** the provisioner runs and `~/.config/opencode/opencode.json` does not exist
- **THEN** no cleanup action is taken

#### Scenario: User-local file is identical to the source

- **WHEN** `~/.config/opencode/opencode.json` exists and is identical to the sparkdock source configuration
- **THEN** the user-local file is deleted

#### Scenario: User-local file differs from the source

- **WHEN** `~/.config/opencode/opencode.json` exists and differs from the sparkdock source configuration
- **THEN** a warning message is displayed informing the user that the file should contain only personal customizations and that configurations already present in the system-wide file can be removed
