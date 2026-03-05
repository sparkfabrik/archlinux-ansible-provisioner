## Context

The provisioner clones sparkdock to `~/.local/spark/sparkdock` (PR #165). On macOS, sparkdock ships `sjust` — a `just`-based task runner at `/usr/local/bin/sjust` pointing to `/opt/sparkdock/sjust/Justfile`. That justfile sets `sparkdock_path := "/opt/sparkdock"` and imports platform-specific recipes. The skills recipes (`05-skills.just`) call `sparkdock-skills-sync` and `sparkdock-skills-status` via `{{sparkdock_path}}/bin/...` — those scripts are pure bash and Linux-compatible already.

The only thing blocking Linux is: the wrong `sparkdock_path` and a Homebrew-based installer.

## Goals / Non-Goals

**Goals:**
- Install `ajust` at `/usr/local/bin/ajust` for users with `sparkfabrik: true`
- Provide `sf-skills-refresh` and `sf-skills-status` recipes on Linux by importing `05-skills.just`
- Provide `sparkdock-fetch-updates` recipe to git-pull the sparkdock clone
- Install `just` via pacman automatically
- Allow user customization via `~/.config/ajust/100-custom.just`

**Non-Goals:**
- Porting macOS-specific recipes (Lima, Docker Desktop, Homebrew, Ghostty)
- Replacing the Makefile — ajust is additive, not a Makefile migration
- Implementing any new skills — skills themselves live in sparkdock/sf-awesome-copilot

## Decisions

### D1: justfile stored in `~/.local/share/ajust/justfile`, not inside sparkdock

**Decision:** Deploy our own justfile to `~/.local/share/ajust/justfile`; do not use `~/.local/spark/sparkdock/sjust/Justfile` directly.

**Rationale:** Sparkdock's justfile hardcodes `sparkdock_path := "/opt/sparkdock"` and imports macOS-only recipes. Overriding those requires importing `00-default.just` and patching. Instead, we own our justfile that defines the correct Linux path and selectively imports only portable recipes. Zero changes to sparkdock needed, and updates to sparkdock's justfile don't break us.

**Alternative considered:** Patch sparkdock's justfile with `set allow-duplicate-variables`. Rejected: fragile, fights upstream.

### D2: Override `sparkdock_path` via just variable scoping

**Decision:** Define `sparkdock_path := env_var('HOME') + "/.local/spark/sparkdock"` in our justfile. The imported `05-skills.just` references `{{sparkdock_path}}` but never defines it — it relies on the outer justfile to provide it. Our definition satisfies that reference.

**Rationale:** `just` merges all variables into a single global namespace. Variables defined in the importing justfile are visible in imported files. No patching needed.

### D3: `import?` (optional) for sparkdock recipes

**Decision:** Use `import?` (not `import`) for `05-skills.just`.

**Rationale:** `import?` silently skips missing files. If sparkdock hasn't been cloned yet (e.g., running ajust before the sparkdock role completes), `ajust` degrades gracefully instead of crashing.

### D4: `/usr/local/bin/ajust` as install path

**Decision:** Install wrapper at `/usr/local/bin/ajust`, matching the Mac `sjust` at `/usr/local/bin/sjust` and the pattern used in the `sparkfabrik` role.

**Alternative considered:** `~/.local/bin/ajust`. Rejected: requires PATH setup verification; `/usr/local/bin` is universally on PATH.

### D5: `just` installed inside the sparkdock role, not packages

**Decision:** Install `just` inside the new ajust block within the `sparkdock` role, guarded by `when: sparkfabrik`.

**Rationale:** `just` is only needed for ajust, which is a sparkfabrik-specific feature. Installing it unconditionally in the packages role would affect all users.

## Risks / Trade-offs

- **`sparkdock_path` coupling** → If sparkdock ever changes the variable name used in `05-skills.just`, we'd need to update our justfile. Low probability; mitigated by `import?` (ajust still works, just without skill recipes).
- **`~/.local/share/ajust/justfile` is managed** → Users who hand-edit it will lose changes on next `make local-install`. Mitigation: document this; user customizations go in `~/.config/ajust/100-custom.just`.
- **`just` package name on Arch** → Package is `just` in the official Arch repos. No AUR needed.

## Migration Plan

No migration required — this is entirely additive. Existing provisioned systems can re-run with `--tags ajust` after the change is merged.

Rollback: remove `/usr/local/bin/ajust` and `~/.local/share/ajust/`.
