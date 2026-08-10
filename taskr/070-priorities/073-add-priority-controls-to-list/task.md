---
title: Add priority controls to list
status: developing
created_at: 2026-08-10T14:41:17Z
updated_at: 2026-08-10T15:11:49Z
designing_at: 2026-08-10T14:41:18Z
developing_at: 2026-08-10T15:11:49Z
---

# Description

Use effective task priority for list ordering, filtering, grouping, and
optional priority display.

# Acceptance

- Task list ordering places `high` before `normal` before `low` and preserves
  the existing stable order within one priority.
- `taskr list --priority <high|normal|low>` filters tasks by effective priority.
- `--show-priority` forces priority values into list rows.
- `--hide-priority` suppresses priority values in list rows.
- Default list rows include `priority=high` and `priority=low`; effective
  `normal` remains hidden regardless of whether the result set is mixed or
  uniform.
- `--group-by priority` groups tasks in stable `high`, `normal`, `low` order.
- Priority grouping requires `--type task`; mixed item-role output is rejected
  instead of assigning milestones or subtasks an artificial priority.
- Priority is not treated as an item selector or free-text search term.
- Help, examples, and completion cover all list priority controls.
- Smokey tests cover ordering, stable ties, omitted-as-normal filtering,
  grouping, forced/hidden/default display, and incompatible flags.

# Comments

- 2026-08-10: Priority search is intentionally excluded; filtering is the
  correct operation for queries such as all high-priority tasks.
- 2026-08-10: Agreed display model: non-normal priority is visible by default,
  `--show-priority` includes normal, `--hide-priority` suppresses all priority,
  and `--group-by priority` requires `--type task`.

# Outcome
