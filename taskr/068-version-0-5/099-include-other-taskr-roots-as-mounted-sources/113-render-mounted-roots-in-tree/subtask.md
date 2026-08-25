---
title: Render mounted roots in tree
status: designing
created_at: 2026-08-25T17:20:19Z
updated_at: 2026-08-25T17:20:19Z
designing_at: 2026-08-25T17:20:19Z
---

# Description

Extend `taskr tree` so mount objects and mounted subtrees render in hierarchy
output.

# Acceptance

- Mount objects render as root-level virtual items.
- Mounted root contents render below their mount object using mount-prefixed
  item identity.
- Existing `tree` indentation modes still work with mounted roots.
- Default unfinished filtering and `--all` behavior are preserved for mounted
  items.
- Cyclic and unavailable mounts fail clearly.
- Help, docs, examples, and shell completion cover mounted tree behavior.
- Smokey covers default tree output, `--all`, indentation flags, transitive
  mounts, cycles, unavailable mounts, and local/mounted ID collisions.

# Comments

- 2026-08-25: Tree-specific slice of ticket 099.

# Outcome
