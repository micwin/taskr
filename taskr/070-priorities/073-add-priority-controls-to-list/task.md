---
title: Add priority controls to list
status: designing
created_at: 2026-08-10T14:41:17Z
updated_at: 2026-08-10T14:41:18Z
designing_at: 2026-08-10T14:41:18Z
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
- The default priority visibility for mixed and uniform result sets is agreed
  before Smokey expectations are fixed.
- Priority grouping is supported without treating priority as a selector or
  free-text search term; the exact grouping flag is refined before coding.
- Help, examples, and completion cover all list priority controls.
- Smokey tests cover ordering, stable ties, omitted-as-normal filtering,
  grouping, forced/hidden/default display, and incompatible flags.

# Comments

- 2026-08-10: Priority search is intentionally excluded; filtering is the
  correct operation for queries such as all high-priority tasks.

# Outcome
