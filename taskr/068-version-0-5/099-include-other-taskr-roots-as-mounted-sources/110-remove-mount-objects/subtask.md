---
title: Remove mount objects
status: designing
created_at: 2026-08-25T17:20:18Z
updated_at: 2026-08-25T17:20:18Z
designing_at: 2026-08-25T17:20:18Z
---

# Description

Implement `taskr remove mount <id>` for unmounting virtual mount objects.

Removal deletes only the local mount entry from `taskr.toml`. It never deletes,
modifies, archives, or rewrites the mounted Taskr root.

# Acceptance

- `taskr remove mount <id>` removes the matching local mount config entry.
- The mounted root remains unchanged.
- Removing an unknown or ambiguous mount fails clearly.
- Removing a mount updates the project config atomically enough to avoid
  leaving malformed TOML on ordinary failures.
- Help, docs, examples, and shell completion cover `remove mount`.
- Smokey covers successful removal, unchanged external root, unknown mount, and
  completion for mount IDs.

# Comments

- 2026-08-25: Command-specific slice of ticket 099.

# Outcome
