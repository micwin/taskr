---
title: Render mounted roots in tree
status: developing
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-25T18:40:36Z
designing_at: 2026-08-25T17:20:19Z
developing_at: 2026-08-25T18:40:36Z
---

# Description

Extend `taskr tree` so mount objects and mounted subtrees render in hierarchy
output.

# Acceptance

- Mount objects render as root-level virtual items.
- Mount object rows use `id [mount <mode>] <name>` and show the configured
  mount mode (`read-only` or `read-write`) where normal item rows show status.
  Mount objects do not show Taskr lifecycle status values.
- Mounted root contents render below their mount object using mount-prefixed
  item identity.
- Existing `tree` indentation modes still work with mounted roots.
- Default unfinished filtering and `--all` behavior are preserved for mounted
  items.
- Cyclic and unavailable mounts fail clearly.
- Help, docs, examples, and shell completion cover mounted tree behavior.
- Smokey covers default tree output, mount objects with modes instead of
  statuses, `--all`, indentation flags, transitive mounts, cycles, unavailable
  mounts, and local/mounted ID collisions.

# Comments

- 2026-08-25: Tree-specific slice of ticket 099.

# Outcome
