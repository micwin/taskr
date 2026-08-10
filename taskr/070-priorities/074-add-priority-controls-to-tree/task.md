---
title: Add priority controls to tree
status: designing
created_at: 2026-08-10T14:41:18Z
updated_at: 2026-08-10T14:41:18Z
designing_at: 2026-08-10T14:41:18Z
---

# Description

Apply effective task priority to sibling ordering and optional priority display
in tree output without changing hierarchy.

# Acceptance

- Sibling tasks are ordered `high`, `normal`, `low` with stable existing order
  inside one priority.
- Milestone and subtask placement remains structural and is not assigned a
  priority.
- `--show-priority` forces effective task priority into tree rows.
- `--hide-priority` suppresses priority values in tree rows.
- Default tree priority visibility is agreed before Smokey expectations are
  fixed.
- Existing tree indentation, `--all`, `--open`, `--ascii`, `--tabs`, and
  `--wide` behavior remains intact.
- Help, examples, completion, and Smokey tests cover ordering, stable ties,
  omitted-as-normal behavior, display modes, and flag combinations.

# Comments

- 2026-08-10: Priority changes sibling order only; it never changes the tree's
  parent-child relationships.

# Outcome
