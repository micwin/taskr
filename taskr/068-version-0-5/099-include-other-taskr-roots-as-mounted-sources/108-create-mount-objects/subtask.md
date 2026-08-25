---
title: Create mount objects
status: designing
created_at: 2026-08-25T17:20:17Z
updated_at: 2026-08-25T17:20:17Z
designing_at: 2026-08-25T17:20:17Z
---

# Description

Implement `taskr create mount` for virtual root-level mount objects stored in
`taskr.toml`.

The command creates no marker directory. It resolves the supplied path to the
actual Taskr root and stores the mount configuration.

# Acceptance

- `taskr create mount <path> --id <id> --name <name>` stores a mount with
  `id`, `name`, `path`, and `mode`.
- `--mode` accepts `read-only` and `read-write`; omitted mode defaults to
  `read-only`.
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
  name, parent-directory path resolution, duplicate ID, and derivation failure.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.

# Outcome
