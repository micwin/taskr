---
title: Initialize project site
status: done
created_at: 2026-08-10T18:15:00Z
updated_at: 2026-08-12T08:19:47Z
designing_at: 2026-08-10T18:15:00Z
developing_at: 2026-08-10T19:38:59Z
reviewing_at: 2026-08-10T19:43:35Z
done_at: 2026-08-12T08:19:47Z
---

# Description

Add `taskr site init <site-directory>`. The command associates one persistent
site output directory with the selected Taskr root so later `site generate` and
`site open` calls do not require a target argument.

The setting belongs to the managed project rather than a user's personal
editor or shell configuration. It is stored in the `[site]` table of the
root-local `taskr.toml` defined by task `086` and must not duplicate item
roles, hierarchy, or other data already derived from marker files and
directories.

# Acceptance

- `taskr site init <site-directory>` resolves and validates the selected Taskr
  root and requested output path.
- Without `--create-if-missing`, the site directory must already exist.
  `--create-if-missing` creates a missing directory and required parents.
- Site initialization persists enough project-local configuration for
  argument-free `taskr site generate` and `taskr site open` calls.
- Site configuration is stored in `<taskr-root>/taskr.toml` under `[site]`;
  personal XDG configuration is not the canonical source for a shared
  project's site directory.
- Relative and absolute site-directory arguments have defined resolution and
  portability behavior. Relative arguments are stored as given after lexical
  cleaning and resolve from the Taskr root; absolute arguments remain absolute.
- The target must be a writable directory. Regular files, symlinks, and paths
  that are equal to, contain, or are contained by the Taskr root are rejected
  in the initial implementation.
- An empty target is claimed by writing a versioned `.taskr-site` ownership
  marker. A nonempty target without a valid ownership marker is rejected.
- Missing targets are created only after all source/config/path preflight checks
  pass. Failed initialization does not leave a partial config or ownership
  marker.
- Repeating initialization with the same effective configuration is
  idempotent. A different configured directory is not changed by `site init`;
  users may edit `taskr.toml` directly until task `088` provides a general
  configuration command.
- Initialization records or creates only site ownership/configuration data and
  does not duplicate the Taskr item hierarchy.
- Successful output reports the resolved root and site directory plus stable
  `created` and `changed` booleans; an idempotent repeat reports
  `changed=false`.
- Doctor validates site configuration and reports invalid or unsafe output
  associations.
- Smokey covers initial setup, idempotency, reconfiguration protection, path
  resolution, invalid targets, and later consumption by `site generate` and
  `site open`.
- Help, examples, completion, documentation, Doctor behavior, and public API
  behavior are updated for the final command surface.

# Comments

- 2026-08-10: Added after deciding that generation and preview should share one
  persistent site directory rather than requiring a target argument for every
  call or using a temporary directory for normal preview.
- 2026-08-10: Selected root-local `taskr.toml` with a `[site]` table instead of
  a hidden site-specific YAML file. Task `086` defines the reusable project
  configuration contract; personal XDG config would make CI and collaborator
  behavior diverge.
- 2026-08-10: `site init` does not gain a reconfiguration flag. General
  project configuration changes belong to later task `088`.
- 2026-08-10: Initial path handling is deliberately conservative. Site output
  must not overlap the Taskr source root, and only empty or already Taskr-owned
  directories can be initialized. `--create-if-missing` is the sole creation
  convenience flag.
- 2026-08-10: Implemented the command with transactional marker/config writes,
  Doctor validation, help, completion, examples, and user documentation. The
  final Smokey run passes all 25 suites; Go tests and `go vet` also pass.

# Outcome

`taskr site init <site-directory>` now stores a validated project-local site
association in `taskr.toml` and claims the output with a versioned
`.taskr-site` marker. It supports explicit creation through
`--create-if-missing`, rejects unsafe or foreign targets, rolls back failed
initialization, and is idempotent for an unchanged association.
