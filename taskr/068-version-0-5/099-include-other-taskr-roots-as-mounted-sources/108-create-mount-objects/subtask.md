---
title: Create mount objects
status: reviewing
created_at: 2026-08-25T17:20:17Z
updated_at: 2026-08-25T20:15:41Z
designing_at: 2026-08-25T17:20:17Z
developing_at: 2026-08-25T17:49:17Z
reviewing_at: 2026-08-25T20:15:41Z
---

# Description

Implement `taskr create mount` for virtual root-level mount objects stored in
`taskr.toml`.

The command creates no marker directory. It resolves the supplied path to the
actual Taskr root and stores the mount configuration.

Mount creation validates access before storing configuration. Every mount
target must be readable. A `read-write` mount must also pass a write probe by
creating and removing a short temporary file in the mounted Taskr root.

# Acceptance

- `taskr create mount <path> --id <id> --name <name>` stores a mount with
  `id`, `name`, `path`, and `mode`.
- `--mode` accepts `read-only` and `read-write`; omitted mode defaults to
  `read-only`.
- Every mount target is checked for readability before it is stored.
- `--mode read-write` checks that the resolved Taskr root is writable before it
  is stored.
- `--name` accepts quoted values with spaces.
- When `--id` is omitted, the ID is derived from the first word of `--name` by
  trying progressively longer lowercase prefixes.
- ID derivation fails clearly when no valid free candidate remains.
- The command accepts a direct Taskr root path and the parent directory of a
  `taskr` subdirectory; the stored path is the resolved Taskr root.
- Invalid IDs, modes, names, missing paths, unreadable paths, duplicate IDs,
  and non-Taskr-root paths fail clearly.
- Help, docs, examples, and shell completion cover `create mount`, `--id`,
  `--name`, and `--mode`.
- Smokey covers explicit ID, derived ID, mode default, read-write mode, quoted
  name, missing path validation, non-Taskr-root validation, parent-directory
  path resolution, duplicate ID, and derivation failure.
- Negative permission-denied cases for unreadable roots and unwritable
  read-write roots require robust Smokey permission fixtures and are deferred
  until that Smokey-side support exists. The implementation still must perform
  the runtime readability and writability checks.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.
- 2026-08-25: Mount creation must validate readability for all mounts and
  writability for `read-write` mounts.
- 2026-08-25: Chmod-based unreadable/unwritable Smokey cases were not kept in
  this suite because permission behavior depends on the test runner
  environment. Robust permission fixture support is tracked in the Smokey
  project.

# Outcome

Implemented persisted virtual mounts with explicit or derived IDs, strict mode
validation, parent-path resolution, and runtime readability/writability probes.

# Release Notes

Taskr can mount another Taskr root with `taskr create mount`.
