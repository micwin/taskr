---
title: Add priority controls to list
status: done
created_at: 2026-08-10T14:41:17Z
updated_at: 2026-08-10T15:53:16Z
designing_at: 2026-08-10T14:41:18Z
developing_at: 2026-08-10T15:11:49Z
reviewing_at: 2026-08-10T15:26:27Z
done_at: 2026-08-10T15:53:16Z
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

Task-only list output now sorts `high`, `normal`, `low` with stable ties.
Effective priority can be filtered, automatically shown for non-normal values,
forced, hidden, or grouped with `--group-by priority --type task`. Invalid and
conflicting flags fail clearly. Help, completion, examples, workflow
documentation, and the shared Priority Smokey workflow cover the new surface.
