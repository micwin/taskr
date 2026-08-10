---
title: Add priority controls to tree
status: reviewing
created_at: 2026-08-10T14:41:18Z
updated_at: 2026-08-10T15:27:53Z
designing_at: 2026-08-10T14:41:18Z
developing_at: 2026-08-10T15:17:36Z
reviewing_at: 2026-08-10T15:27:53Z
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
- Default task rows include `priority=high` and `priority=low` inside the
  existing status brackets; effective `normal` remains hidden.
- Existing tree indentation, `--all`, `--open`, `--ascii`, `--tabs`, and
  `--wide` behavior remains intact.
- Help, examples, completion, and Smokey tests cover ordering, stable ties,
  omitted-as-normal behavior, display modes, and flag combinations.

# Comments

- 2026-08-10: Priority changes sibling order only; it never changes the tree's
  parent-child relationships.
- 2026-08-10: Tree uses the same auto/show/hide visibility model as list.
  Priority ordering applies to task siblings under their parent milestone.

# Outcome

Tree output now sorts task siblings by effective `high`, `normal`, `low`
priority with stable ties while preserving hierarchy and visibility behavior.
Non-normal priority is shown inside task status brackets by default;
`--show-priority` and `--hide-priority` control labels without changing order.
All existing indentation modes and open/all filtering remain intact, with help,
completion, examples, workflow documentation, and Smokey coverage updated.
