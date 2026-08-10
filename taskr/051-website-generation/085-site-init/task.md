---
title: Initialize project site
status: designing
created_at: 2026-08-10T18:15:00Z
updated_at: 2026-08-10T18:15:00Z
designing_at: 2026-08-10T18:15:00Z
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
- Site initialization persists enough project-local configuration for
  argument-free `taskr site generate` and `taskr site open` calls.
- Site configuration is stored in `<taskr-root>/taskr.toml` under `[site]`;
  personal XDG configuration is not the canonical source for a shared
  project's site directory.
- Relative and absolute site-directory arguments have defined resolution and
  portability behavior.
- Initialization defines how a missing, empty, nonempty, already initialized,
  moved, unwritable, or Taskr-root-overlapping site directory is handled.
- Repeating initialization with the same effective configuration is
  idempotent. A different configured directory is not changed by `site init`;
  users may edit `taskr.toml` directly until task `088` provides a general
  configuration command.
- Initialization records or creates only site ownership/configuration data and
  does not duplicate the Taskr item hierarchy.
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

# Outcome
