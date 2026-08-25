---
title: Validate mounted roots with doctor
status: designing
created_at: 2026-08-25T17:20:20Z
updated_at: 2026-08-25T17:20:20Z
designing_at: 2026-08-25T17:20:20Z
---

# Description

Extend `taskr doctor` and `taskr doctor --fix` for mount configuration,
availability, transitive mount graphs, and mount-aware repair rules.

# Acceptance

- Default `doctor` validates local structure, mount config syntax, duplicate
  local mount IDs, invalid modes, invalid paths, readability, and whether each
  mounted path is a Taskr root.
- Default `doctor` checks read-write mount writability by creating and removing
  a short temporary probe file.
- `doctor --include-mounts` deeply validates mounted item structures.
- Mounted diagnostics include mount identity.
- Transitive mounts are followed for graph checks.
- Cyclic mount references fail clearly and are not fixable.
- Transitive mount ID collisions fail clearly and are not fixable.
- `doctor --fix` removes clearly broken local mount entries from `taskr.toml`
  when all reported errors are fixable.
- `doctor --fix --include-mounts` fails when a read-only mounted root would
  need an in-place fix.
- `doctor --fix` respects read-only mode anywhere in a transitive mount chain.
- Help, docs, and examples cover `--include-mounts` and mount fix behavior.
- Smokey covers invalid config, missing root, unreadable root, unwritable
  read-write root, fix removal, cycle rejection, ID collision rejection,
  read-only fix failure, and read-write deep fix success if supported.

# Comments

- 2026-08-25: Doctor-specific slice of ticket 099.

# Outcome
