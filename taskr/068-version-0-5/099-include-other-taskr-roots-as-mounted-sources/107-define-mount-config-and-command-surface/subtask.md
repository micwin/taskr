---
title: Define mount config and command surface
status: designing
created_at: 2026-08-25T16:28:12Z
updated_at: 2026-08-25T16:28:12Z
designing_at: 2026-08-25T16:28:12Z
---

# Description

Define the mounted-root configuration model and the CLI surface that manages
mount entries.

The expected shape is a `taskr.toml` project configuration section for mounted
roots. Each mount has a stable identifier, a path to another Taskr root, and a
mode. Supported modes are `read-only` and `read-write`.

The command surface should be small and explicit, for example:

- `taskr mount add <id> <path> --mode read-only`
- `taskr mount list`
- `taskr mount set <id> --path <path> --mode read-write`
- `taskr mount remove <id>`

Open questions to settle in this ticket:

- exact TOML schema for multiple mounts
- whether paths are stored relative to the current working directory, the
  Taskr root, or the `taskr.toml` file
- allowed mount identifier syntax
- selector separator, with `mount:selector` as the current candidate
- whether mounts are root-level only for the first implementation

# Acceptance

- `taskr.toml` schema for mounted roots is documented and tested.
- Mount identifiers have a defined validation rule.
- Mount modes are limited to `read-only` and `read-write`.
- Mounted-root paths have a defined storage and resolution rule.
- The command surface for add, list, set, and remove is documented in help and
  examples.
- Invalid mount identifiers, modes, and paths fail clearly.
- Shell completion covers mount identifiers where mount commands accept them.
- Smokey covers adding, listing, updating, and removing a mount entry without
  requiring mounted-item loading yet.

# Comments

- 2026-08-25: First implementation slice for parent ticket 099.

# Outcome
