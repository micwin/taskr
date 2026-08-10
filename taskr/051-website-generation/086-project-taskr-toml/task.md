---
title: Define project taskr.toml configuration
status: designing
created_at: 2026-08-10T18:19:10Z
updated_at: 2026-08-10T18:19:11Z
designing_at: 2026-08-10T18:19:11Z
---

# Description

Introduce optional project-local configuration in `taskr.toml` at the Taskr
root. The file provides extensible, namespaced settings for Taskr features; the
initial consumer is the `[site]` section used by `taskr site init`, `generate`,
and `open`.

`taskr.toml` supplements the marker-based worktree. It must never duplicate or
override item roles, IDs, hierarchy, status, priority, or other information
derived from marker files and directory structure.

# Acceptance

- The canonical project configuration path is `<taskr-root>/taskr.toml`.
- The configuration language is TOML and the parser provides actionable file,
  key, and syntax errors.
- The schema is extensible through named tables; `[site]` is the first defined
  table and unrelated future tables do not require another project config file.
- The initial shape supports at least:

  ```toml
  [site]
  directory = "../site"
  ```

- Relative paths are resolved against the Taskr root rather than the caller's
  current working directory.
- `taskr.toml` does not make a directory a valid Taskr root by itself and does
  not replace marker-based root discovery or hierarchy validation.
- Item roles, IDs, parent relationships, status, priority, and duplicated
  marker metadata are rejected as project configuration concepts.
- Site initialization can add `[site]` without deleting unrelated supported
  tables, keys, or comments. General updates are deferred to task `088`.
- The design defines precedence between project `taskr.toml`, personal XDG
  configuration, explicit `--config-file`, environment variables, and command
  flags for settings that may exist at more than one scope.
- Project configuration must not contain secrets; documentation points to
  Vaultline or environment-based runtime retrieval for secret values.
- Doctor validates the file, schema, path safety, and known values while still
  providing actionable diagnostics when configuration is malformed.
- Smokey covers missing configuration, valid site configuration, syntax
  errors, unknown or misplaced keys, path resolution, preservation of unrelated
  settings, and precedence behavior.
- Help, documentation, examples, completion impact, and public API exposure are
  reviewed before implementation is closed.

# Comments

- 2026-08-10: A root-local `taskr.toml` was chosen over a hidden
  `.taskr-site.yaml`. The Taskr root already supplies scope, TOML tables support
  future features, and one project configuration avoids feature-specific files.
- 2026-08-10: This does not reverse the marker-only hierarchy decision from
  ticket `002`; project configuration may tune features but cannot describe the
  worktree structure.

# Outcome
